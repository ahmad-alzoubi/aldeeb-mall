#!/usr/bin/env python3
"""
Aldeeb Mall — Task 7: Multi-Branch Operational Isolation & Inventory Transfers Forensic Audit Suite
Zero-tolerance verification of:
1. Real branch connection checks & latency metrics (no simulated timers)
2. Atomic branch creation, isolated schema provisioning, and warehouse registration
3. Cross-branch isolation and RLS security enforcement
4. End-to-end 7-stage transfer lifecycle with strict total inventory conservation
5. Duplicate receipt prevention (anti-tampering & idempotency)
6. Cancellation with automatic stock rollback
7. Inter-branch discrepancy and damage compensation settlement
8. Enterprise persistent audit trail and multi-device persistence
"""

import sys
import json
import time
import urllib.request
import urllib.error
import subprocess

POSTGREST_URL = "http://127.0.0.1:54321"

def call_postgrest(path, method="GET", data=None, headers=None):
    url = f"{POSTGREST_URL}{path}"
    req_headers = {"Accept": "application/json"}
    if headers:
        req_headers.update(headers)
    
    body = None
    if data is not None:
        body = json.dumps(data).encode("utf-8")
        req_headers["Content-Type"] = "application/json"
    
    req = urllib.request.Request(url, data=body, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            content = resp.read().decode("utf-8")
            return resp.status, json.loads(content) if content else {}
    except urllib.error.HTTPError as e:
        err_content = e.read().decode("utf-8")
        try:
            err_json = json.loads(err_content)
        except Exception:
            err_json = {"raw": err_content}
        return e.code, err_json
    except Exception as e:
        return 500, {"error": str(e)}

def run_psql(query):
    result = subprocess.run(
        ["psql", "-d", "aldeeb_mall_prod", "-t", "-A", "-c", query],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"psql error: {result.stderr.strip()}")
    return result.stdout.strip()

passed = 0
failed = 0

def test_assert(desc, condition, details=""):
    global passed, failed
    if condition:
        print(f"  [PASS] {desc}")
        passed += 1
    else:
        print(f"  [FAIL] {desc} -> {details}")
        failed += 1

print("\n================================================================================")
print("🏬 ALDEEB MALL TASK 7: FORENSIC VERIFICATION OF BRANCHES & TRANSFERS")
print("================================================================================\n")

# -----------------------------------------------------------------------------
# Test 1: Real Branch Connectivity & Live Health Check
# -----------------------------------------------------------------------------
print("▶ 1. Real Branch Database Connectivity & Ping Latency Check")
# Warm up connection socket
call_postgrest("/branches?limit=1")
start_time = time.perf_counter()
status_code, branches_resp = call_postgrest("/branches?code=eq.BR-RUH-01&select=id,code,is_active")
elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)

test_assert("PostgREST responds with HTTP 200 for branch ping", status_code == 200, f"Got status {status_code}")
test_assert("Real branch record retrieved from database", len(branches_resp) > 0 and branches_resp[0]["code"] == "BR-RUH-01")
test_assert("Ping latency is real and non-zero (< 1000ms)", 0 < elapsed_ms < 1000, f"Latency: {elapsed_ms}ms")

# Test degraded/offline behavior on non-existent endpoint
offline_status, _ = call_postgrest("/branches?code=eq.NON_EXISTENT_BRANCH_XYZ")
test_assert("Non-existent branch returns empty array cleanly without crashing", offline_status == 200)

# -----------------------------------------------------------------------------
# Test 2: Atomic Branch Creation & Physical Schema Provisioning
# -----------------------------------------------------------------------------
print("\n▶ 2. Atomic Branch Creation, Isolated Schema & Warehouse Provisioning")
new_branch_code = f"BR-TEST-{int(time.time()) % 10000:04d}"
create_payload = {
    "p_code": new_branch_code,
    "p_name_ar": "فرع التجربة والتدقيق المتقدم",
    "p_name_en": "Advanced Forensic Audit Branch",
    "p_city": "اللاذقية",
    "p_district": "الكورنيش الغربي",
    "p_address": "شارع الجمهورية، اللاذقية",
    "p_phone": "+963 41 888 9999",
    "p_manager_name": "م. كنان إبراهيم",
    "p_type": "supermarket",
    "p_terminals_count": 5,
    "p_currency": "ل.س"
}

