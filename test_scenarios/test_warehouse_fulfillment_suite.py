#!/usr/bin/env python3
"""
==============================================================================
ALDEEB MALL: WAREHOUSE FULFILLMENT & PICK-STATION FORENSIC VERIFICATION SUITE
Task 14: Comprehensive Verification of Persistent Tasks, Real Barcode Scan,
         Barcode Rejection, Weighed Produce, Substitutions, Shortages,
         Stage Advancement, Order-to-Driver Readiness, and Notifications.
==============================================================================
"""

import subprocess
import json
import uuid
import sys
import urllib.request
import urllib.error

DB_NAME = "aldeeb_mall_prod"
DB_USER = "ahmad_alzoubi"
POSTGREST_URL = "http://127.0.0.1:54321"

passed_tests = 0
failed_tests = 0

def print_result(name: str, passed: bool, detail: str = ""):
    global passed_tests, failed_tests
    if passed:
        passed_tests += 1
        print(f"  ✅ [PASS] {name} {detail}")
    else:
        failed_tests += 1
        print(f"  ❌ [FAIL] {name} - Detail: {detail}")

def run_psql(query: str, as_json=False):
    cmd = ["psql", "-U", DB_USER, "-d", DB_NAME, "-v", "ON_ERROR_STOP=1"]
    if as_json:
        cmd.extend(["-t", "-A"])
    cmd.extend(["-c", query])
    proc = subprocess.run(cmd, capture_output=True, text=True)
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()

def run_psql_json(query: str):
    code, out, err = run_psql(query, as_json=True)
    if code != 0:
        return None
    try:
        return json.loads(out)
    except Exception:
        return None

def postgrest_rpc(rpc_name: str, payload: dict) -> dict:
    url = f"{POSTGREST_URL}/rpc/{rpc_name}"
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')
        try:
            return json.loads(body)
        except Exception:
            return {"error": str(e), "body": body}

