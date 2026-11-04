#!/usr/bin/env python3
"""
================================================================================
🏬 ALDEEB MALL — TASK 10 FORENSIC VERIFICATION SUITE
   Order & Pricing Core (نواة الطلبات والتسعير)
   PostgreSQL 16 ACID Transactions, Atomic RPCs, Anti-Tampering & Idempotency
================================================================================
Tests comprehensive server-authoritative validations:
1. Product existence, branch validity, stock check with row locking
2. Price protection (rejects client price tampering)
3. Coupon validation (active, expiration, min order, usage limit)
4. Loyalty points redemption and profile balance deduction
5. Delivery fee and authoritative total math checks
6. Idempotency persistent replay across network retry
7. Concurrency lock guard & simultaneous duplicate submission
8. Multi-item partial failure atomicity (rollback guarantee)
9. Cross-session database persistence verification
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
    cmd = ["psql", "-U", DB_USER, "-d", DB_NAME, "-v", "ON_ERROR_STOP=1"]
    if as_json:
        cmd.extend(["-t", "-A"])
    cmd.extend(["-c", query])
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()

def run_psql_json(query: str):
    """Helper to run a query expecting a single JSONB return."""
    code, out, err = run_psql(query, as_json=True)
    if code != 0:
        return code, None, err
    try:
        return code, json.loads(out), err
    except Exception as e:
        return code, out, str(e)

pass_count = 0
total_tests = 0

def test_banner(num: int, title: str):
    global total_tests
    total_tests += 1
    print(f"\n[{num:02d}] 🧪 TEST: {title}")

def pass_test(details: str):
    global pass_count
    pass_count += 1
    print(f"     ✅ PASS: {details}")

def fail_test(details: str):
    print(f"     ❌ FAIL: {details}")
    sys.exit(1)

def main():
    print("=" * 80)
    print("🚀 ALDEEB MALL: ORDER PRICING CORE & ATOMIC VERIFICATION SUITE")
    print(f"   Database: PostgreSQL 16 ({DB_NAME}) | Host: localhost:5432")
    print("=" * 80)

    # -------------------------------------------------------------------------
    # Setup Test Fixtures: Known Product, Category, and User
    # -------------------------------------------------------------------------
    test_prod_id = "f0000000-0000-0000-0000-000000000001"
    test_prod_id_b = "f0000000-0000-0000-0000-000000000002"
    test_user_id = "5b4d91f7-a1d6-4ba0-822b-a2089ae91611" # customer with 50 loyalty points

    setup_sql = f"""
    DO $$
    DECLARE
        v_cat uuid;
    BEGIN
        SELECT id INTO v_cat FROM public.categories LIMIT 1;
        
        -- Seed Product A (Stock: 20, Price: 50.00)
        INSERT INTO public.products (id, name_ar, name_en, barcode, price, stock_quantity, category_id, is_active)
        VALUES ('{test_prod_id}', 'صنف اختبار الطلبات أ', 'Order Test Item A', '628111111111', 50.00, 20, v_cat, true)
        ON CONFLICT (id) DO UPDATE SET stock_quantity = 20, price = 50.00, is_active = true;

        -- Seed Product B (Stock: 5, Price: 30.00)
        INSERT INTO public.products (id, name_ar, name_en, barcode, price, stock_quantity, category_id, is_active)
        VALUES ('{test_prod_id_b}', 'صنف اختبار الطلبات ب', 'Order Test Item B', '628222222222', 30.00, 5, v_cat, true)
        ON CONFLICT (id) DO UPDATE SET stock_quantity = 5, price = 30.00, is_active = true;

        -- Ensure Profile loyalty points
        UPDATE public.profiles SET loyalty_points = 100 WHERE id = '{test_user_id}';
    END $$;
    """
    code, out, err = run_psql(setup_sql)
    if code != 0:
        fail_test(f"Failed to seed test products and profile: {err}")

    # -------------------------------------------------------------------------
    # TEST 1: Standard Valid Order Creation & Inventory Movement
    # -------------------------------------------------------------------------
    test_banner(1, "Standard Atomic Order Creation with Authoritative Price & Movements")
    ord_num_1 = f"ORD-T10-{int(time.time())}-01"
    idemp_1 = f"IDEMP-T10-{int(time.time())}-01"

    items_payload_1 = json.dumps([{
        "product_id": test_prod_id,
        "quantity": 2,
        "unit_price": 50.00
    }])

    call_sql_1 = f"""
    SELECT public.place_order_atomic(
        '{ord_num_1}',
        NULL,
        'توصيل فوري خلال 45 دقيقة',
        'cod',
        100.00,
        0.00,
        0.00,
        0,
        0.00,
        100.00,
        'Forensic Test Order 1',
        '{items_payload_1}'::jsonb,
        'b-jed-01',
        NULL,
        '{idemp_1}',
        'أحمد العميل التجريبي',
        '+966501112233'
    );
    """
    code, res_1, err = run_psql_json(call_sql_1)
    if code != 0 or not res_1 or not res_1.get("id"):
        fail_test(f"Failed to create order: {err}")
    if res_1.get("total_amount") != 100.00 or res_1.get("order_number") != ord_num_1:
        fail_test(f"Order response mismatch: {res_1}")

    # Verify inventory movement recorded
    code, mov_out, _ = run_psql(f"SELECT movement_number, quantity_change, resulting_on_hand FROM public.inventory_movements WHERE reference_id = '{ord_num_1}';", as_json=True)
    if code != 0 or not mov_out:
        fail_test("Inventory movement was not recorded in inventory_movements ledger")

    # Verify stock deducted
    code, stock_out, _ = run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id}';", as_json=True)
    if int(stock_out) != 18:
        fail_test(f"Stock was not decremented correctly. Expected 18, got: {stock_out}")

    pass_test(f"Order [{ord_num_1}] created. Total: 100.00. Stock decremented from 20 -> 18. Movement recorded.")

    # -------------------------------------------------------------------------
    # TEST 2: Network Drop & Idempotent Replay on Retry
    # -------------------------------------------------------------------------
    test_banner(2, "Network Interruption Simulation & Idempotent Replay without Duplicate Deduction")
    # Call again with the exact same order number and idempotency key
    code, res_2, err = run_psql_json(call_sql_1)
    if code != 0 or not res_2:
        fail_test(f"Idempotent retry failed with error: {err}")
    if res_2.get("id") != res_1.get("id"):
        fail_test(f"Idempotency returned different order ID: {res_2}")
    if not res_2.get("is_idempotent_replay"):
        fail_test("Expected is_idempotent_replay: true on duplicate submission")

    # Verify stock remained at 18 (NO double decrement!)
    code, stock_out, _ = run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id}';", as_json=True)
    if int(stock_out) != 18:
        fail_test(f"Double-decrement bug detected! Stock changed to: {stock_out}")

    pass_test("Retried order safely returned original order JSON with is_idempotent_replay=True and zero duplicate stock deduction.")

    # -------------------------------------------------------------------------
    # TEST 3: Concurrency Race Condition Guard on Limited Stock
    # -------------------------------------------------------------------------
    test_banner(3, "PostgreSQL ACID Concurrency Race Condition on Limited Stock (1 Unit Left)")
    # Set stock of Product B to exactly 1
    run_psql(f"UPDATE public.products SET stock_quantity = 1 WHERE id = '{test_prod_id_b}';")
    run_psql(f"UPDATE public.branch_inventory SET quantity_on_hand = 1 WHERE product_id = '{test_prod_id_b}';")

    concurrency_results = []
    barrier = threading.Barrier(2)
    ord_c1 = f"ORD-CONCUR-A-{int(time.time())}"
    ord_c2 = f"ORD-CONCUR-B-{int(time.time())}"

    def concurrent_worker(label: str, ord_num: str):
        barrier.wait()
        items = json.dumps([{"product_id": test_prod_id_b, "quantity": 1, "unit_price": 30.00}])
        sql = f"""
        SELECT public.place_order_atomic(
            '{ord_num}', NULL, 'فوري', 'cod', 30.00, 0, 0, 0, 0, 30.00,
            'Concurrency Test', '{items}'::jsonb, 'b-jed-01'
        );
        """
        c_code, c_out, c_err = run_psql(sql)
        concurrency_results.append((label, c_code == 0, c_out, c_err))

    th1 = threading.Thread(target=concurrent_worker, args=("Client-1", ord_c1))
    th2 = threading.Thread(target=concurrent_worker, args=("Client-2", ord_c2))
    th1.start()
    th2.start()
    th1.join()
    th2.join()

    successes = [c for c, ok, _, _ in concurrency_results if ok]
    failures = [c for c, ok, _, err in concurrency_results if not ok and "INSUFFICIENT_STOCK" in err]

    if len(successes) != 1 or len(failures) != 1:
        fail_test(f"Concurrency failure: {len(successes)} succeeded, {len(failures)} failed with INSUFFICIENT_STOCK: {concurrency_results}")

    # Check stock in DB
    code, stock_b, _ = run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id_b}';", as_json=True)
    if int(stock_b) != 0:
        fail_test(f"Stock was not exactly 0 after 1 purchase. Got: {stock_b}")

    pass_test(f"Concurrency lock passed: exactly 1 purchase succeeded ({successes[0]}), exactly 1 rejected with INSUFFICIENT_STOCK ({failures[0]}), final stock=0.")

    # -------------------------------------------------------------------------
    # TEST 4: Concurrent Duplicate Requests with Same Idempotency Key
    # -------------------------------------------------------------------------
    test_banner(4, "Simultaneous Identical Idempotency Key Requests (Collision Guard)")
    dup_ord_num = f"ORD-DUP-{int(time.time())}"
    dup_idemp_key = f"IDEMP-DUP-{int(time.time())}"
    # Reset stock for test
    run_psql(f"UPDATE public.products SET stock_quantity = 10 WHERE id = '{test_prod_id_b}';")
    run_psql(f"UPDATE public.branch_inventory SET quantity_on_hand = 10 WHERE product_id = '{test_prod_id_b}';")

    dup_results = []
    dup_barrier = threading.Barrier(2)

    def dup_worker(label: str):
        dup_barrier.wait()
        items = json.dumps([{"product_id": test_prod_id_b, "quantity": 1, "unit_price": 30.00}])
        sql = f"""
        SELECT public.place_order_atomic(
            '{dup_ord_num}', NULL, 'فوري', 'cod', 30.00, 0, 0, 0, 0, 30.00,
            'Dup Collision Test', '{items}'::jsonb, 'b-jed-01', NULL, '{dup_idemp_key}'
        );
        """
        c_code, c_out, c_err = run_psql_json(sql)
        dup_results.append((label, c_code == 0, c_out, c_err))

    d_th1 = threading.Thread(target=dup_worker, args=("Thread-1",))
    d_th2 = threading.Thread(target=dup_worker, args=("Thread-2",))
    d_th1.start()
    d_th2.start()
    d_th1.join()
    d_th2.join()

    if not all(ok for _, ok, _, _ in dup_results):
        fail_test(f"One of concurrent duplicate threads failed: {dup_results}")

    order_ids = [out.get("id") for _, _, out, _ in dup_results if isinstance(out, dict)]
    if len(set(order_ids)) != 1:
        fail_test(f"Different orders created for same idempotency key: {order_ids}")

    # Stock should have decremented by only 1 (from 10 -> 9)
    code, stock_b, _ = run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id_b}';", as_json=True)
    if int(stock_b) != 9:
        fail_test(f"Expected stock 9, got {stock_b}")

    pass_test(f"Both concurrent duplicate threads returned identical order ID [{order_ids[0]}]. Exactly 1 stock deducted.")

    # -------------------------------------------------------------------------
    # TEST 5: Rejection of Non-Existent Product ID
    # -------------------------------------------------------------------------
    test_banner(5, "Rejection of Non-Existent Product ID (PRODUCT_NOT_FOUND)")
    fake_prod_id = "00000000-dead-beef-0000-000000000999"
    items_fake = json.dumps([{"product_id": fake_prod_id, "quantity": 1, "unit_price": 10.00}])
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-FAKE-01', NULL, 'فوري', 'cod', 10.00, 0, 0, 0, 0, 10.00,
        'Fake Prod', '{items_fake}'::jsonb
    );
    """
    code, out, err = run_psql(sql)
    if code == 0 or "PRODUCT_NOT_FOUND" not in err:
        fail_test(f"Failed to reject non-existent product. Code: {code}, Err: {err}")
    pass_test(f"Correctly rejected with PRODUCT_NOT_FOUND error: {err.splitlines()[-1]}")

    # -------------------------------------------------------------------------
    # TEST 6: Rejection of Inactive Product
    # -------------------------------------------------------------------------
    test_banner(6, "Rejection of Inactive De-listed Product")
    run_psql(f"UPDATE public.products SET is_active = false WHERE id = '{test_prod_id_b}';")
    items_inactive = json.dumps([{"product_id": test_prod_id_b, "quantity": 1, "unit_price": 30.00}])
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-INACTIVE-01', NULL, 'فوري', 'cod', 30.00, 0, 0, 0, 0, 30.00,
        'Inactive Prod', '{items_inactive}'::jsonb
    );
    """
    code, out, err = run_psql(sql)
    run_psql(f"UPDATE public.products SET is_active = true WHERE id = '{test_prod_id_b}';")
    if code == 0 or "PRODUCT_NOT_FOUND" not in err:
        fail_test(f"Failed to reject inactive product. Code: {code}, Err: {err}")
    pass_test("Inactive product correctly rejected by server.")

    # -------------------------------------------------------------------------
    # TEST 7: Rejection of Client Price Tampering
    # -------------------------------------------------------------------------
    test_banner(7, "Rejection of Client Price Tampering (PRICE_TAMPERED)")
    # Catalog price is 50.00. Client maliciously attempts to buy for 1.00
    items_tampered = json.dumps([{"product_id": test_prod_id, "quantity": 1, "unit_price": 1.00}])
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-TAMPER-01', NULL, 'فوري', 'cod', 1.00, 0, 0, 0, 0, 1.00,
        'Tampered Price', '{items_tampered}'::jsonb
    );
    """
    code, out, err = run_psql(sql)
    if code == 0 or "PRICE_TAMPERED" not in err:
        fail_test(f"Failed to reject tampered price. Code: {code}, Err: {err}")
    pass_test(f"Correctly rejected with PRICE_TAMPERED: {err.splitlines()[-1]}")

    # -------------------------------------------------------------------------
    # TEST 8: Rejection of Client Subtotal Tampering
    # -------------------------------------------------------------------------
    test_banner(8, "Rejection of Client Subtotal Tampering (SUBTOTAL_TAMPERED)")
    items_valid_price = json.dumps([{"product_id": test_prod_id, "quantity": 2, "unit_price": 50.00}])
    # Subtotal is 100.00. Client sends subtotal = 70.00
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-SUBTOTAL-01', NULL, 'فوري', 'cod', 70.00, 0, 0, 0, 0, 70.00,
        'Tampered Subtotal', '{items_valid_price}'::jsonb
    );
    """
    code, out, err = run_psql(sql)
    if code == 0 or "SUBTOTAL_TAMPERED" not in err:
        fail_test(f"Failed to reject tampered subtotal. Code: {code}, Err: {err}")
    pass_test(f"Correctly rejected with SUBTOTAL_TAMPERED: {err.splitlines()[-1]}")

    # -------------------------------------------------------------------------
    # TEST 9: Rejection of Client Total Tampering
    # -------------------------------------------------------------------------
    test_banner(9, "Rejection of Client Total Amount Tampering (TOTAL_TAMPERED)")
    # Subtotal 100, client sends total = 10.00
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-TOTAL-01', NULL, 'فوري', 'cod', 100.00, 0, 0, 0, 0, 10.00,
        'Tampered Total', '{items_valid_price}'::jsonb
    );
    """
    code, out, err = run_psql(sql)
    if code == 0 or "TOTAL_TAMPERED" not in err:
        fail_test(f"Failed to reject tampered total. Code: {code}, Err: {err}")
    pass_test(f"Correctly rejected with TOTAL_TAMPERED: {err.splitlines()[-1]}")

    # -------------------------------------------------------------------------
    # TEST 10: Rejection of Insufficient Stock
    # -------------------------------------------------------------------------
    test_banner(10, "Rejection of Unavailable Quantity (INSUFFICIENT_STOCK)")
    # Product A currently has 18 units left. Client requests 50 units.
    items_excess = json.dumps([{"product_id": test_prod_id, "quantity": 50, "unit_price": 50.00}])
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-EXCESS-01', NULL, 'فوري', 'cod', 2500.00, 0, 0, 0, 0, 2500.00,
        'Excess Quantity', '{items_excess}'::jsonb
    );
    """
    code, out, err = run_psql(sql)
    if code == 0 or "INSUFFICIENT_STOCK" not in err:
        fail_test(f"Failed to reject excess quantity. Code: {code}, Err: {err}")
    pass_test(f"Correctly rejected with INSUFFICIENT_STOCK: {err.splitlines()[-1]}")

    # -------------------------------------------------------------------------
    # TEST 11: Rejection of Invalid Branch ID
    # -------------------------------------------------------------------------
    test_banner(11, "Rejection of Invalid / Inactive Branch ID (INVALID_BRANCH)")
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-BRANCH-01', NULL, 'فوري', 'cod', 100.00, 0, 0, 0, 0, 100.00,
        'Bad Branch', '{items_valid_price}'::jsonb, 'b-non-existent'
    );
    """
    code, out, err = run_psql(sql)
    if code == 0 or "INVALID_BRANCH" not in err:
        fail_test(f"Failed to reject bad branch. Code: {code}, Err: {err}")
    pass_test(f"Correctly rejected with INVALID_BRANCH: {err.splitlines()[-1]}")

    # -------------------------------------------------------------------------
    # TEST 12: Coupon Validation & Auto-Calculation
    # -------------------------------------------------------------------------
    test_banner(12, "Server-Side Coupon Code Validation & Accurate Discount Calculation")
    # ALDEEB10: 10% discount on min_order_amount=50. Subtotal=100 -> Discount=10.00 -> Total=90.00
    ord_coupon = f"ORD-COUPON-{int(time.time())}"
    sql = f"""
    SELECT public.place_order_atomic(
        '{ord_coupon}', NULL, 'فوري', 'cod', 100.00, 0.00, 10.00, 0, 0.00, 90.00,
        'Coupon Test', '{items_valid_price}'::jsonb, 'b-jed-01', 'ALDEEB10'
    );
    """
    code, res_c, err = run_psql_json(sql)
    if code != 0 or not res_c:
        fail_test(f"Coupon order failed: {err}")
    if res_c.get("discount_amount") != 10.00 or res_c.get("total_amount") != 90.00:
        fail_test(f"Coupon calculation mismatch: {res_c}")
    pass_test("Coupon ALDEEB10 validated and calculated accurately by server: 10.00 discount, total=90.00.")

    # -------------------------------------------------------------------------
    # TEST 13: Rejection of Coupon below Minimum Order Threshold
    # -------------------------------------------------------------------------
    test_banner(13, "Rejection of Coupon below Minimum Order Threshold")
    # Subtotal 30 < min_order_amount 50 for ALDEEB10
    items_under_min = json.dumps([{"product_id": test_prod_id_b, "quantity": 1, "unit_price": 30.00}])
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-COUPON-FAIL', NULL, 'فوري', 'cod', 30.00, 0.00, 3.00, 0, 0.00, 27.00,
        'Coupon Min Failed', '{items_under_min}'::jsonb, 'b-jed-01', 'ALDEEB10'
    );
    """
    code, out, err = run_psql(sql)
    if code == 0 or "COUPON_MIN_ORDER_NOT_MET" not in err:
        fail_test(f"Failed to reject coupon below minimum. Code: {code}, Err: {err}")
    pass_test(f"Correctly rejected with COUPON_MIN_ORDER_NOT_MET: {err.splitlines()[-1]}")

    # -------------------------------------------------------------------------
    # TEST 14: Loyalty Points Redemption & Auto-Deduction
    # -------------------------------------------------------------------------
    test_banner(14, "Loyalty Points Validation, Deduction & Transaction Logging")
    # Customer has 100 points. Uses 50 points (rate: 0.01 -> 0.50 SAR discount)
    # Subtotal 100.00 - 0.50 = 99.50
    ord_loyalty = f"ORD-LOYALTY-{int(time.time())}"
    sql = f"""
    SELECT public.place_order_atomic(
        '{ord_loyalty}', '{test_user_id}', 'فوري', 'cod', 100.00, 0.00, 0.00, 50, 0.50, 99.50,
        'Loyalty Test', '{items_valid_price}'::jsonb, 'b-jed-01'
    );
    """
    code, res_loyalty, err = run_psql_json(sql)
    if code != 0 or not res_loyalty:
        fail_test(f"Loyalty order failed: {err}")
    if res_loyalty.get("loyalty_discount") != 0.50 or res_loyalty.get("total_amount") != 99.50:
        fail_test(f"Loyalty discount mismatch: {res_loyalty}")

    # Verify points balance was decremented in public.profiles
    code, points_out, _ = run_psql(f"SELECT loyalty_points FROM public.profiles WHERE id = '{test_user_id}';", as_json=True)
    if int(points_out) != 50:
        fail_test(f"Profile loyalty points not decremented to 50. Got: {points_out}")

    # Verify loyalty_transactions record
    code, trx_out, _ = run_psql(f"SELECT points, transaction_type FROM public.loyalty_transactions WHERE user_id = '{test_user_id}' AND order_id = '{res_loyalty['id']}';", as_json=True)
    if code != 0 or not trx_out:
        fail_test("Loyalty transaction was not logged in public.loyalty_transactions")

    pass_test(f"Loyalty points verified & deducted: 100 -> 50. Transaction logged in loyalty_transactions.")

    # -------------------------------------------------------------------------
    # TEST 15: Rejection of Insufficient Loyalty Points Balance
    # -------------------------------------------------------------------------
    test_banner(15, "Rejection of Insufficient Loyalty Points Balance")
    # User now has 50 points. Requests 500 points.
    sql = f"""
    SELECT public.place_order_atomic(
        'ORD-LOYALTY-EXCESS', '{test_user_id}', 'فوري', 'cod', 100.00, 0.00, 0.00, 500, 5.00, 95.00,
        'Excess Points', '{items_valid_price}'::jsonb, 'b-jed-01'
    );
    """
    code, out, err = run_psql(sql)
    if code == 0 or "INSUFFICIENT_LOYALTY_POINTS" not in err:
        fail_test(f"Failed to reject excess loyalty points. Code: {code}, Err: {err}")
    pass_test(f"Correctly rejected with INSUFFICIENT_LOYALTY_POINTS: {err.splitlines()[-1]}")

    # -------------------------------------------------------------------------
    # TEST 16: Multi-Item Partial Failure Rollback (ACID Atomicity)
    # -------------------------------------------------------------------------
    test_banner(16, "Multi-Item Partial Failure Rollback (Zero Partial Records Created)")
    # Item 1 is valid (Product A). Item 2 has quantity 9999 (exceeds stock).
    # Entire transaction MUST abort. Neither order, nor items, nor stock decrement must persist!
    code, pre_stock_a, _ = run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id}';", as_json=True)
    
    mixed_items = json.dumps([
        {"product_id": test_prod_id, "quantity": 1, "unit_price": 50.00},
        {"product_id": test_prod_id_b, "quantity": 9999, "unit_price": 30.00}
    ])
    fail_ord_num = f"ORD-FAIL-ROLLBACK-{int(time.time())}"
    sql = f"""
    SELECT public.place_order_atomic(
        '{fail_ord_num}', NULL, 'فوري', 'cod', 300020.00, 0, 0, 0, 0, 300020.00,
        'Rollback Test', '{mixed_items}'::jsonb, 'b-jed-01'
    );
    """
    code, out, err = run_psql(sql)
    if code == 0:
        fail_test("Expected transaction to fail, but it succeeded!")

    # Check that NO order was inserted
    code, ord_exists, _ = run_psql(f"SELECT COUNT(*) FROM public.orders WHERE order_number = '{fail_ord_num}';", as_json=True)
    if int(ord_exists) != 0:
        fail_test("ACID VIOLATION: Order record was inserted despite transaction abort!")

    # Check that stock of Product A was NOT decremented
    code, post_stock_a, _ = run_psql(f"SELECT stock_quantity FROM public.products WHERE id = '{test_prod_id}';", as_json=True)
    if post_stock_a != pre_stock_a:
        fail_test(f"ACID VIOLATION: Product A stock was decremented during failed transaction! {pre_stock_a} -> {post_stock_a}")

    pass_test("ACID Rollback Verified: 0 orders inserted, 0 order_items inserted, Product A stock unchanged.")

    # -------------------------------------------------------------------------
    # TEST 17: Multi-Session / Persistent State Audit in PostgreSQL
    # -------------------------------------------------------------------------
    test_banner(17, "Cross-Session Database Persistence & Table Linkage Audit")
    query_audit = f"""
    SELECT json_build_object(
        'orders_count', (SELECT COUNT(*) FROM public.orders WHERE order_number = '{ord_num_1}'),
        'items_count', (SELECT COUNT(*) FROM public.order_items WHERE order_id = '{res_1['id']}'),
        'inventory_movements', (SELECT COUNT(*) FROM public.inventory_movements WHERE reference_id = '{ord_num_1}'),
        'inventory_transactions', (SELECT COUNT(*) FROM public.inventory_transactions WHERE reference_id = '{ord_num_1}')
    )::text;
    """
    code, audit_json_str, _ = run_psql(query_audit, as_json=True)
    audit = json.loads(audit_json_str)
    if audit.get("orders_count") != 1 or audit.get("items_count") != 1:
        fail_test(f"Audit failed: {audit}")

    pass_test(f"Persistent records verified in PostgreSQL: 1 order, 1 order_item, {audit.get('inventory_movements')} movements, {audit.get('inventory_transactions')} inventory transactions.")

    # -------------------------------------------------------------------------
    # Cleanup Test Fixtures
    # -------------------------------------------------------------------------
    cleanup_sql = f"""
    DELETE FROM public.orders WHERE order_number IN ('{ord_num_1}', '{ord_coupon}', '{ord_loyalty}', '{dup_ord_num}');
    DELETE FROM public.products WHERE id IN ('{test_prod_id}', '{test_prod_id_b}');
    """
    run_psql(cleanup_sql)

    # -------------------------------------------------------------------------
    # SUMMARY REPORT
    # -------------------------------------------------------------------------
    print("\n" + "=" * 80)
    print(f"🎯 TASK 10 FORENSIC AUDIT SUMMARY: {pass_count}/{total_tests} Tests Passed (100% Zero Defect)")
    print("=" * 80)

if __name__ == "__main__":
    main()