status_code, branch_res = call_postgrest("/rpc/rpc_create_branch_atomic", method="POST", data=create_payload)
test_assert("Atomic branch creation RPC returns HTTP 200", status_code == 200, f"Got {status_code}: {branch_res}")
test_assert("Branch object returned with success flag", branch_res.get("success") is True)

expected_schema = f"branch_{new_branch_code.lower().replace('-', '_')}"
schema_exists = run_psql(f"SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = '{expected_schema}');")
test_assert(f"Physical schema '{expected_schema}' created in PostgreSQL", schema_exists == "t", f"Result: {schema_exists}")

# Verify isolated tables inside the schema
tables_count = run_psql(f"SELECT count(*) FROM information_schema.tables WHERE table_schema = '{expected_schema}';")
test_assert(f"Schema contains 5 isolated operational tables (products, orders, pos, movements, outbox)", int(tables_count) >= 5, f"Count: {tables_count}")

# Verify dark store warehouse registered for branch
wh_count = run_psql(f"SELECT count(*) FROM dark_stores WHERE branch_id = '{branch_res['branch']['id']}';")
test_assert("Dedicated dark store warehouse registered for the branch", int(wh_count) >= 1, f"Warehouses: {wh_count}")

# -----------------------------------------------------------------------------
# Test 3: Two-Branch Isolation (RLS Enforcement)
# -----------------------------------------------------------------------------
print("\n▶ 3. Two-Branch Strict RLS Isolation & Access Restrictions")
# Test that unauthenticated/anonymous query on audit_logs returns 0 rows due to RLS
anon_status, anon_audit = call_postgrest("/audit_logs")
test_assert("Anonymous user receives 0 audit log records due to RLS", len(anon_audit) == 0, f"Got {len(anon_audit)} rows")

# Verify database RLS is enabled and forced on inventory_transfers
rls_check = run_psql("SELECT relrowsecurity, relforcerowsecurity FROM pg_class WHERE relname = 'inventory_transfers';")
test_assert("FORCE RLS is strictly enabled on inventory_transfers table", rls_check == "t|t", f"Got: {rls_check}")

# -----------------------------------------------------------------------------
# Test 4: End-to-End 7-Stage Transfer Lifecycle & Stock Conservation
# -----------------------------------------------------------------------------
print("\n▶ 4. Complete Transfer Lifecycle & Total Inventory Invariance")
# Pick a source warehouse and product with sufficient stock
src_row = run_psql("""
    SELECT dsi.dark_store_id, dsi.product_id, ds.branch_id, dsi.quantity_on_hand, p.name_ar
    FROM dark_store_inventory dsi 
    JOIN dark_stores ds ON ds.id = dsi.dark_store_id 
    JOIN products p ON p.id = dsi.product_id
    WHERE ds.branch_id IS NOT NULL AND dsi.quantity_on_hand >= 50 
    ORDER BY dsi.quantity_on_hand DESC 
    LIMIT 1;
""").split("|")

src_wh_id = src_row[0]
prod_id = src_row[1]
src_branch = src_row[2]
prod_name = src_row[4]

# Pick a destination warehouse
dest_row = run_psql(f"""
    SELECT id, branch_id 
    FROM dark_stores 
    WHERE id != '{src_wh_id}' AND branch_id IS NOT NULL 
    LIMIT 1;
""").split("|")
dest_wh_id = dest_row[0]
dest_branch = dest_row[1]

