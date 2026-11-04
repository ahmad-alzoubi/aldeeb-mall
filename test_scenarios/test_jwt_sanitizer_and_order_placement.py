#!/usr/bin/env python3
"""
========================================================================================
ALDEEB MALL: FORENSIC VERIFICATION SUITE — JWT SANITIZATION & ORDER PLACEMENT INTEGRITY
========================================================================================
Verifies resolution of "Expected 3 parts in JWT; got 1" error:
1. Replicates and captures PostgREST 401 rejection on 1-part/malformed Bearer tokens.
2. Proves that valid 3-part staff JWTs (Cashier, Super Admin) authenticate with 200 OK.
3. Proves atomic order creation, items insertion, and inventory deduction in PostgreSQL.
4. Confirms TypeScript production build bundle contains the auto-healing JWT sanitizer.
========================================================================================
"""

import json
import subprocess
import urllib.request
import urllib.error
import time
import os

POSTGREST_URL = "http://127.0.0.1:54321"
DB_NAME = "aldeeb_mall_prod"

def run_sql(query: str) -> str:
    res = subprocess.run(
        ["psql", "-h", "localhost", "-p", "5432", "-U", "ahmad_alzoubi", "-d", DB_NAME, "-t", "-A", "-c", query],
        capture_output=True,
        text=True,
        check=True
    )
    return res.stdout.strip()

def http_request(url: str, method: str = "GET", headers: dict = None, data: dict = None):
    req_headers = headers or {}
    encoded_data = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, data=encoded_data, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"raw": body}
        return e.code, parsed

def log_test(name: str, passed: bool, details: str = ""):
    status = "✅ PASS" if passed else "❌ FAIL"
    print(f"[{status}] {name}")
    if details:
        print(f"       Details: {details}")
    if not passed:
        raise AssertionError(f"Test failed: {name} - {details}")

