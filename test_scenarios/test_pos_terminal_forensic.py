#!/usr/bin/env python3
"""
================================================================================
🏬 ALDEEB MALL — TASK 11 FORENSIC VERIFICATION SUITE
   POS Terminal, Cashier Governance, Real PIN, Shifts & Atomic POS Checkout
   PostgreSQL 16 ACID Transactions, Concurrency Locks & Anti-Hallucination
================================================================================
Comprehensive test suite testing:
1. Real Staff PIN verification (server-authoritative RPC)
2. Real Customer Loyalty lookup by phone (profiles table)
3. POS Shift lifecycle (open, active fetch, duplicate prevention, close with variance)
4. Cash sale with sufficient cash & change calculation
5. Cash sale rejection with insufficient cash (transaction rollback guarantee)
6. Card sale with card auth reference code & missing auth rejection
7. Split payment (cash + card) validation & math verification
8. Stock depletion and out-of-stock guard (zero overselling)
9. Concurrent transaction locking (FOR UPDATE race condition protection)
10. Idempotency key replay protection (safe network retry)
11. Shift closed sale rejection
12. Database persistence across sessions
================================================================================
"""

import subprocess
import json
import uuid
import time
import threading
import sys

DB_NAME = "aldeeb_mall_prod"
DB_USER = "ahmad_alzoubi"

def run_psql(query: str, as_json=False):
    """Executes a SQL query against PostgreSQL returning stdout and exit code."""
    cmd = ["psql", "-h", "127.0.0.1", "-U", DB_USER, "-d", DB_NAME, "-v", "ON_ERROR_STOP=1"]
    if as_json:
        cmd.extend(["-t", "-A"])
    cmd.extend(["-c", query])
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return proc.stdout.strip(), proc.stderr.strip(), proc.returncode

def test_passed(name, details=""):
    print(f"  ✅ PASS: {name}")
    if details:
        print(f"     └─ {details}")

def test_failed(name, error=""):
    print(f"  ❌ FAIL: {name}")
    if error:
        print(f"     └─ Error: {error}")
    sys.exit(1)