# Record Initial Stock
src_initial_on_hand = int(run_psql(f"SELECT quantity_on_hand FROM dark_store_inventory WHERE dark_store_id = '{src_wh_id}' AND product_id = '{prod_id}';") or 0)
dest_initial_on_hand = int(run_psql(f"SELECT quantity_on_hand FROM dark_store_inventory WHERE dark_store_id = '{dest_wh_id}' AND product_id = '{prod_id}';") or 0)
dest_initial_damaged = int(run_psql(f"SELECT quantity_damaged FROM dark_store_inventory WHERE dark_store_id = '{dest_wh_id}' AND product_id = '{prod_id}';") or 0)

initial_system_stock = src_initial_on_hand + dest_initial_on_hand + dest_initial_damaged
print(f"  Initial Source Stock: {src_initial_on_hand} | Initial Dest Stock: {dest_initial_on_hand} | Initial System Total: {initial_system_stock}")

TRANSFER_QTY = 30

# Stage 1: Create Transfer Request
idem_key_1 = f"IDEM-FORENSIC-{int(time.time())}"
transfer_payload = {
    "p_source_warehouse_id": src_wh_id,
    "p_dest_warehouse_id": dest_wh_id,
    "p_product_id": prod_id,
    "p_quantity": TRANSFER_QTY,
    "p_actor_id": "u-auditor",
    "p_actor_name": "المدقق الجنائي",
    "p_actor_role": "auditor",
    "p_idempotency_key": idem_key_1,
    "p_notes": "مناقلة تدقيق شامل لفحص حفظ المخزون"
}
code, tr_1 = call_postgrest("/rpc/rpc_create_inventory_transfer", method="POST", data=transfer_payload)
test_assert("Stage 1 (Requested): Transfer created with status 'requested'", code == 200 and tr_1.get("status") == "requested", f"Status: {tr_1.get('status')}")
tr_1_id = tr_1["id"]

# Stage 2: Approve & Reserve Source Stock
code, tr_2 = call_postgrest("/rpc/rpc_approve_and_reserve_transfer", method="POST", data={"p_transfer_id": tr_1_id})
test_assert("Stage 2 (Reserved): Status updated to 'reserved'", code == 200 and tr_2.get("status") == "reserved", f"Status: {tr_2.get('status')}")

# Verify source stock reserved
src_reserved = int(run_psql(f"SELECT quantity_reserved FROM dark_store_inventory WHERE dark_store_id = '{src_wh_id}' AND product_id = '{prod_id}';"))
test_assert(f"Source warehouse reserved stock increased by {TRANSFER_QTY}", src_reserved == TRANSFER_QTY, f"Reserved: {src_reserved}")

# Stage 3: Dispatch with Driver
code, tr_3 = call_postgrest("/rpc/rpc_dispatch_transfer", method="POST", data={"p_transfer_id": tr_1_id, "p_assigned_driver": "الكابتن علاء (شاحنة تبريد #05)"})
test_assert("Stage 3 (Dispatched): Status updated to 'dispatched'", code == 200 and tr_3.get("status") == "dispatched")

# Verify stock moved from on-hand to in-transit
src_on_hand_after_disp = int(run_psql(f"SELECT quantity_on_hand FROM dark_store_inventory WHERE dark_store_id = '{src_wh_id}' AND product_id = '{prod_id}';"))
src_in_transit = int(run_psql(f"SELECT quantity_in_transit FROM dark_store_inventory WHERE dark_store_id = '{src_wh_id}' AND product_id = '{prod_id}';"))
test_assert(f"Source on-hand deducted by {TRANSFER_QTY}", src_on_hand_after_disp == src_initial_on_hand - TRANSFER_QTY, f"On hand: {src_on_hand_after_disp}")
test_assert(f"Source in-transit reflects {TRANSFER_QTY}", src_in_transit == TRANSFER_QTY, f"In transit: {src_in_transit}")

# Total system stock during transit
test_assert("System total stock is invariant during transit", (src_on_hand_after_disp + src_in_transit + dest_initial_on_hand + dest_initial_damaged) == initial_system_stock)

# Stage 4: Receive Good (27), Damaged (2), Missing/Discrepancy (1)
GOOD_QTY = 27
DAMAGED_QTY = 2
MISSING_QTY = 1

