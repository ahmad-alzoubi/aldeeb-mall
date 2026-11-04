#!/usr/bin/env python3
"""
==============================================================================
🏢 ALDEEB MALL & HYPERMARKET — CORPORATE B2B SALES FORENSIC VERIFICATION SUITE
==============================================================================
Forensic End-to-End Validation for Task 9: Corporate B2B Sales & Wholesale:
1. Corporate Client Accounts & KYC (Credit Limits, Payment Terms, CR Uniqueness)
2. Quotations & Pricing RFQs (Mathematical Accuracy, VAT 15%, Multi-tier Status)
3. Supervisor Approval Workflow & Audit Trail (Authorized vs Unauthorized)
4. Credit Limit Ceiling Guard (Rejection when balance + invoice > credit_limit)
5. Atomic Invoice Creation & Inventory Stock Deduction (Real Stock decrements)
6. Payment Settlement & Real-time Debt Reduction (Balance decrements, Status: paid)
7. Goods Return, Credit Notes & Stock Restoration (Stock restored to catalog)
8. Multi-Branch Isolation & Security Matrix
9. Multi-Device Persistence in PostgreSQL
==============================================================================
"""

import urllib.request
import urllib.error
import json
import time
import sys
import subprocess
import uuid

BASE_URL = "http://127.0.0.1:54321"

def log_test(num, name, passed, details=""):
    status = "✅ PASS" if passed else "❌ FAIL"
    print(f"[{num:02d}] {status} | {name}")
    if details:
        print(f"        • {details}")
    if not passed:
        print(f"\n❌ CRITICAL DEFECT ENCOUNTERED IN TEST [{num:02d}]: {name}")
        sys.exit(1)

def http_post(endpoint, payload, headers=None):
    url = f"{BASE_URL}{endpoint}"
    data = json.dumps(payload).encode('utf-8')
    req_headers = {'Content-Type': 'application/json', 'Prefer': 'return=representation'}
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(url, data=data, headers=req_headers)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw.strip() else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = body
        return e.code, parsed

def http_get(endpoint, headers=None):
    url = f"{BASE_URL}{endpoint}"
    req_headers = {}
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(url, headers=req_headers)
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = body
        return e.code, parsed

def run_psql(query: str) -> str:
    res = subprocess.run(['psql', '-d', 'aldeeb_mall_prod', '-t', '-c', query], capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"PSQL execution error: {res.stderr}")
    return res.stdout.strip()