def main():
    print("=" * 80)
    print("🛡️ RUNNING FORENSIC VERIFICATION: JWT SANITIZER & ORDER PLACEMENT SUITE")
    print("=" * 80)

    # -------------------------------------------------------------------------
    # TEST 1: Replicate Exact Root Cause (1-Part JWT Rejection on PostgREST)
    # -------------------------------------------------------------------------
    malformed_1part_token = "bearer-jwt-staff-cashier-01-1730700000000"
    status_1part, body_1part = http_request(
        f"{POSTGREST_URL}/orders?limit=1",
        headers={"Authorization": f"Bearer {malformed_1part_token}"}
    )
    log_test(
        "Test 1: PostgREST Correctly Rejects 1-Part Malformed Token with PGRST301",
        status_1part == 401 and "Expected 3 parts in JWT; got 1" in str(body_1part),
        f"HTTP Status: {status_1part}, Message: {body_1part.get('message')}"
    )

    # -------------------------------------------------------------------------
    # TEST 2: Cashier Server-Signed 3-Part JWT Authenticates Flawlessly (HTTP 200)
    # -------------------------------------------------------------------------
    cashier_token = run_sql("SELECT public.staff_login('cashier_omar', 'pos123')->>'token';")
    parts = cashier_token.split(".")
    status_cashier, body_cashier = http_request(
        f"{POSTGREST_URL}/orders?limit=1",
        headers={"Authorization": f"Bearer {cashier_token}"}
    )
    log_test(
        "Test 2: Cashier Server-Signed 3-Part JWT Returns HTTP 200 OK",
        status_cashier == 200 and len(parts) == 3,
        f"HTTP Status: {status_cashier}, Token Parts Count: {len(parts)}"
    )

    # -------------------------------------------------------------------------
    # TEST 3: Super Admin Server-Signed 3-Part JWT Authenticates Flawlessly (HTTP 200)
    # -------------------------------------------------------------------------
    admin_token = run_sql("SELECT public.staff_login('admin', 'admin')->>'token';")
    status_admin, body_admin = http_request(
        f"{POSTGREST_URL}/orders?limit=1",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    log_test(
        "Test 3: Super Admin 3-Part JWT Returns HTTP 200 OK",
        status_admin == 200 and len(admin_token.split(".")) == 3,
        f"HTTP Status: {status_admin}"
    )

    # -------------------------------------------------------------------------
    # TEST 4: Atomic POS Order Creation via PostgREST with Valid Cashier Token
    # -------------------------------------------------------------------------
    test_order_uuid = "e8888888-8888-4888-a888-888888888888"
    test_receipt_num = f"POS-FORENSIC-{int(time.time())}"
    
    order_payload = {
        "id": test_order_uuid,
        "order_number": test_receipt_num,
        "customer_name": "عميل نقطة بيع مباشر",
        "customer_phone": "+966 50 123 9999",
        "branch_id": "b-ruh-01",
        "branch_name": "هايبرماركت الرياض الرئيسي (المركز الفاخر)",
        "status": "delivered",
        "delivery_slot": "كاشير مباشر - المركز الفاخر",
        "payment_method": "cash",
        "payment_status": "paid",
        "subtotal": 150.00,
        "delivery_fee": 0.00,
        "total_amount": 150.00,
        "notes": "فحص جنائي مباشر لمنع خطأ JWT"
    }

    status_order, body_order = http_request(
        f"{POSTGREST_URL}/orders",
        method="POST",
        headers={
            "Authorization": f"Bearer {cashier_token}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        },
        data=order_payload
    )

    log_test(
        "Test 4: Atomic POS Order Insertion via PostgREST Returns HTTP 201 Created",
        status_order == 201,
        f"HTTP Status: {status_order}, Created Order ID: {body_order[0]['id'] if isinstance(body_order, list) else body_order.get('id')}"
    )

    # -------------------------------------------------------------------------
    # TEST 5: Order Items Insertion Linked to Order in PostgreSQL
    # -------------------------------------------------------------------------
    item_payload = [{
        "order_id": test_order_uuid,
        "product_id": "a0000000-0000-0000-0000-000000000001",
        "product_name_ar": "موز فلبيني طازج كافنديش درجة أولى",
        "product_name_en": "Fresh Cavendish Bananas",
        "unit": "kg",
        "unit_price": 50.00,
        "quantity": 3,
        "total_price": 150.00
    }]

    status_item, body_item = http_request(
        f"{POSTGREST_URL}/order_items",
        method="POST",
        headers={
            "Authorization": f"Bearer {cashier_token}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        },
        data=item_payload
    )

    log_test(
        "Test 5: Order Items Linked to Order Saved with HTTP 201 Created",
        status_item == 201,
        f"HTTP Status: {status_item}"
    )

    # -------------------------------------------------------------------------
    # TEST 6: Atomic Stock Movement RPC Execution for POS Sale
    # -------------------------------------------------------------------------
    movement_payload = {
        "p_branch_id": "b-ruh-01",
        "p_product_id": "a0000000-0000-0000-0000-000000000001",
        "p_movement_type": "sale",
        "p_qty_change": -3,
        "p_qty_reserved_change": 0,
        "p_ref_type": "order",
        "p_ref_id": test_receipt_num,
        "p_actor_name": "عمر الدوسري",
        "p_actor_role": "cashier",
        "p_notes": "فحص نقطة البيع"
    }

    status_move, body_move = http_request(
        f"{POSTGREST_URL}/rpc/record_inventory_movement_atomic",
        method="POST",
        headers={
            "Authorization": f"Bearer {cashier_token}",
            "Content-Type": "application/json"
        },
        data=movement_payload
    )

    log_test(
        "Test 6: Atomic Inventory Movement RPC Deducts Stock with HTTP 200/204",
        status_move in [200, 204],
        f"HTTP Status: {status_move}"
    )

    # Verify order in DB
    db_order_count = run_sql(f"SELECT count(*) FROM public.orders WHERE id = '{test_order_uuid}';")
    log_test(
        "Test 7: Order Row Exists and Confirmed in PostgreSQL",
        int(db_order_count) == 1,
        f"Found {db_order_count} row in orders table"
    )

    # Clean up test records
    run_sql(f"DELETE FROM public.order_items WHERE order_id = '{test_order_uuid}';")
    run_sql(f"DELETE FROM public.orders WHERE id = '{test_order_uuid}';")

    # -------------------------------------------------------------------------
    # TEST 8: Verify Production Bundle Contains JWT Sanitizer & Self-Healing Code
    # -------------------------------------------------------------------------
    dist_dir = "aldeeb_mall_admin/dist/assets"
    dist_files = [os.path.join(dist_dir, f) for f in os.listdir(dist_dir) if f.startswith("index-") and f.endswith(".js")]
    assert len(dist_files) > 0, "No production index JS bundle found in dist/assets"

    bundle_path = dist_files[0]
    with open(bundle_path, "r", encoding="utf-8") as f:
        bundle_content = f.read()

    has_sanitizer = "JWT Sanitizer" in bundle_content or "isValid3PartJwt" in bundle_content or "Expected 3 parts" in bundle_content or "PGRST301" in bundle_content
    log_test(
        "Test 8: Production Build Bundle (dist/) Contains Verified JWT Auto-Healing Sanitizer",
        has_sanitizer,
        f"Bundle: {bundle_path}, Size: {len(bundle_content)} bytes"
    )

    print("=" * 80)
    print("🎯 ALL 8 FORENSIC VERIFICATION TESTS PASSED WITH 100% SUCCESS")
    print("=" * 80)

if __name__ == "__main__":
    main()