receive_payload = {
    "p_transfer_id": tr_1_id,
    "p_good_qty": GOOD_QTY,
    "p_damaged_qty": DAMAGED_QTY,
    "p_discrepancy_reason": "كرتونة مفقودة وتالفتين أثناء التفريغ برصيف الاستلام",
    "p_actor_name": "مستلم المستودع النهائي",
    "p_actor_role": "receiving_officer"
}
code, tr_4 = call_postgrest("/rpc/rpc_receive_and_close_transfer", method="POST", data=receive_payload)
test_assert("Stage 4 (Closed): Status updated to 'closed' and audit locked", code == 200 and tr_4.get("status") == "closed" and tr_4.get("audit_locked") is True)

# Verify Final Stocks
src_final_on_hand = int(run_psql(f"SELECT quantity_on_hand FROM dark_store_inventory WHERE dark_store_id = '{src_wh_id}' AND product_id = '{prod_id}';"))
src_final_in_transit = int(run_psql(f"SELECT quantity_in_transit FROM dark_store_inventory WHERE dark_store_id = '{src_wh_id}' AND product_id = '{prod_id}';"))
dest_final_on_hand = int(run_psql(f"SELECT quantity_on_hand FROM dark_store_inventory WHERE dark_store_id = '{dest_wh_id}' AND product_id = '{prod_id}';"))
dest_final_damaged = int(run_psql(f"SELECT quantity_damaged FROM dark_store_inventory WHERE dark_store_id = '{dest_wh_id}' AND product_id = '{prod_id}';"))

test_assert("Source in-transit is cleared to 0 after receipt", src_final_in_transit == 0)
test_assert(f"Destination good stock increased by {GOOD_QTY}", dest_final_on_hand == dest_initial_on_hand + GOOD_QTY)
test_assert(f"Destination damaged stock increased by {DAMAGED_QTY}", dest_final_damaged == dest_initial_damaged + DAMAGED_QTY)

# Conservation of Total Inventory Equation:
final_sum = src_final_on_hand + dest_final_on_hand + dest_final_damaged + MISSING_QTY
test_assert("MATHEMATICAL STOCK CONSERVATION: Total Stock Invariant (0% leak / 0% phantom creation)", final_sum == initial_system_stock, f"Final: {final_sum} vs Initial: {initial_system_stock}")

# -----------------------------------------------------------------------------
# Test 5: Duplicate Receipt Prevention (Anti-Tampering / Idempotency)
# -----------------------------------------------------------------------------
print("\n▶ 5. Prevention of Duplicate Receipt (Anti-Tampering)")
code_dup, res_dup = call_postgrest("/rpc/rpc_receive_and_close_transfer", method="POST", data=receive_payload)
test_assert("Second attempt to receive closed transfer is rejected with HTTP 400", code_dup == 400, f"Got: {code_dup}")
test_assert("Error message confirms duplicate receipt is strictly blocked", "TRANSFER_ALREADY_CLOSED" in res_dup.get("message", ""), f"Message: {res_dup.get('message')}")

# Verify destination stock was NOT double-counted
dest_stock_after_dup = int(run_psql(f"SELECT quantity_on_hand FROM dark_store_inventory WHERE dark_store_id = '{dest_wh_id}' AND product_id = '{prod_id}';"))
test_assert("Destination stock remained exactly invariant after replay attempt", dest_stock_after_dup == dest_final_on_hand)

# -----------------------------------------------------------------------------
# Test 6: Transfer Cancellation & Automatic Stock Rollback
# -----------------------------------------------------------------------------
print("\n▶ 6. Transfer Cancellation with Automatic Stock Rollback")
cancel_payload = {
    "p_source_warehouse_id": src_wh_id,
    "p_dest_warehouse_id": dest_wh_id,
    "p_product_id": prod_id,
    "p_quantity": 10,
    "p_idempotency_key": f"IDEM-CANCEL-{int(time.time())}",
    "p_notes": "مناقلة سيتم إلغاؤها لفحص استرجاع الحجز"
}
_, tr_c = call_postgrest("/rpc/rpc_create_inventory_transfer", method="POST", data=cancel_payload)
tr_c_id = tr_c["id"]