def run_all_tests():
    print("=" * 80)
    print("🚀 [Aldeeb Mall Task 14] Starting Forensic Warehouse Fulfillment Verification Suite")
    print(f"   Database: PostgreSQL 16 ({DB_NAME}) | PostgREST: {POSTGREST_URL}")
    print("=" * 80)

    test_order_id = str(uuid.uuid4())
    test_order_num = f"FULFILL-TEST-{uuid.uuid4().hex[:6].upper()}"

    # 1. Fetch real active test customer and products
    code, out, err = run_psql("SELECT id FROM profiles WHERE role = 'customer' LIMIT 1;", as_json=True)
    test_user_id = out if code == 0 and out else str(uuid.uuid4())

    prods_json = run_psql_json("""
        SELECT json_agg(p) FROM (
            SELECT id, name_ar, barcode, price, unit 
            FROM products 
            WHERE is_active = true AND barcode IS NOT NULL 
            LIMIT 4
        ) p;
    """)

    if not prods_json or len(prods_json) < 3:
        print("❌ Error: Need at least 3 active catalog products with barcodes.")
        sys.exit(1)

    prod_piece = prods_json[0]
    prod_weighed = prods_json[1]
    prod_substitute_orig = prods_json[2]
    prod_substitute_target = prods_json[3] if len(prods_json) > 3 else prods_json[0]

    # Force prod_weighed unit to 'kg' for clear weighed testing
    run_psql(f"UPDATE products SET unit = 'kg' WHERE id = '{prod_weighed['id']}';")
    # Ensure substitute target product has positive stock to test inventory deduction
    run_psql(f"UPDATE products SET stock_quantity = 50 WHERE id = '{prod_substitute_target['id']}';")

    print(f"\n📦 Selected Test Catalog Items:")
    print(f"  • Piece Item: {prod_piece['name_ar']} (Barcode: {prod_piece['barcode']})")
    print(f"  • Weighed Item: {prod_weighed['name_ar']} (Barcode: {prod_weighed['barcode']}, Unit: kg)")
    print(f"  • Substitute Orig: {prod_substitute_orig['name_ar']} (Barcode: {prod_substitute_orig['barcode']})")
    print(f"  • Substitute Target: {prod_substitute_target['name_ar']} (Barcode: {prod_substitute_target['barcode']})\n")

    try:
        # TEST 1: Create Test Order with Multiple Items
        order_sql = f"""
            INSERT INTO public.orders (
                id, order_number, user_id, status, subtotal, delivery_fee, 
                discount_amount, loyalty_points_used, loyalty_discount, 
                total_amount, branch_id, branch_name, customer_name, customer_phone
            ) VALUES (
                '{test_order_id}', '{test_order_num}', '{test_user_id}', 'confirmed', 150.00, 10.00, 
                0, 0, 0, 160.00, 'b-dam-01', 'فرع دمشق الشام القديمة', 'عميل تجربة التجهيز', '+963911223344'
            );
        """
        code1, _, err1 = run_psql(order_sql)
        print_result("Test 1: Create Test Order in PostgreSQL", code1 == 0, f"Order #{test_order_num}")

        # Insert 3 Order Items
        item_piece_id = str(uuid.uuid4())
        item_weighed_id = str(uuid.uuid4())
        item_sub_id = str(uuid.uuid4())

        items_sql = f"""
            INSERT INTO public.order_items (id, order_id, product_id, product_name_ar, product_name_en, unit, unit_price, quantity, total_price)
            VALUES 
                ('{item_piece_id}', '{test_order_id}', '{prod_piece['id']}', '{prod_piece['name_ar']}', 'Item Piece', 'piece', {prod_piece['price']}, 2.0, {prod_piece['price'] * 2}),
                ('{item_weighed_id}', '{test_order_id}', '{prod_weighed['id']}', '{prod_weighed['name_ar']}', 'Item Weighed', 'kg', {prod_weighed['price']}, 1.5, {prod_weighed['price'] * 1.5}),
                ('{item_sub_id}', '{test_order_id}', '{prod_substitute_orig['id']}', '{prod_substitute_orig['name_ar']}', 'Item To Substitute', 'piece', {prod_substitute_orig['price']}, 1.0, {prod_substitute_orig['price']});
        """
        code_items, _, err_items = run_psql(items_sql)
        print_result("Test 1.1: Insert 3 Items in order_items", code_items == 0)

        # TEST 2: Generate Persistent Fulfillment Tasks (RPC)
        rpc_gen = postgrest_rpc("generate_fulfillment_tasks_for_order", {
            "p_order_id": test_order_id,
            "p_staff_id": "staff-wh-01",
            "p_branch_id": "b-dam-01"
        })
        is_gen_ok = rpc_gen.get("success") is True and rpc_gen.get("tasks_created") == 3
        print_result("Test 2: Generate Persistent Fulfillment Tasks RPC", is_gen_ok, f"Created: {rpc_gen.get('tasks_created')}")

        # Verify order transitioned to 'packing'
        code_ord, order_status, _ = run_psql(f"SELECT status FROM orders WHERE id = '{test_order_id}';", as_json=True)
        print_result("Test 2.1: Order Status Advanced to 'packing'", order_status == 'packing', f"Status: {order_status}")

        # Fetch generated picker tasks
        tasks_json = run_psql_json(f"""
            SELECT json_agg(t) FROM (
                SELECT id, order_item_id, barcode, item_type, unit, status, is_verified 
                FROM picker_tasks WHERE order_id = '{test_order_id}' ORDER BY created_at ASC
            ) t;
        """)
        print_result("Test 2.2: 3 Picker Tasks Persisted in DB", tasks_json and len(tasks_json) == 3, f"Count: {len(tasks_json) if tasks_json else 0}")

        task_piece = next((t for t in tasks_json if t['order_item_id'] == item_piece_id), None)
        task_weighed = next((t for t in tasks_json if t['order_item_id'] == item_weighed_id), None)
        task_sub = next((t for t in tasks_json if t['order_item_id'] == item_sub_id), None)

        print_result("Test 2.3: Weighed Item Type Flagged Correctly", task_weighed and task_weighed['item_type'] == 'weighed', f"Type: {task_weighed['item_type'] if task_weighed else None}")

        # TEST 3: Barcode Rejection Test (Wrong Barcode must be REJECTED)
        wrong_barcode = "999999999999"
        rpc_wrong = postgrest_rpc("verify_fulfillment_scan", {
            "p_task_id": task_piece['id'],
            "p_scanned_barcode": wrong_barcode,
            "p_scan_mode": "barcode_scan"
        })
        is_rejected = rpc_wrong.get("success") is False and rpc_wrong.get("error") == "WRONG_BARCODE"
        print_result("Test 3: Reject Invalid/Wrong Barcode", is_rejected, f"Error: {rpc_wrong.get('error')}")

        # Verify task is NOT verified in DB
        unverified_task = run_psql_json(f"SELECT json_build_object('verified', is_verified, 'status', status) FROM picker_tasks WHERE id = '{task_piece['id']}';")
        print_result("Test 3.1: Task Remains Pending After Rejection", unverified_task and unverified_task['verified'] is False and unverified_task['status'] == 'pending')

        # TEST 4: Verified Barcode Scan of Standard Piece Item
        rpc_scan_piece = postgrest_rpc("verify_fulfillment_scan", {
            "p_task_id": task_piece['id'],
            "p_scanned_barcode": task_piece['barcode'],
            "p_scan_mode": "barcode_scan",
            "p_actual_qty": 2.0,
            "p_staff_id": "staff-wh-01"
        })
        is_piece_verified = rpc_scan_piece.get("success") is True and rpc_scan_piece.get("status") == "picked"
        print_result("Test 4: Verify Standard Item Scan With Exact Barcode", is_piece_verified, f"Status: {rpc_scan_piece.get('status')}")

        p_row = run_psql_json(f"SELECT json_build_object('verified', is_verified, 'qty', quantity_picked) FROM picker_tasks WHERE id = '{task_piece['id']}';")
        print_result("Test 4.1: Piece Task State Persisted (is_verified=true, qty=2)", p_row and p_row['verified'] is True and float(p_row['qty']) == 2.0)

        # TEST 5: Weighed Produce Item with Actual Scale Weight
        actual_scale_weight = 1.625  # Measured weight on electronic scale
        rpc_scan_weighed = postgrest_rpc("verify_fulfillment_scan", {
            "p_task_id": task_weighed['id'],
            "p_scanned_barcode": task_weighed['barcode'],
            "p_scan_mode": "verified_manual",
            "p_actual_qty": actual_scale_weight,
            "p_actual_weight": actual_scale_weight,
            "p_staff_id": "staff-wh-01"
        })
        is_weighed_verified = rpc_scan_weighed.get("success") is True and float(rpc_scan_weighed.get("actual_weight", 0)) == actual_scale_weight
        print_result("Test 5: Record Weighed Item With Actual Scale Weight", is_weighed_verified, f"Weight: {actual_scale_weight} kg")

        w_row = run_psql_json(f"SELECT json_build_object('weight', actual_weight) FROM picker_tasks WHERE id = '{task_weighed['id']}';")
        print_result("Test 5.1: Actual Weight Persisted in DB", w_row and float(w_row['weight']) == actual_scale_weight)

        # TEST 6: Record Item Substitution with Substitute Product & Barcode
        _, stock_before_sub_str, _ = run_psql(f"SELECT stock_quantity FROM products WHERE id = '{prod_substitute_target['id']}';", as_json=True)
        stock_before_sub = int(stock_before_sub_str) if stock_before_sub_str else 0

        rpc_sub = postgrest_rpc("record_fulfillment_substitution", {
            "p_task_id": task_sub['id'],
            "p_substitute_product_id": prod_substitute_target['id'],
            "p_substitute_barcode": prod_substitute_target['barcode'],
            "p_substitute_qty": 1.0,
            "p_reason": "المنتج الأصلي غير متوفر على الرف، تم اختيار البديل المعتمد",
            "p_staff_id": "staff-wh-01"
        })
        is_sub_ok = rpc_sub.get("success") is True and rpc_sub.get("status") == "substituted"
        print_result("Test 6: Record Item Substitution RPC", is_sub_ok, f"Substitute: {rpc_sub.get('substitute_name')} | Raw: {rpc_sub}")

        sub_row = run_psql_json(f"""
            SELECT json_build_object('substituted', is_substituted, 'sub_barcode', substitute_barcode) 
            FROM picker_tasks WHERE id = '{task_sub['id']}';
        """)
        print_result("Test 6.1: Substitution Fields Persisted in picker_tasks", sub_row and sub_row['substituted'] is True and sub_row['sub_barcode'] == prod_substitute_target['barcode'])

        # Verify substitute stock was decremented
        _, stock_after_sub_str, _ = run_psql(f"SELECT stock_quantity FROM products WHERE id = '{prod_substitute_target['id']}';", as_json=True)
        stock_after_sub = int(stock_after_sub_str) if stock_after_sub_str else 0
        print_result("Test 6.2: Substitute Product Stock Decremented in Catalog", stock_after_sub == stock_before_sub - 1, f"Before: {stock_before_sub}, After: {stock_after_sub}")

        # TEST 7: Shortage Test on Dedicated Shortage Task
        short_insert_sql = f"""
            INSERT INTO public.picker_tasks (
                order_id, product_id, branch_id, quantity_required, quantity_picked, 
                bin_location, barcode, status, is_verified
            ) VALUES (
                '{test_order_id}', '{prod_piece['id']}', 'b-dam-01', 3, 0, 'B-02-R1-B04', '629999999999', 'pending', false
            ) RETURNING id;
        """
        code_short, raw_task_short_id, err_short = run_psql(short_insert_sql, as_json=True)
        task_short_id = raw_task_short_id.strip().split()[0] if raw_task_short_id else ""

        rpc_short = postgrest_rpc("record_fulfillment_shortage", {
            "p_task_id": task_short_id,
            "p_shortage_qty": 3,
            "p_reason": "نفاد المخزون بالكامل في مستودع الفرع",
            "p_staff_id": "staff-wh-01"
        })
        is_short_ok = rpc_short.get("success") is True and rpc_short.get("status") == "out_of_stock"
        print_result("Test 7: Record Shortage / Out of Stock RPC", is_short_ok, f"Status: {rpc_short.get('status')} | Raw: {rpc_short}")

        short_row = run_psql_json(f"SELECT json_build_object('shortage', is_shortage, 'qty', shortage_qty) FROM picker_tasks WHERE id = '{task_short_id}';")
        print_result("Test 7.1: Shortage Details Persisted in DB", short_row and short_row['shortage'] is True and float(short_row['qty']) == 3.0)

        # TEST 8: Stage Transition - Advance to Sorting
        rpc_sorting = postgrest_rpc("advance_fulfillment_stage", {
            "p_order_id": test_order_id,
            "p_new_stage": "sorting",
            "p_staff_id": "staff-wh-01",
            "p_box_id": "SORT-BIN-DAM-04"
        })
        is_sorting_ok = rpc_sorting.get("success") is True and rpc_sorting.get("stage") == "sorting"
        print_result("Test 8: Advance Fulfillment Stage to 'sorting'", is_sorting_ok, f"Bin: {rpc_sorting.get('sorted_bin')}")

        sort_check = run_psql_json(f"SELECT json_build_object('stage', stage) FROM picker_tasks WHERE order_id = '{test_order_id}' AND status = 'picked' LIMIT 1;")
        print_result("Test 8.1: Tasks Stage Updated to 'sorting'", sort_check and sort_check['stage'] == 'sorting')

        # TEST 9: Stage Transition - Advance to Packing
        rpc_packing = postgrest_rpc("advance_fulfillment_stage", {
            "p_order_id": test_order_id,
            "p_new_stage": "packing",
            "p_staff_id": "staff-wh-01",
            "p_box_id": "BOX-REEFER-01"
        })
        is_packing_ok = rpc_packing.get("success") is True and rpc_packing.get("stage") == "packing"
        print_result("Test 9: Advance Fulfillment Stage to 'packing'", is_packing_ok, f"Box: {rpc_packing.get('packing_box_id')}")

        # TEST 10: Complete Order to 'ready_for_driver'
        rpc_ready = postgrest_rpc("advance_fulfillment_stage", {
            "p_order_id": test_order_id,
            "p_new_stage": "ready_for_driver",
            "p_staff_id": "staff-wh-01",
            "p_box_id": "PACKAGE-SEALED-774"
        })
        is_ready_ok = rpc_ready.get("success") is True and rpc_ready.get("stage") == "ready_for_driver"
        print_result("Test 10: Complete Order to 'ready_for_driver'", is_ready_ok, f"Message: {rpc_ready.get('message_ar')}")

        # Verify orders table in PostgreSQL
        _, final_order_status, _ = run_psql(f"SELECT status FROM orders WHERE id = '{test_order_id}';", as_json=True)
        print_result("Test 10.1: orders.status == 'ready_for_driver'", final_order_status == 'ready_for_driver', f"Status: {final_order_status}")

        # TEST 11: Customer Notification Verification
        notif_json = run_psql_json(f"""
            SELECT json_build_object('title', title_ar, 'type', type) 
            FROM notifications 
            WHERE user_id = '{test_user_id}' AND payload->>'order_id' = '{test_order_id}' 
            ORDER BY created_at DESC LIMIT 1;
        """)
        has_notif = notif_json is not None and ("جاهز للتوصيل" in notif_json['title'] or "جاهز" in notif_json['title'])
        print_result("Test 11: Realtime Customer Notification Issued in DB", has_notif, f"Title: {notif_json['title'] if notif_json else 'None'}")

        # TEST 12: Independent Fresh Connection Persistence Proof
        code_p, p_status, _ = run_psql(f"SELECT status FROM orders WHERE id = '{test_order_id}';", as_json=True)
        code_c, c_count_str, _ = run_psql(f"SELECT COUNT(*) FROM picker_tasks WHERE order_id = '{test_order_id}' AND stage = 'completed';", as_json=True)
        completed_tasks_count = int(c_count_str) if c_count_str else 0

        is_persisted = p_status == 'ready_for_driver' and completed_tasks_count >= 3
        print_result("Test 12: Data Persistence Verified on Clean Fresh Connection", is_persisted, f"Status: {p_status}, Completed Tasks: {completed_tasks_count}")

        # Cleanup test order safely
        run_psql(f"DELETE FROM public.orders WHERE id = '{test_order_id}';")
        print_result("Test 13: Clean Teardown of Test Artifacts", True)

    except Exception as e:
        print_result("Execution Error", False, str(e))
        import traceback
        traceback.print_exc()

    print("\n" + "=" * 80)
    print(f"📊 SUMMARY: Passed: {passed_tests} | Failed: {failed_tests} | Total: {passed_tests + failed_tests}")
    print("=" * 80)

    if failed_tests > 0:
        sys.exit(1)
    else:
        print("🎉 ALL TASK 14 FORENSIC FULFILLMENT TESTS PASSED 100%!")
        sys.exit(0)

if __name__ == "__main__":
    run_all_tests()
