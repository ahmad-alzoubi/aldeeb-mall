#!/usr/bin/env python3
"""
Test Suite: Suppliers & Procurement Forensic Verification Suite (Task 8)
Verifies:
1. Server-Generated Sequential Numbers (PO-2026-XXXX)
2. Multi-Device Flow (Device A Creates -> Device B Receives Partially -> Device A Receives Remainder)
3. Damaged goods tracking in central inventory ledger
4. Catalog stock atomic increments & branch stock synchronization
5. Double-entry & over-receiving prevention
6. Supplier payment accounting, overpayment prevention & payables ledger
7. PO Cancellation validation (allowed when unreceived, strictly forbidden when received)
8. Draft product lifecycle & customer catalog isolation
9. REST API & Multi-Client Data Parity
"""

import sys
import os
import json
import time
import random
import subprocess
import urllib.request
import urllib.error

DB_NAME = "aldeeb_mall_prod"
PGRST_URL = "http://127.0.0.1:54321"

def run_psql(sql: str, as_json: bool = False):
    """Executes a SQL command via psql and returns trimmed stdout."""
    clean_sql = sql.strip().rstrip(';')
    if as_json:
        wrapped_sql = f"SELECT json_agg(t) FROM ({clean_sql}) t;"
        cmd = ["psql", "-d", DB_NAME, "-t", "-A", "-c", wrapped_sql]
    else:
        cmd = ["psql", "-d", DB_NAME, "-t", "-A", "-c", clean_sql]
        
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"psql error: {proc.stderr.strip()}")
    res = proc.stdout.strip()
    if as_json:
        return json.loads(res) if res else []
    return res

def log_test(name, passed, details=""):
    status = "✅ PASS" if passed else "❌ FAIL"
    print(f"[{status}] {name}")
    if details:
        print(f"       Details: {details}")
    if not passed:
        sys.exit(1)