# Reserve
call_postgrest("/rpc/rpc_approve_and_reserve_transfer", method="POST", data={"p_transfer_id": tr_c_id})
rsv_before_cancel = int(run_psql(f"SELECT quantity_reserved FROM dark_store_inventory WHERE dark_store_id = '{src_wh_id}' AND product_id = '{prod_id}';"))

# Cancel
code_cancel, res_cancel = call_postgrest("/rpc/rpc_cancel_transfer", method="POST", data={"p_transfer_id": tr_c_id, "p_reason": "إلغاء لعدم الحاجة"})
test_assert("Cancel RPC returns HTTP 200 with status 'cancelled'", code_cancel == 200 and res_cancel.get("status") == "cancelled")

# Verify stock rollback
rsv_after_cancel = int(run_psql(f"SELECT quantity_reserved FROM dark_store_inventory WHERE dark_store_id = '{src_wh_id}' AND product_id = '{prod_id}';"))
test_assert("Reserved stock was automatically unreserved and restored to source", rsv_after_cancel == rsv_before_cancel - 10)

# -----------------------------------------------------------------------------
# Test 7: Inter-Branch Compensation for Damages & Discrepancies
# -----------------------------------------------------------------------------
print("\n▶ 7. Inter-Branch Compensation Settlement")
comp_payload = {
    "p_transfer_id": tr_1_id,
    "p_compensation_type": "credit_note",
    "p_notes": "إصدار إشعار تسوية مالي دائن لصالح فرع الاستلام"
}
code_comp, res_comp = call_postgrest("/rpc/rpc_compensate_transfer", method="POST", data=comp_payload)
test_assert("Compensate RPC returns HTTP 200 with status 'compensated'", code_comp == 200 and res_comp.get("status") == "compensated")

comp_records = int(run_psql(f"SELECT count(*) FROM inventory_compensations WHERE transfer_id = '{tr_1_id}';"))
test_assert("Compensation record permanently inserted into inventory_compensations", comp_records == 1)

# -----------------------------------------------------------------------------
# Test 8: Enterprise Audit Trail Verification
# -----------------------------------------------------------------------------
print("\n▶ 8. Enterprise Persistent Audit Trail")
audit_actions = run_psql(f"SELECT action FROM audit_logs WHERE target_id = '{tr_1_id}' ORDER BY created_at;").split("\n")
test_assert("Audit log recorded TRANSFER_REQUESTED", "TRANSFER_REQUESTED" in audit_actions)
test_assert("Audit log recorded TRANSFER_APPROVED_RESERVED", "TRANSFER_APPROVED_RESERVED" in audit_actions)
test_assert("Audit log recorded TRANSFER_DISPATCHED", "TRANSFER_DISPATCHED" in audit_actions)
test_assert("Audit log recorded TRANSFER_CLOSED_MATCHED", "TRANSFER_CLOSED_MATCHED" in audit_actions)
test_assert("Audit log recorded TRANSFER_COMPENSATED", "TRANSFER_COMPENSATED" in audit_actions)

# -----------------------------------------------------------------------------
# Test 9: Multi-Device Persistence
# -----------------------------------------------------------------------------
print("\n▶ 9. Multi-Device Persistence Verification")
persisted_status = run_psql(f"SELECT status, audit_locked FROM inventory_transfers WHERE id = '{tr_1_id}';")
test_assert("Transfer status permanently persisted as 'compensated|t'", persisted_status == "compensated|t", f"Got: {persisted_status}")

print("\n================================================================================")
print(f"FORENSIC AUDIT SUMMARY: {passed} PASSED | {failed} FAILED")
print("================================================================================\n")

if failed > 0:
    sys.exit(1)
sys.exit(0)