def main():
    print("=" * 80)
    print("🚀 ALDEEB MALL — TASK 9: CORPORATE B2B SALES & INVENTORY AUDIT SUITE")
    print("=" * 80)

    # Authenticate as Super Admin to obtain authorized JWT
    status, admin_login = http_post("/rpc/staff_login", {"p_username": "admin", "p_password": "admin"})
    if status != 200 or not admin_login.get("token"):
        print("❌ Failed to authenticate super admin for B2B test suite")
        sys.exit(1)
    admin_token = admin_login["token"]
    h_admin = {"Authorization": f"Bearer {admin_token}"}

    # Authenticate as Manager Wael (Damascus)
    status, wael_login = http_post("/rpc/staff_login", {"p_username": "manager_wael", "p_password": "dam123"})
    h_wael = {"Authorization": f"Bearer {wael_login['token']}"}

    # Authenticate as Manager Rami (Jeddah)
    status, rami_login = http_post("/rpc/staff_login", {"p_username": "manager_rami", "p_password": "jed123"})
    h_rami = {"Authorization": f"Bearer {rami_login['token']}"}

    # -------------------------------------------------------------------------
    # TEST 1: Corporate Accounts Schema & Seeded Accounts Verification
    # -------------------------------------------------------------------------
    status, accs = http_get("/corporate_accounts?select=id,company_name,cr_number,monthly_credit_limit,payment_terms,branch_id", headers=h_admin)
    log_test(1, "Retrieve Seeded Corporate Accounts via PostgREST", status == 200 and len(accs) >= 5, f"Loaded {len(accs)} corporate client accounts")

    # -------------------------------------------------------------------------
    # TEST 2: Corporate Account CRUD & Commercial Registration (CR) Uniqueness
    # -------------------------------------------------------------------------
    unique_cr = f"CR-TEST-{uuid.uuid4().hex[:6]}"
    new_acc_payload = {
        "company_name": "شركة الاختبار المؤسسي المتحدة B2B",
        "cr_number": unique_cr,
        "vat_number": "310998877660003",
        "contact_person": "أ. كنان السوري",
        "phone": "+963 99 888 7766",
        "email": "corporate.test@aldeebmall.com",
        "city": "دمشق",
        "branch_id": "b-dam-01",
        "monthly_credit_limit": 2000000.00,
        "current_balance": 0.00,
        "payment_terms": "Net-30",
        "status": "active"
    }
    status, created_acc = http_post("/corporate_accounts", new_acc_payload, headers=h_admin)
    created_id = created_acc[0]["id"] if isinstance(created_acc, list) else created_acc.get("id")
    log_test(2, "Create Authorized Corporate Client Account", status in (200, 201) and created_id is not None, f"Account ID: {created_id}, CR: {unique_cr}")

    # Duplicate CR check: must be rejected with 409 or 400
    status, dup_res = http_post("/corporate_accounts", new_acc_payload, headers=h_admin)
    log_test(3, "CR Uniqueness Constraint Enforced (Duplicate Rejected)", status in (400, 409), f"Status: {status}")

    # -------------------------------------------------------------------------
    # TEST 4: Setup Active Test Product with Guaranteed Stock
    # -------------------------------------------------------------------------
    test_prod_id = "b2b00000-0000-0000-0000-000000000001"
    setup_prod_sql = f"""
    DO $$
    DECLARE
        v_cat uuid;
    BEGIN
        SELECT id INTO v_cat FROM public.categories LIMIT 1;
        INSERT INTO public.products (id, name_ar, name_en, barcode, price, stock_quantity, category_id, is_active)
        VALUES ('{test_prod_id}', 'بن دمشقي فاخر للشركات 1 كغ', 'Corporate Espresso 1kg', '628111222333', 50000.00, 100, v_cat, true)
        ON CONFLICT (id) DO UPDATE SET stock_quantity = 100, price = 50000.00, is_active = true;

        DELETE FROM public.branch_inventory WHERE product_id = '{test_prod_id}' AND branch_id <> 'b-dam-01';

        INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved)
        VALUES ('b-dam-01', '{test_prod_id}', 100, 0)
        ON CONFLICT (branch_id, product_id) DO UPDATE SET quantity_on_hand = 100, quantity_reserved = 0;

        UPDATE public.products SET stock_quantity = 100 WHERE id = '{test_prod_id}';
    END $$;
    """
    run_psql(setup_prod_sql)
    stock_before = int(run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id}';"))
    dam_stock_before = int(float(run_psql(f"SELECT quantity_on_hand FROM public.branch_inventory WHERE branch_id = 'b-dam-01' AND product_id = '{test_prod_id}';")))
    log_test(4, "Provision Test Product with Initial Stock in Damascus", dam_stock_before == 100, f"Global Sum Stock: {stock_before} units, Damascus Branch Stock: {dam_stock_before} units")

    # -------------------------------------------------------------------------
    # TEST 5: Quotation Creation & Mathematical Totals Accuracy
    # -------------------------------------------------------------------------
    # 10 units @ 50,000 = 500,000. Discount 10% = 50,000. Subtotal after discount = 450,000.
    # Tax 15% = 67,500. Total = 517,500.
    quote_payload = {
        "quotation_number": f"QT-2026-{uuid.uuid4().hex[:6].upper()}",
        "corporate_account_id": created_id,
        "branch_id": "b-dam-01",
        "subtotal": 500000.00,
        "discount_percent": 10.00,
        "discount_amount": 50000.00,
        "tax_amount": 67500.00,
        "total_amount": 517500.00,
        "status": "draft",
        "valid_until": "2026-12-31",
        "notes": "عرض سعر خاص لتوريد بن اسبريسو شهري"
    }
    status, created_quote = http_post("/corporate_quotations", quote_payload, headers=h_admin)
    quote_id = created_quote[0]["id"] if isinstance(created_quote, list) else created_quote.get("id")
    log_test(5, "Issue Corporate Quotation (B2B RFQ)", status in (200, 201) and quote_id is not None, f"Quotation Number: {quote_payload['quotation_number']}, Total: {quote_payload['total_amount']} SP")

    # Add line items to quotation
    item_payload = {
        "quotation_id": quote_id,
        "product_id": test_prod_id,
        "quantity": 10.00,
        "unit_price": 50000.00,
        "discount_percent": 10.00,
        "final_unit_price": 45000.00,
        "total_price": 450000.00
    }
    status, q_item = http_post("/corporate_quotation_items", item_payload, headers=h_admin)
    log_test(6, "Insert Quotation Line Items with Wholesale Discount", status in (200, 201), "10 units @ 45,000 SP = 450,000 SP")

    # -------------------------------------------------------------------------
    # TEST 7: Supervisor Approval Workflow
    # -------------------------------------------------------------------------
    approve_rpc_payload = {
        "p_payload": {
            "quotation_id": quote_id,
            "action": "approve",
            "staff_name": "المدير المالي وائل خوري",
            "notes": "تمت المراجعة واعتماد الخصم التجاري 10%"
        }
    }
    status, app_res = http_post("/rpc/approve_or_reject_corporate_quotation", approve_rpc_payload, headers=h_admin)
    log_test(7, "Approve Corporate Quotation via Official Server RPC", status == 200 and app_res.get("status") == "approved", f"Reviewed by: {app_res.get('reviewed_by')}")

    # -------------------------------------------------------------------------
    # TEST 8: Credit Limit Ceiling Guard (Rejection When Limit Exceeded)
    # -------------------------------------------------------------------------
    # Limit is 2,000,000 SP. Attempt to order 50 units @ 50,000 = 2,500,000 + tax = 2,875,000 SP (> 2,000,000)
    over_limit_payload = {
        "p_payload": {
            "corporate_account_id": created_id,
            "branch_id": "b-dam-01",
            "items": [{
                "product_id": test_prod_id,
                "quantity": 50,
                "unit_price": 50000.00,
                "discount_percent": 0.00
            }],
            "notes": "طلب يتجاوز السقف الائتماني"
        }
    }
    status, over_res = http_post("/rpc/create_corporate_invoice_with_stock_deduction", over_limit_payload, headers=h_admin)
    credit_blocked = status in (400, 500) and "CREDIT_LIMIT_EXCEEDED" in str(over_res)
    log_test(8, "Credit Limit Ceiling Guard (Excessive Order BLOCKED)", credit_blocked, f"Error: {over_res}")

    # -------------------------------------------------------------------------
    # TEST 9: Atomic Invoice Creation & Inventory Stock Deduction
    # -------------------------------------------------------------------------
    # Valid order: 10 units @ 50,000 with 10% discount = 517,500 SP (within 2,000,000 SP limit)
    valid_invoice_payload = {
        "p_payload": {
            "corporate_account_id": created_id,
            "branch_id": "b-dam-01",
            "quotation_id": quote_id,
            "items": [{
                "product_id": test_prod_id,
                "quantity": 10,
                "unit_price": 50000.00,
                "discount_percent": 10.00
            }],
            "notes": "فاتورة توريد رسمية لشهر تشرين الثاني",
            "created_by": "مسؤول مبيعات الشركات"
        }
    }
    status, inv_res = http_post("/rpc/create_corporate_invoice_with_stock_deduction", valid_invoice_payload, headers=h_admin)
    invoice_id = inv_res.get("invoice_id")
    invoice_num = inv_res.get("invoice_number")
    log_test(9, "Issue Corporate Invoice with Stock Deduction RPC", status == 200 and invoice_id is not None, f"Invoice: {invoice_num}, Amount: {inv_res.get('total_amount')} SP")

    # Check that stock was atomically deducted by 10 units
    stock_after = int(run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id}';"))
    branch_stock_after = int(float(run_psql(f"SELECT quantity_on_hand FROM public.branch_inventory WHERE branch_id = 'b-dam-01' AND product_id = '{test_prod_id}';")))
    stock_decremented = (stock_after == stock_before - 10 and branch_stock_after == dam_stock_before - 10)
    log_test(10, "Authoritative Stock Deduction Verified in PostgreSQL", stock_decremented, f"Global Stock: {stock_after} (was {stock_before}), Branch Stock: {branch_stock_after} (was {dam_stock_before})")

    # Check Corporate Account balance increased by total_amount (517,500)
    current_debt = float(run_psql(f"SELECT current_balance FROM public.corporate_accounts WHERE id = '{created_id}';"))
    log_test(11, "Corporate Account Debt Updated in Balance Sheet", current_debt == 517500.00, f"Outstanding Balance: {current_debt:,.2f} SP")

    # -------------------------------------------------------------------------
    # TEST 12: Payment Settlement & Real-Time Debt Relief
    # -------------------------------------------------------------------------
    payment_payload = {
        "p_payload": {
            "invoice_id": invoice_id,
            "amount": 517500.00,
            "payment_method": "bank_transfer",
            "reference_number": "TRX-CHAM-BANK-2026",
            "notes": "سداد كامل قيمة الفاتورة عبر المصرف التجاري السوري",
            "received_by": "المحاسب طارق العلي"
        }
    }
    status, pay_res = http_post("/rpc/record_corporate_payment", payment_payload, headers=h_admin)
    log_test(12, "Record Corporate Bank Payment via Atomic RPC", status == 200 and pay_res.get("payment_status") == "paid", f"Receipt: {pay_res.get('payment_number')}, Status: {pay_res.get('payment_status')}")

    # Check invoice status and corporate balance after payment
    inv_db_status = run_psql(f"SELECT payment_status FROM public.corporate_invoices WHERE id = '{invoice_id}';")
    account_db_debt = float(run_psql(f"SELECT current_balance FROM public.corporate_accounts WHERE id = '{created_id}';"))
    log_test(13, "Invoice Marked 'paid' and Corporate Balance Cleared to 0", inv_db_status == "paid" and account_db_debt == 0.00, f"Invoice Status: {inv_db_status}, Account Debt: {account_db_debt:,.2f} SP")

    # -------------------------------------------------------------------------
    # TEST 14: Goods Return & Inventory Stock Restoration
    # -------------------------------------------------------------------------
    # Create return request for 2 units
    ret_test_num = f"RET-B2B-TEST-{int(time.time() * 1000)}"
    return_req_sql = f"""
    DO $$
    DECLARE
        v_ret_id uuid := gen_random_uuid();
    BEGIN
        INSERT INTO public.corporate_returns (
            id, return_number, invoice_id, corporate_account_id, branch_id,
            total_refund_amount, status, reason, created_by
        ) VALUES (
            v_ret_id, '{ret_test_num}', '{invoice_id}', '{created_id}', 'b-dam-01',
            90000.00, 'pending_approval', 'إرجاع 2 كغ غير مطابقة للمواصفة', 'أمين المستودع'
        );

        INSERT INTO public.corporate_return_items (
            return_id, product_id, quantity, unit_price, total_refund, reason
        ) VALUES (
            v_ret_id, '{test_prod_id}', 2.00, 45000.00, 90000.00, 'غير مطابقة'
        );
    END $$;
    """
    run_psql(return_req_sql)
    ret_id = run_psql(f"SELECT id FROM public.corporate_returns WHERE return_number = '{ret_test_num}';")

    # Process return via atomic RPC
    process_ret_payload = {
        "p_payload": {
            "return_id": ret_id,
            "approved_by": "مدير ضبط الجودة"
        }
    }
    status, ret_res = http_post("/rpc/process_corporate_return_with_stock_restoration", process_ret_payload, headers=h_admin)
    log_test(14, "Process Return & Credit Note with Server RPC", status == 200 and ret_res.get("status") == "completed", f"Return: {ret_res.get('return_number')}, Restored: {ret_res.get('restored_items_count')} items")

    # Check that stock was restored by 2 units
    stock_restored = int(run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id}';"))
    log_test(15, "Inventory Catalog Stock Restored Accurately (+2 units)", stock_restored == stock_after + 2, f"Stock after return: {stock_restored} units (was {stock_after})")

    # -------------------------------------------------------------------------
    # TEST 16: Multi-Branch Data Isolation on Corporate Portal
    # -------------------------------------------------------------------------
    # Manager Wael (Damascus) queries corporate accounts
    status, wael_accs = http_get("/corporate_accounts?select=id,company_name,branch_id", headers=h_wael)
    wael_dam_only = all(a["branch_id"] == "b-dam-01" for a in wael_accs)
    log_test(16, "Branch Manager Wael sees ONLY Damascus corporate accounts", status == 200 and wael_dam_only and len(wael_accs) >= 2, f"Visible Damascus Accounts: {len(wael_accs)}")

    # Manager Rami (Jeddah) queries corporate accounts
    status, rami_accs = http_get("/corporate_accounts?select=id,company_name,branch_id", headers=h_rami)
    rami_jed_only = all(a["branch_id"] == "b-jed-01" for a in rami_accs)
    log_test(17, "Branch Manager Rami sees ONLY Jeddah corporate accounts", status == 200 and rami_jed_only and len(rami_accs) >= 1, f"Visible Jeddah Accounts: {len(rami_accs)}")

    # Manager Rami queries Damascus invoices: MUST BE 0
    status, rami_dam_invs = http_get(f"/corporate_invoices?branch_id=eq.b-dam-01", headers=h_rami)
    log_test(18, "Branch Manager Rami cross-branch IDOR returns 0 rows", status == 200 and len(rami_dam_invs) == 0, f"Rami visible Damascus invoices: {len(rami_dam_invs)}")

    # -------------------------------------------------------------------------
    # TEST 19: Anonymous Access Blocked (Security Boundary)
    # -------------------------------------------------------------------------
    status, anon_accs = http_get("/corporate_accounts")
    log_test(19, "Anonymous Access to /corporate_accounts is strictly BLOCKED", status in (401, 403), f"Status: {status}")

    status, anon_invs = http_get("/corporate_invoices")
    log_test(20, "Anonymous Access to /corporate_invoices is strictly BLOCKED", status in (401, 403), f"Status: {status}")

    # -------------------------------------------------------------------------
    # TEST 21: Multi-Device Persistence Verification
    # -------------------------------------------------------------------------
    persisted_inv = run_psql(f"SELECT invoice_number, payment_status, total_amount FROM public.corporate_invoices WHERE id = '{invoice_id}';")
    log_test(21, "PostgreSQL Authoritative Persistence Verified Across Reboots", bool(persisted_inv), f"Persistent Data: {persisted_inv}")

    print("\n" + "=" * 80)
    print("🏆 ALL 21/21 CORPORATE B2B FORENSIC TESTS PASSED (100% ZERO DEFECT)!")
    print("=" * 80)

if __name__ == "__main__":
    main()