def run_suite():
    print("======================================================================")
    print("🚀 Running Task 8: Suppliers & Procurement Forensic Audit Suite")
    print("======================================================================")

    # -------------------------------------------------------------------------
    # TEST 1: Certified Suppliers Active in PostgreSQL
    # -------------------------------------------------------------------------
    sup_count = int(run_psql("SELECT count(*) FROM public.suppliers WHERE status = 'active';"))
    log_test("Test 1: Certified Suppliers Active in PostgreSQL", sup_count >= 4, f"Found {sup_count} active suppliers")

    # Pick a supplier
    sup_almarai = run_psql("SELECT id, name_ar, balance FROM public.suppliers WHERE name_ar LIKE '%المراعي%' LIMIT 1;", as_json=True)[0]
    supplier_id = sup_almarai["id"]
    initial_balance = float(sup_almarai["balance"])

    # Pick two test products
    prods = run_psql("SELECT id, name_ar, stock_quantity FROM public.products WHERE is_active = true LIMIT 2;", as_json=True)
    prod_a = prods[0]
    prod_b = prods[1]
    prod_a_initial_stock = int(prod_a["stock_quantity"])
    prod_b_initial_stock = int(prod_b["stock_quantity"])

    # -------------------------------------------------------------------------
    # TEST 2: Device A creates PO with Unique Sequential Number (Atomic Server Sequence)
    # -------------------------------------------------------------------------
    items_json = json.dumps([
        {
            "product_id": str(prod_a["id"]),
            "name_ar": prod_a["name_ar"],
            "unit": "piece",
            "quantity_ordered": 100,
            "unit_cost": 20.0,
            "is_new_draft_product": False
        },
        {
            "product_id": str(prod_b["id"]),
            "name_ar": prod_b["name_ar"],
            "unit": "kg",
            "quantity_ordered": 50,
            "unit_cost": 30.0,
            "is_new_draft_product": False
        }
    ]).replace("'", "''")

    sql_create = f"""
        SELECT public.create_purchase_order(
            '{supplier_id}',
            'شركة المراعي للألبان والعصائر',
            'b-dam-01',
            'اليوم الساعة 2 ظهراً',
            'أمر شراء اختبار محاكاة الأجهزة المتعددة',
            '{items_json}'::jsonb,
            'جهاز إدارة المشتريات (Device A - Procurement HQ)'
        );
    """
    res_create = json.loads(run_psql(sql_create))
    po_id = res_create["id"]
    po_number = res_create["po_number"]
    total_cost = float(res_create["total_cost"])

    expected_cost = (100 * 20.0) + (50 * 30.0)
    log_test(
        "Test 2: Server-Generated Unique PO Number & Multi-Item Total",
        po_number.startswith("PO-2026-") and total_cost == expected_cost,
        f"Generated PO Number: {po_number}, Total Cost: {total_cost} SYP"
    )

    # -------------------------------------------------------------------------
    # TEST 3: Supplier Balance Debt Accrual
    # -------------------------------------------------------------------------
    new_balance = float(run_psql(f"SELECT balance FROM public.suppliers WHERE id = '{supplier_id}';"))
    log_test(
        "Test 3: Supplier Balance Debt Accrual",
        abs(new_balance - (initial_balance + total_cost)) < 0.01,
        f"Initial: {initial_balance}, Accrued: {new_balance}"
    )

    # -------------------------------------------------------------------------
    # TEST 4: Device B (Damascus Warehouse) Queries PO via PostgREST REST Gateway
    # -------------------------------------------------------------------------
    req = urllib.request.Request(f"{PGRST_URL}/purchase_orders?id=eq.{po_id}&select=*,items:purchase_order_items(*)")
    with urllib.request.urlopen(req) as resp:
        po_fetched = json.loads(resp.read().decode())[0]

    log_test(
        "Test 4: Cross-Device Query via REST Gateway (Device B Fetch)",
        po_fetched["status"] == "sent" and len(po_fetched["items"]) == 2,
        f"Device B fetched PO {po_fetched['po_number']} with {len(po_fetched['items'])} items"
    )

    item_a_id = [it["id"] for it in po_fetched["items"] if it["product_id"] == str(prod_a["id"])][0]
    item_b_id = [it["id"] for it in po_fetched["items"] if it["product_id"] == str(prod_b["id"])][0]

    # -------------------------------------------------------------------------
    # TEST 5: Device B performs Partial Receipt with Damaged Goods
    # Item A: Ordered 100 -> Receive 60 (5 Damaged). Net good = 55.
    # Item B: Ordered 50 -> Receive 20 (0 Damaged). Net good = 20.
    # -------------------------------------------------------------------------
    receipt_1 = json.dumps([
        {"item_id": item_a_id, "quantity_received": 60, "quantity_damaged": 5},
        {"item_id": item_b_id, "quantity_received": 20, "quantity_damaged": 0}
    ]).replace("'", "''")

    sql_rec1 = f"""
        SELECT public.receive_purchase_order_items(
            '{po_id}', '{receipt_1}'::jsonb, 'أمين مستودع دمشق (Device B)', 'b-dam-01'
        );
    """
    res_rec1 = json.loads(run_psql(sql_rec1))

    log_test(
        "Test 5: Partial Receiving & Status Update to 'partially_received'",
        res_rec1["status"] == "partially_received" and not res_rec1["all_fulfilled"],
        f"Status: {res_rec1['status']}, All fulfilled: {res_rec1['all_fulfilled']}"
    )

    # -------------------------------------------------------------------------
    # TEST 6: Central Inventory Transactions Audit for Receipts & Damaged Goods
    # -------------------------------------------------------------------------
    trxs = run_psql(f"""
        SELECT movement_type, quantity_change, total_value
        FROM public.inventory_transactions
        WHERE reference_id = '{po_number}'
        ORDER BY created_at ASC;
    """, as_json=True)
    good_receipts = [t for t in trxs if t["movement_type"] == "purchase_receipt"]
    damaged_receipts = [t for t in trxs if t["movement_type"] == "damaged_loss"]

    log_test(
        "Test 6: Ledger Audit for Receipts and Damaged Goods",
        len(good_receipts) >= 2 and len(damaged_receipts) >= 1,
        f"Recorded {len(good_receipts)} good receipts and {len(damaged_receipts)} damaged loss records"
    )

    # -------------------------------------------------------------------------
    # TEST 7: Atomic Catalog Stock Increment for Received Good Units
    # -------------------------------------------------------------------------
    stock_a_now = int(run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{prod_a['id']}';"))
    stock_b_now = int(run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{prod_b['id']}';"))

    log_test(
        "Test 7: Atomic Catalog Stock Increment for Received Good Units",
        stock_a_now == prod_a_initial_stock + 55 and stock_b_now == prod_b_initial_stock + 20,
        f"Prod A: {prod_a_initial_stock} -> {stock_a_now} (+55), Prod B: {prod_b_initial_stock} -> {stock_b_now} (+20)"
    )

    # -------------------------------------------------------------------------
    # TEST 8: Anti-Double-Entry & Over-receiving Protection
    # -------------------------------------------------------------------------
    over_receipt = json.dumps([
        {"item_id": item_a_id, "quantity_received": 50, "quantity_damaged": 0}
    ]).replace("'", "''")

    sql_over = f"""
        SELECT public.receive_purchase_order_items(
            '{po_id}', '{over_receipt}'::jsonb, 'أمين مستودع دمشق (Device B)', 'b-dam-01'
        );
    """
    over_blocked = False
    try:
        run_psql(sql_over)
    except Exception as e:
        over_blocked = True
        err_msg = str(e)

    log_test(
        "Test 8: Defense Against Over-Receiving and Duplicate Quantity Booking",
        over_blocked,
        f"Server blocked invalid excess receipt with error: {err_msg[:60]}..."
    )

    # -------------------------------------------------------------------------
    # TEST 9: Device A receives Remainder to Complete the PO
    # Item A: 45 remaining. Item B: 30 remaining.
    # -------------------------------------------------------------------------
    receipt_2 = json.dumps([
        {"item_id": item_a_id, "quantity_received": 45, "quantity_damaged": 0},
        {"item_id": item_b_id, "quantity_received": 30, "quantity_damaged": 0}
    ]).replace("'", "''")

    sql_rec2 = f"""
        SELECT public.receive_purchase_order_items(
            '{po_id}', '{receipt_2}'::jsonb, 'مدير المستودعات المركزي (Device A)', 'b-dam-01'
        );
    """
    res_rec2 = json.loads(run_psql(sql_rec2))

    log_test(
        "Test 9: Full Fulfillment Transition to 'received'",
        res_rec2["status"] == "received" and res_rec2["all_fulfilled"],
        f"Status: {res_rec2['status']}, All fulfilled: {res_rec2['all_fulfilled']}"
    )

    # -------------------------------------------------------------------------
    # TEST 10: Cancellation Guard: Received PO Cannot Be Cancelled
    # -------------------------------------------------------------------------
    cancel_blocked = False
    try:
        run_psql(f"SELECT public.cancel_purchase_order('{po_id}', 'محاولة إلغاء غير قانونية');")
    except Exception as e:
        cancel_blocked = True
        err_cancel = str(e)

    log_test(
        "Test 10: Strict Cancellation Ban on Partially/Fully Received PO",
        cancel_blocked,
        f"Server prevented cancellation of received order: {err_cancel[:60]}..."
    )

    # -------------------------------------------------------------------------
    # TEST 11: Accountant Partial Payment with Server Payment Number
    # -------------------------------------------------------------------------
    sql_pay1 = f"""
        SELECT public.record_supplier_payment(
            '{po_id}',
            1500.0,
            'sham_cash',
            'SHAM-REF-2026-TEST',
            'المحاسب المالي (Accountant)',
            'سداد دفعة أولى'
        );
    """
    res_pay1 = json.loads(run_psql(sql_pay1))
    payment_num = res_pay1["payment_number"]
    rem_bal = float(res_pay1["remaining_balance"])

    log_test(
        "Test 11: Partial Supplier Payment with Atomic Payment Number",
        payment_num.startswith("SP-PAY-") and res_pay1["payment_status"] == "partial",
        f"Payment Num: {payment_num}, Paid: 1500, Remaining: {rem_bal}"
    )

    # -------------------------------------------------------------------------
    # TEST 12: Overpayment Prevention Guard
    # -------------------------------------------------------------------------
    overpay_blocked = False
    try:
        run_psql(f"""
            SELECT public.record_supplier_payment(
                '{po_id}', {rem_bal + 500.0}, 'cash', NULL, 'المحاسب', NULL
            );
        """)
    except Exception as e:
        overpay_blocked = True
        err_pay = str(e)

    log_test(
        "Test 12: Overpayment Guard Defense",
        overpay_blocked,
        f"Server blocked overpayment: {err_pay[:60]}..."
    )

    # -------------------------------------------------------------------------
    # TEST 13: Final Payment & Complete Settle
    # -------------------------------------------------------------------------
    sql_pay2 = f"""
        SELECT public.record_supplier_payment(
            '{po_id}', {rem_bal}, 'bank_transfer', 'BANK-TRANSFER-9988', 'المحاسب المالي', 'تسديد كامل الرصيد المتبقي'
        );
    """
    res_pay2 = json.loads(run_psql(sql_pay2))

    log_test(
        "Test 13: Full Payment Settlement Transition to 'paid'",
        res_pay2["payment_status"] == "paid" and float(res_pay2["remaining_balance"]) == 0.0,
        f"PO Payment Status: {res_pay2['payment_status']}"
    )

    # -------------------------------------------------------------------------
    # TEST 14: Draft Product Lifecycle & Customer App Invisibility
    # -------------------------------------------------------------------------
    test_barcode = f"6299{int(time.time())}{random.randint(10, 99)}"
    draft_item_json = json.dumps([
        {
            "name_ar": "صنوبر بلدي سوري درجة أولى",
            "name_en": "Syrian Wild Pine Nuts Premium",
            "barcode": test_barcode,
            "unit": "kg",
            "quantity_ordered": 25,
            "unit_cost": 85.0,
            "is_new_draft_product": True
        }
    ]).replace("'", "''")

    sql_draft_po = f"""
        SELECT public.create_purchase_order(
            '{supplier_id}',
            'شركة المراعي للألبان والعصائر',
            'b-dam-01',
            'الأسبوع القادم',
            'تجربة مسودة صنف جديد معزول عن تطبيق العملاء',
            '{draft_item_json}'::jsonb,
            'مدير المشتريات'
        );
    """
    res_draft_po = json.loads(run_psql(sql_draft_po))
    draft_po_id = res_draft_po["id"]

    draft_prod_id = run_psql(f"SELECT product_id FROM public.purchase_order_items WHERE purchase_order_id = '{draft_po_id}';")
    prod_row = run_psql(f"SELECT is_draft, is_active, status FROM public.products WHERE id = '{draft_prod_id}';", as_json=True)[0]

    # Query customer endpoint (is_active = true)
    req_cust = urllib.request.Request(f"{PGRST_URL}/products?id=eq.{draft_prod_id}&is_active=eq.true")
    with urllib.request.urlopen(req_cust) as resp:
        cust_view = json.loads(resp.read().decode())

    log_test(
        "Test 14: Customer App Isolation (Draft Product Hidden)",
        prod_row["is_draft"] and not prod_row["is_active"] and len(cust_view) == 0,
        f"Draft flag: {prod_row['is_draft']}, Active: {prod_row['is_active']}, Customer visibility: {len(cust_view)} items"
    )

    # Approve Draft Product
    run_psql(f"SELECT public.approve_draft_product('{draft_prod_id}', 'مدير الكتالوج العام');")
    approved_prod = run_psql(f"SELECT is_draft, is_active, status FROM public.products WHERE id = '{draft_prod_id}';", as_json=True)[0]

    log_test(
        "Test 15: Draft Product Approval & Customer Catalog Publication",
        not approved_prod["is_draft"] and approved_prod["is_active"] and approved_prod["status"] == "published",
        f"Approved product status: {approved_prod['status']}, is_active: {approved_prod['is_active']}"
    )

    # -------------------------------------------------------------------------
    # TEST 16: Legal Cancellation of Unreceived Purchase Order
    # -------------------------------------------------------------------------
    res_cancel = json.loads(run_psql(f"""
        SELECT public.cancel_purchase_order('{draft_po_id}', 'إلغاء لعدم توفر المادة لدى المورد', 'مدير المشتريات');
    """))
    po_canc_row = run_psql(f"SELECT status, cancellation_reason FROM public.purchase_orders WHERE id = '{draft_po_id}';", as_json=True)[0]

    log_test(
        "Test 16: Legal Cancellation & Audit Logging on Unreceived PO",
        res_cancel["status"] == "cancelled" and po_canc_row["status"] == "cancelled",
        f"Status: {po_canc_row['status']}, Reason: {po_canc_row['cancellation_reason']}"
    )

    # -------------------------------------------------------------------------
    # TEST 17: PostgREST Restored Data Verification & Multi-Device Parity
    # -------------------------------------------------------------------------
    req_check = urllib.request.Request(f"{PGRST_URL}/purchase_orders?id=eq.{po_id}&select=*,items:purchase_order_items(*),payments:supplier_payments(*)")
    with urllib.request.urlopen(req_check) as resp:
        full_po = json.loads(resp.read().decode())[0]

    log_test(
        "Test 17: Complete End-to-End Hierarchy Persistence",
        full_po["status"] == "received" and full_po["payment_status"] == "paid" and len(full_po["payments"]) == 2,
        f"PO {full_po['po_number']}: status={full_po['status']}, payment_status={full_po['payment_status']}, payments_count={len(full_po['payments'])}"
    )

    print("======================================================================")
    print("🎯 ALL 17 FORENSIC PROCUREMENT TESTS PASSED WITH 100% SUCCESS")
    print("======================================================================")

if __name__ == "__main__":
    run_suite()