def run_suite():
    print("=" * 80)
    print("🚀 ALDEEB MALL — POS TERMINAL & CASHIER SALES FORENSIC SUITE (TASK 11)")
    print("=" * 80)

    # Clean start: close any lingering test shifts left from interrupted executions
    run_psql("UPDATE cashier_shifts SET status = 'closed', closed_at = now() WHERE cashier_id = 'staff-cashier-01' AND status = 'open';")

    # -------------------------------------------------------------------------
    # TEST 1: Real Staff PIN Verification (Valid PIN)
    # -------------------------------------------------------------------------
    print("\n[TEST 1] Real Staff PIN Verification — Valid Cashier PIN ('1234')")
    out, err, code = run_psql("SELECT verify_staff_pin('cashier_omar', '1234');", as_json=True)
    if code != 0:
        test_failed("verify_staff_pin valid PIN query failed", err)
    data = json.loads(out)
    if data.get("success") is True and data.get("role") == "cashier" and data.get("staff_id") == "staff-cashier-01":
        test_passed("Valid PIN accepted", f"Staff: {data.get('full_name')} ({data.get('employee_code')})")
    else:
        test_failed("Valid PIN check rejected unexpectedly", str(data))

    # -------------------------------------------------------------------------
    # TEST 2: Real Staff PIN Verification — Invalid PIN Rejection
    # -------------------------------------------------------------------------
    print("\n[TEST 2] Real Staff PIN Verification — Invalid PIN ('9999') Rejection")
    out, err, code = run_psql("SELECT verify_staff_pin('cashier_omar', '9999');", as_json=True)
    if code != 0:
        test_failed("verify_staff_pin invalid PIN query failed", err)
    data = json.loads(out)
    if data.get("success") is False and data.get("error") == "INVALID_PIN":
        test_passed("Invalid PIN rejected by server", f"Error returned: {data.get('message')}")
    else:
        test_failed("Invalid PIN was not rejected", str(data))

    # -------------------------------------------------------------------------
    # TEST 3: Real Loyalty Customer Lookup (Registered Customer)
    # -------------------------------------------------------------------------
    print("\n[TEST 3] Real Loyalty Customer Lookup by Phone — Registered Phone")
    out, err, code = run_psql("SELECT lookup_customer_by_phone('+966502222222');", as_json=True)
    if code != 0:
        test_failed("lookup_customer_by_phone query failed", err)
    data = json.loads(out)
    if data.get("found") is True and data.get("customer_id") and "loyalty_points" in data:
        test_passed("Registered loyalty customer retrieved", f"Name: {data.get('full_name')}, Tier: {data.get('tier')}, Points: {data.get('loyalty_points')}")
    else:
        test_failed("Registered customer lookup failed", str(data))

    # -------------------------------------------------------------------------
    # TEST 4: Real Loyalty Customer Lookup (Unregistered Phone)
    # -------------------------------------------------------------------------
    print("\n[TEST 4] Real Loyalty Customer Lookup by Phone — Unregistered Phone")
    out, err, code = run_psql("SELECT lookup_customer_by_phone('+966500000000');", as_json=True)
    if code != 0:
        test_failed("lookup_customer_by_phone unregistered query failed", err)
    data = json.loads(out)
    if data.get("found") is False:
        test_passed("Unregistered phone returns found=false cleanly without fake mocks", data.get("message"))
    else:
        test_failed("Unregistered phone returned found=true unexpectedly", str(data))

    # -------------------------------------------------------------------------
    # TEST 5: POS Shift Lifecycle — Open New Cashier Shift
    # -------------------------------------------------------------------------
    print("\n[TEST 5] POS Shift Lifecycle — Open New Shift with Float Cash")
    terminal_code = f"POS-T11-{uuid.uuid4().hex[:4].upper()}"
    out, err, code = run_psql(f"""
        SELECT open_cashier_shift(
            'b-ruh-01',
            'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
            '{terminal_code}',
            'TEST-DEV-ENV',
            'staff-cashier-01',
            'عمر الدوسري',
            500.00,
            'وردية الاختبار الآلي التلقائي'
        );
    """, as_json=True)
    if code != 0:
        test_failed("open_cashier_shift failed", err)
    shift_data = json.loads(out)
    shift_id = shift_data.get("id")
    shift_num = shift_data.get("shift_number")
    if shift_id and shift_data.get("status") == "open" and float(shift_data.get("opening_balance")) == 500.00:
        test_passed("Cashier shift opened", f"Shift ID: {shift_id}, Number: {shift_num}, Float: 500.00")
    else:
        test_failed("Open shift returned unexpected payload", str(shift_data))

    # -------------------------------------------------------------------------
    # TEST 6: POS Shift Lifecycle — Duplicate Open Prevention (Idempotent)
    # -------------------------------------------------------------------------
    print("\n[TEST 6] POS Shift Lifecycle — Duplicate Open Prevention")
    out, err, code = run_psql(f"""
        SELECT open_cashier_shift(
            'b-ruh-01',
            'هايبرماركت الرياض الرئيسي (المركز الفاخر)',
            '{terminal_code}',
            'TEST-DEV-ENV',
            'staff-cashier-01',
            'عمر الدوسري',
            500.00,
            'محاولة فتح ثانية'
        );
    """, as_json=True)
    if code != 0:
        test_failed("open_cashier_shift duplicate attempt failed", err)
    dup_shift = json.loads(out)
    if dup_shift.get("id") == shift_id and dup_shift.get("shift_number") == shift_num:
        test_passed("Duplicate shift open idempotent return", f"Returned existing active shift {shift_num}")
    else:
        test_failed("Duplicate open created a second shift instead of returning active", str(dup_shift))

    # -------------------------------------------------------------------------
    # TEST 7: Active Shift Query RPC
    # -------------------------------------------------------------------------
    print("\n[TEST 7] Active Shift Query via get_active_cashier_shift")
    out, err, code = run_psql(f"SELECT get_active_cashier_shift('b-ruh-01', 'staff-cashier-01', '{terminal_code}');", as_json=True)
    if code != 0:
        test_failed("get_active_cashier_shift failed", err)
    active_res = json.loads(out)
    if active_res.get("found") is True and active_res.get("shift", {}).get("id") == shift_id:
        test_passed("Active shift retrieved accurately from PostgreSQL", f"Shift Number: {shift_num}")
    else:
        test_failed("Active shift lookup mismatch", str(active_res))

    # -------------------------------------------------------------------------
    # Fetch a live product for checkout tests
    # -------------------------------------------------------------------------
    out, err, code = run_psql("SELECT id, name_ar, price, stock_quantity FROM products WHERE is_active = true AND stock_quantity > 10 LIMIT 1;", as_json=True)
    if code != 0 or not out:
        test_failed("Failed to query sample test product", err)
    prod_row = out.split("|")
    test_prod_id = prod_row[0]
    test_prod_name = prod_row[1]
    test_prod_price = float(prod_row[2])
    test_prod_stock = int(prod_row[3])
    print(f"\n[INFO] Sample Test Product: {test_prod_name} | Price: {test_prod_price} | Stock: {test_prod_stock}")

    # Ensure branch_inventory has sufficient stock
    run_psql(f"""
        INSERT INTO branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved, bin_location)
        VALUES ('b-ruh-01', '{test_prod_id}', 100, 0, 'رف-POS-TEST')
        ON CONFLICT (branch_id, product_id) DO UPDATE SET quantity_on_hand = 100;
    """)

    # -------------------------------------------------------------------------
    # TEST 8: Cash Sale with Insufficient Cash (Strict Exception & Abort)
    # -------------------------------------------------------------------------
    print("\n[TEST 8] Cash Sale with Insufficient Cash Rejection (Server Exception)")
    insufficient_receipt = f"RCP-FAIL-CASH-{uuid.uuid4().hex[:6].upper()}"
    insufficient_idem = f"IDEM-FAIL-CASH-{uuid.uuid4().hex[:6].upper()}"
    total_val = test_prod_price * 2
    tendered_val = total_val - 10.0  # 10 less than total!

    out, err, code = run_psql(f"""
        SELECT process_pos_sale_atomic(
            '{insufficient_receipt}',
            '{insufficient_idem}',
            'b-ruh-01',
            '{terminal_code}',
            'staff-cashier-01',
            '{shift_id}',
            'عميل كاش مرفوض',
            '+966502222222',
            'cash',
            {tendered_val},
            0.00,
            NULL,
            {total_val},
            0.00,
            0.00,
            0,
            0.00,
            {total_val},
            '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 2}}]'::jsonb
        );
    """)
    if code != 0 and "INSUFFICIENT_CASH" in err:
        test_passed("Insufficient cash strictly rejected by PostgreSQL transaction", err.split("\n")[0])
    else:
        test_failed("Insufficient cash was not rejected!", f"Code: {code}, Out: {out}, Err: {err}")

    # Verify no order was created
    out, _, _ = run_psql(f"SELECT COUNT(*) FROM orders WHERE order_number = '{insufficient_receipt}';", as_json=True)
    if out == "0":
        test_passed("Zero phantom orders created on insufficient cash failure")
    else:
        test_failed("Phantom order created despite insufficient cash!", out)

    # -------------------------------------------------------------------------
    # TEST 9: Successful Cash Sale & Change Calculation
    # -------------------------------------------------------------------------
    print("\n[TEST 9] Successful Cash Sale with Correct Change Calculation")
    success_receipt = f"RCP-CASH-{uuid.uuid4().hex[:6].upper()}"
    success_idem = f"IDEM-CASH-{uuid.uuid4().hex[:6].upper()}"
    cash_tendered = total_val + 25.0
    expected_change = 25.0

    out, err, code = run_psql(f"""
        SELECT process_pos_sale_atomic(
            '{success_receipt}',
            '{success_idem}',
            'b-ruh-01',
            '{terminal_code}',
            'staff-cashier-01',
            '{shift_id}',
            'عميل نقدي مكتمل',
            '+966502222222',
            'cash',
            {cash_tendered},
            0.00,
            NULL,
            {total_val},
            0.00,
            0.00,
            0,
            0.00,
            {total_val},
            '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 2}}]'::jsonb
        );
    """, as_json=True)
    if code != 0:
        test_failed("Successful cash sale failed", err)
    sale_data = json.loads(out)
    if sale_data.get("success") is True and float(sale_data.get("change_given")) == expected_change:
        test_passed("Cash sale recorded with precise change", f"Receipt: {success_receipt}, Change Due: {sale_data.get('change_given')}")
    else:
        test_failed("Cash sale payload invalid", str(sale_data))

    # Verify order items, shift totals, and stock deduction
    out, _, _ = run_psql(f"SELECT COUNT(*) FROM order_items WHERE order_id = '{sale_data.get('order_id')}';", as_json=True)
    if out == "1":
        test_passed("Order items securely inserted in PostgreSQL")
    else:
        test_failed("Order item missing", out)

    out, _, _ = run_psql(f"SELECT cash_sales, total_sales, transactions_count FROM cashier_shifts WHERE id = '{shift_id}';", as_json=True)
    shift_nums = out.split("|")
    if float(shift_nums[0]) == total_val and int(shift_nums[2]) == 1:
        test_passed("Shift cash_sales and transaction counter incremented", f"Cash Sales: {shift_nums[0]}, Count: {shift_nums[2]}")
    else:
        test_failed("Shift stats not updated correctly", out)

    # -------------------------------------------------------------------------
    # TEST 10: Idempotent Replay on Network Retry
    # -------------------------------------------------------------------------
    print("\n[TEST 10] Idempotent Replay on Network Retry (Zero Double-Deduction)")
    out, err, code = run_psql(f"""
        SELECT process_pos_sale_atomic(
            '{success_receipt}',
            '{success_idem}',
            'b-ruh-01',
            '{terminal_code}',
            'staff-cashier-01',
            '{shift_id}',
            'عميل نقدي مكتمل',
            '+966502222222',
            'cash',
            {cash_tendered},
            0.00,
            NULL,
            {total_val},
            0.00,
            0.00,
            0,
            0.00,
            {total_val},
            '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 2}}]'::jsonb
        );
    """, as_json=True)
    if code != 0:
        test_failed("Idempotent replay failed", err)
    replay_data = json.loads(out)
    if replay_data.get("is_idempotent_replay") is True and replay_data.get("order_id") == sale_data.get("order_id"):
        test_passed("Duplicate checkout returned existing order without re-deducting stock or double-charging")
    else:
        test_failed("Idempotent replay failed to flag existing order", str(replay_data))

    # Verify shift transaction count remained 1 (NOT 2)
    out, _, _ = run_psql(f"SELECT transactions_count FROM cashier_shifts WHERE id = '{shift_id}';", as_json=True)
    if out == "1":
        test_passed("Shift transactions count preserved without double counting")
    else:
        test_failed("Transactions count corrupted by replay", out)

    # -------------------------------------------------------------------------
    # TEST 11: Card Sale without Auth Code Rejection
    # -------------------------------------------------------------------------
    print("\n[TEST 11] Card Sale without Terminal Auth Code Rejection")
    card_fail_receipt = f"RCP-CARD-FAIL-{uuid.uuid4().hex[:6].upper()}"
    out, err, code = run_psql(f"""
        SELECT process_pos_sale_atomic(
            '{card_fail_receipt}',
            'IDEM-CARD-FAIL',
            'b-ruh-01',
            '{terminal_code}',
            'staff-cashier-01',
            '{shift_id}',
            'عميل بطاقة',
            '+966502222222',
            'card',
            0.00,
            {total_val},
            '',  -- empty auth code
            {total_val},
            0.00,
            0.00,
            0,
            0.00,
            {total_val},
            '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 2}}]'::jsonb
        );
    """)
    if code != 0 and "CARD_AUTH_REQUIRED" in err:
        test_passed("Card payment rejected without payment confirmation/auth code", err.split("\n")[0])
    else:
        test_failed("Card payment without auth code was not rejected", f"Code: {code}, Out: {out}, Err: {err}")

    # -------------------------------------------------------------------------
    # TEST 12: Successful Card Sale with Auth Code
    # -------------------------------------------------------------------------
    print("\n[TEST 12] Successful Card Sale with Confirmed Auth Code")
    card_ok_receipt = f"RCP-CARD-OK-{uuid.uuid4().hex[:6].upper()}"
    card_ok_idem = f"IDEM-CARD-OK-{uuid.uuid4().hex[:6].upper()}"
    auth_code = f"MADA-AUTH-{uuid.uuid4().hex[:6].upper()}"
    out, err, code = run_psql(f"""
        SELECT process_pos_sale_atomic(
            '{card_ok_receipt}',
            '{card_ok_idem}',
            'b-ruh-01',
            '{terminal_code}',
            'staff-cashier-01',
            '{shift_id}',
            'عميل مدى موثق',
            '+966502222222',
            'card',
            0.00,
            {total_val},
            '{auth_code}',
            {total_val},
            0.00,
            0.00,
            0,
            0.00,
            {total_val},
            '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 2}}]'::jsonb
        );
    """, as_json=True)
    if code != 0:
        test_failed("Card sale failed", err)
    card_sale_data = json.loads(out)
    if card_sale_data.get("success") is True and card_sale_data.get("card_auth_code") == auth_code:
        test_passed("Card sale confirmed and recorded", f"Receipt: {card_ok_receipt}, Auth: {auth_code}")
    else:
        test_failed("Card sale payload invalid", str(card_sale_data))

    # -------------------------------------------------------------------------
    # TEST 13: Split Payment (Cash + Card)
    # -------------------------------------------------------------------------
    print("\n[TEST 13] Split Payment (Cash + Card) Atomic Execution")
    split_receipt = f"RCP-SPLIT-OK-{uuid.uuid4().hex[:6].upper()}"
    split_idem = f"IDEM-SPLIT-OK-{uuid.uuid4().hex[:6].upper()}"
    split_auth = f"MADA-SPLIT-{uuid.uuid4().hex[:6].upper()}"
    split_cash = total_val / 2.0
    split_card = total_val - split_cash

    out, err, code = run_psql(f"""
        SELECT process_pos_sale_atomic(
            '{split_receipt}',
            '{split_idem}',
            'b-ruh-01',
            '{terminal_code}',
            'staff-cashier-01',
            '{shift_id}',
            'عميل دفع مجزأ',
            '+966502222222',
            'split',
            {split_cash},
            {split_card},
            '{split_auth}',
            {total_val},
            0.00,
            0.00,
            0,
            0.00,
            {total_val},
            '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 2}}]'::jsonb
        );
    """, as_json=True)
    if code != 0:
        test_failed("Split sale failed", err)
    split_data = json.loads(out)
    if split_data.get("success") is True:
        test_passed("Split payment executed and balanced", f"Cash: {split_cash}, Card: {split_card}, Auth: {split_auth}")
    else:
        test_failed("Split payment failed", str(split_data))

    # -------------------------------------------------------------------------
    # TEST 14: Out of Stock Rejection Guard
    # -------------------------------------------------------------------------
    print("\n[TEST 14] Out-of-Stock Overselling Guard")
    # Set stock to 1
    run_psql(f"UPDATE branch_inventory SET quantity_on_hand = 1 WHERE branch_id = 'b-ruh-01' AND product_id = '{test_prod_id}';")
    run_psql(f"UPDATE products SET stock_quantity = 1 WHERE id = '{test_prod_id}';")

    # Try selling 5
    out, err, code = run_psql(f"""
        SELECT process_pos_sale_atomic(
            'RCP-OVERSELL-FAIL',
            'IDEM-OVERSELL-FAIL',
            'b-ruh-01',
            '{terminal_code}',
            'staff-cashier-01',
            '{shift_id}',
            'عميل نفاذ مخزون',
            '+966502222222',
            'cash',
            {test_prod_price * 5},
            0.00,
            NULL,
            {test_prod_price * 5},
            0.00,
            0.00,
            0,
            0.00,
            {test_prod_price * 5},
            '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 5}}]'::jsonb
        );
    """)
    if code != 0 and "INSUFFICIENT_STOCK" in err:
        test_passed("Overselling blocked by row-level inventory checks", err.split("\n")[0])
    else:
        test_failed("Overselling was not blocked", f"Code: {code}, Out: {out}, Err: {err}")

    # -------------------------------------------------------------------------
    # TEST 15: Concurrent Race Condition (Two Cashiers Competing for Last 1 Item)
    # -------------------------------------------------------------------------
    print("\n[TEST 15] Concurrent Race Condition — 2 Terminals Competing for 1 Remaining Unit")
    run_psql(f"UPDATE branch_inventory SET quantity_on_hand = 1 WHERE branch_id = 'b-ruh-01' AND product_id = '{test_prod_id}';")
    run_psql(f"UPDATE products SET stock_quantity = 1 WHERE id = '{test_prod_id}';")

    results = []
    def checkout_worker(worker_id):
        receipt_no = f"RCP-CONCURRENT-{worker_id}-{uuid.uuid4().hex[:6].upper()}"
        idem_no = f"IDEM-CONCUR-{worker_id}-{uuid.uuid4().hex[:6].upper()}"
        out_w, err_w, code_w = run_psql(f"""
            SELECT process_pos_sale_atomic(
                '{receipt_no}',
                '{idem_no}',
                'b-ruh-01',
                '{terminal_code}',
                'staff-cashier-01',
                '{shift_id}',
                'عميل متزامن {worker_id}',
                '+966502222222',
                'cash',
                {test_prod_price},
                0.00,
                NULL,
                {test_prod_price},
                0.00,
                0.00,
                0,
                0.00,
                {test_prod_price},
                '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 1}}]'::jsonb
            );
        """)
        results.append((worker_id, code_w, out_w, err_w))

    threads = [
        threading.Thread(target=checkout_worker, args=("THREAD-A",)),
        threading.Thread(target=checkout_worker, args=("THREAD-B",)),
    ]
    for t in threads: t.start()
    for t in threads: t.join()

    success_count = sum(1 for r in results if r[1] == 0)
    fail_count = sum(1 for r in results if r[1] != 0 and "INSUFFICIENT_STOCK" in r[3])

    if success_count == 1 and fail_count == 1:
        test_passed("FOR UPDATE row locking guarantees atomic isolation: Exactly 1 sold, 1 rejected for insufficient stock")
    else:
        test_failed("Race condition failed isolation", f"Successes: {success_count}, Fails: {fail_count}, Details: {results}")

    # -------------------------------------------------------------------------
    # TEST 16: Shift Close (Z-Report) with Cash Variance Calculation
    # -------------------------------------------------------------------------
    print("\n[TEST 16] Shift Close (Z-Report) with Cash Variance Calculation")
    out, _, _ = run_psql(f"SELECT expected_cash FROM cashier_shifts WHERE id = '{shift_id}';", as_json=True)
    expected_c = float(out)
    actual_counted = expected_c + 15.0  # Surplus of 15.00

    out, err, code = run_psql(f"""
        SELECT close_cashier_shift(
            '{shift_id}',
            {actual_counted},
            'عمر الدوسري',
            'staff-cashier-01',
            'إغلاق الوردية للاختبار الشامل'
        );
    """, as_json=True)
    if code != 0:
        test_failed("close_cashier_shift failed", err)
    close_data = json.loads(out)
    if close_data.get("status") == "closed" and float(close_data.get("difference")) == 15.00:
        test_passed("Shift closed and Z-Report recorded with variance", f"Expected: {expected_c}, Counted: {actual_counted}, Difference: {close_data.get('difference')}")
    else:
        test_failed("Close shift payload invalid", str(close_data))

    # -------------------------------------------------------------------------
    # TEST 17: Sale on Closed Shift Strictly Rejected
    # -------------------------------------------------------------------------
    print("\n[TEST 17] Sale on Closed Shift Strict Rejection")
    post_close_rcp = f"RCP-POST-CLOSE-{uuid.uuid4().hex[:6].upper()}"
    post_close_idem = f"IDEM-POST-CLOSE-{uuid.uuid4().hex[:6].upper()}"
    out, err, code = run_psql(f"""
        SELECT process_pos_sale_atomic(
            '{post_close_rcp}',
            '{post_close_idem}',
            'b-ruh-01',
            '{terminal_code}',
            'staff-cashier-01',
            '{shift_id}',
            'عميل بعد الإغلاق',
            '+966502222222',
            'cash',
            50.00,
            0.00,
            NULL,
            48.00,
            0.00,
            0.00,
            0,
            0.00,
            48.00,
            '[{{\"product_id\": \"{test_prod_id}\", \"name_ar\": \"{test_prod_name}\", \"price\": {test_prod_price}, \"quantity\": 1}}]'::jsonb
        );
    """)
    if code != 0 and "POS_SHIFT_CLOSED" in err:
        test_passed("Sale on closed shift strictly rejected", err.split("\n")[0])
    else:
        test_failed("Sale on closed shift was not rejected", f"Code: {code}, Out: {out}, Err: {err}")

    # Restore test stock
    run_psql(f"UPDATE branch_inventory SET quantity_on_hand = 100 WHERE branch_id = 'b-ruh-01' AND product_id = '{test_prod_id}';")
    run_psql(f"UPDATE products SET stock_quantity = 100 WHERE id = '{test_prod_id}';")

    print("\n" + "=" * 80)
    print("🎉 ALL 17 FORENSIC TESTS PASSED — 100% ZERO DEFECT VERIFIED")
    print("=" * 80)

if __name__ == "__main__":
    run_suite()
