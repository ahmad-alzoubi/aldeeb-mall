#!/usr/bin/env python3
"""
==============================================================================
Test Suite: Task 13 - Authoritative Order Management, State Machine & Audit Ledger
==============================================================================
Forensic assertions for:
 1. Customer atomic order placement (place_order_atomic) & initial state
 2. Authorized state machine workflow (pending -> confirmed -> packing -> assigned -> out_for_delivery -> delivered)
 3. Status history / audit ledger timeline integrity
 4. Strict rejection of invalid transitions (e.g. pending -> delivered)
 5. Terminal state protection (delivered / cancelled immutable against invalid changes)
 6. Mandatory reason enforcement for cancellation & failure (REASON_REQUIRED)
 7. Atomic stock restoration on cancellation & delivery failure (zero duplicate restoration)
 8. Optimistic concurrency conflict detection (CONCURRENT_MODIFICATION_CONFLICT)
 9. Multi-branch isolation & RBAC authorization enforcement
 10. Persistence across sessions / simulated cross-device reopen
==============================================================================
"""

import sys
import json
import uuid
import time
import subprocess

DB_NAME = "aldeeb_mall_prod"
DB_USER = "postgres"

pass_count = 0
total_tests = 0

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

def log_test(name, success, details=""):
    global total_tests, pass_count
    total_tests += 1
    mark = "✅ PASS" if success else "❌ FAIL"
    print(f"{mark} | {name}")
    if details:
        print(f"       Details: {details}")
    if success:
        pass_count += 1
    else:
        sys.exit(1)

def create_test_order(order_number, prod_id, quantity, unit_price, branch_id="b-jed-01", customer_name="عميل اختبار", customer_phone="+963911223344", notes="ملاحظات تجريبية"):
    subtotal = float(quantity) * float(unit_price)
    delivery_fee = 0.0
    discount = 0.0
    loyalty_points = 0
    loyalty_discount = 0.0
    total = subtotal + delivery_fee - discount - loyalty_discount
    items = json.dumps([{"product_id": prod_id, "quantity": quantity, "unit_price": unit_price}])

    query = f"""
    SELECT public.place_order_atomic(
        '{order_number}',
        NULL,
        'توصيل فوري خلال 45 دقيقة',
        'cod',
        {subtotal:.2f},
        {delivery_fee:.2f},
        {discount:.2f},
        {loyalty_points},
        {loyalty_discount:.2f},
        {total:.2f},
        '{notes}',
        '{items}'::jsonb,
        '{branch_id}',
        NULL,
        'IDEMP-{order_number}',
        '{customer_name}',
        '{customer_phone}'
    );
    """
    return run_psql_json(query)

def run_suite():
    print("==============================================================================")
    print("🚀 Running Task 13 Order Management Forensic Verification Suite")
    print("==============================================================================")

    test_run_id = f"T13_{int(time.time())}_{uuid.uuid4().hex[:4]}"

    # 0. Setup: Ensure an active product with known stock exists in both catalog and branch_inventory
    code, prod, err = run_psql_json("""
        SELECT jsonb_build_object('id', p.id, 'name_ar', p.name_ar, 'price', p.price, 'stock_quantity', p.stock_quantity)
        FROM public.products p
        JOIN public.branch_inventory bi ON bi.product_id = p.id AND bi.branch_id = 'b-jed-01'
        WHERE p.is_active = true AND p.stock_quantity >= 50 AND bi.quantity_on_hand >= 50
        LIMIT 1;
    """)
    if not prod:
        code, prod, err = run_psql_json("""
            WITH new_prod AS (
                INSERT INTO public.products (id, name_ar, name_en, price, stock_quantity, is_active, category_id)
                VALUES (gen_random_uuid(), 'أرز سيلا كلاسيك تجريبي', 'Test Sella Rice', 45.00, 100, true, 'cat-food-staples')
                RETURNING id, name_ar, price, stock_quantity
            )
            INSERT INTO public.branch_inventory (branch_id, product_id, quantity_on_hand, quantity_reserved)
            SELECT 'b-jed-01', id, 100, 0 FROM new_prod
            RETURNING jsonb_build_object('id', product_id, 'name_ar', 'أرز سيلا كلاسيك تجريبي', 'price', 45.00, 'stock_quantity', 100);
        """)

    prod_id = str(prod['id'])
    prod_price = float(prod['price'])
    initial_stock = int(prod['stock_quantity'])
    print(f"📦 Target Test Product: {prod['name_ar']} (ID: {prod_id}) - Price: {prod_price} - Initial Stock: {initial_stock}")

    # Ensure courier exists
    code, courier, err = run_psql_json("""
        SELECT jsonb_build_object('id', id, 'full_name', full_name, 'phone', phone)
        FROM public.couriers WHERE is_active = true LIMIT 1;
    """)
    if not courier:
        code, courier, err = run_psql_json("""
            INSERT INTO public.couriers (id, full_name, phone, vehicle_type, is_active, is_online)
            VALUES (gen_random_uuid(), 'سالم كابتن التوصيل السريع', '+963987654321', 'motorbike', true, true)
            RETURNING jsonb_build_object('id', id, 'full_name', full_name, 'phone', phone);
        """)
    courier_id = str(courier['id'])
    courier_name = courier['full_name']
    courier_phone = courier['phone']

    # --------------------------------------------------------------------------
    # SCENARIO 1: Customer Atomic Order Placement -> Admin Visibility
    # --------------------------------------------------------------------------
    order_num_1 = f"ORD-{test_run_id}-01"
    code, res1, err = create_test_order(order_num_1, prod_id, 3, prod_price, "b-jed-01", "سامر زريق", "+963911223344", "توصيل شقة 4")
    assert res1 and 'id' in res1, f"Failed placing order 1: {err}"
    order_1_id = res1['id']

    # Verify order is in pending, version = 1, and stock is decremented
    code, o1, err = run_psql_json(f"SELECT jsonb_build_object('status', status, 'version', version, 'is_stock_restored', is_stock_restored) FROM public.orders WHERE id = '{order_1_id}';")
    code, stock_res, err = run_psql_json(f"SELECT jsonb_build_object('stock', stock_quantity) FROM public.products WHERE id = '{prod_id}';")
    stock_after_order1 = int(stock_res['stock'])

    scenario_1_pass = (
        o1['status'] == 'pending' and
        o1['version'] == 1 and
        o1['is_stock_restored'] is False and
        stock_after_order1 == (initial_stock - 3)
    )
    log_test("SCN-01: Customer place_order_atomic creates pending order with version=1 and decrements stock",
             scenario_1_pass, f"Status: {o1['status']}, Version: {o1['version']}, Stock: {stock_after_order1}")

    # --------------------------------------------------------------------------
    # SCENARIO 2: State Machine Lifecycle (pending -> confirmed -> packing -> assigned -> out_for_delivery -> delivered)
    # --------------------------------------------------------------------------
    # Step A: pending -> confirmed (Super Admin confirms)
    code, r_confirm, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_1_id}',
            p_new_status => 'confirmed',
            p_expected_version => 1,
            p_staff_name => 'أحمد المدير العام',
            p_staff_role => 'super_admin',
            p_notes => 'تم التحقق من جاهزية الفرع والاتصال بالعميل'
        );
    """)
    code, stock_res2, err = run_psql_json(f"SELECT jsonb_build_object('stock', stock_quantity) FROM public.products WHERE id = '{prod_id}';")
    stock_after_confirm = int(stock_res2['stock'])
    no_double_decrement = (stock_after_confirm == stock_after_order1)

    log_test("SCN-02A: Transition pending -> confirmed preserves stock without double-decrement",
             r_confirm and r_confirm.get('success') and r_confirm.get('version') == 2 and no_double_decrement,
             f"New Version: {r_confirm.get('version') if r_confirm else None}, Stock: {stock_after_confirm}")

    # Step B: confirmed -> packing (Warehouse Manager starts picking)
    code, r_pack, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_1_id}',
            p_new_status => 'packing',
            p_expected_version => 2,
            p_staff_name => 'خالد مسؤول المستودع',
            p_staff_role => 'warehouse_manager',
            p_notes => 'بدء تجميع الأصناف من الرفوف B-12'
        );
    """)
    log_test("SCN-02B: Transition confirmed -> packing increments version to 3",
             r_pack and r_pack.get('success') and r_pack.get('version') == 3, f"Version: {r_pack.get('version') if r_pack else None}")

    # Step C: packing -> assigned (Assign Courier)
    code, r_assign, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_1_id}',
            p_new_status => 'assigned',
            p_expected_version => 3,
            p_courier_id => '{courier_id}',
            p_courier_name => '{courier_name}',
            p_courier_phone => '{courier_phone}',
            p_staff_name => 'مسؤول الإرسال اللوجستي',
            p_staff_role => 'super_admin',
            p_notes => 'تم تعيين الكابتن وسينطلق بعد الاستلام'
        );
    """)
    code, disp_assign, err = run_psql_json(f"""
        SELECT jsonb_build_object('courier_id', courier_id, 'status', status)
        FROM public.courier_dispatches WHERE order_id = '{order_1_id}';
    """)
    log_test("SCN-02C: Transition packing -> assigned links courier and creates courier dispatch",
             r_assign and r_assign.get('success') and r_assign.get('version') == 4 and disp_assign is not None and str(disp_assign['courier_id']) == courier_id,
             f"Dispatch Status: {disp_assign.get('status') if disp_assign else 'None'}")

    # Step D: assigned -> out_for_delivery (Driver picks up goods)
    code, r_out, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_1_id}',
            p_new_status => 'out_for_delivery',
            p_expected_version => 4,
            p_staff_name => '{courier_name}',
            p_staff_role => 'courier',
            p_notes => 'تم استلام الشحنة من الفرع وجاري التوجه للعميل'
        );
    """)
    log_test("SCN-02D: Transition assigned -> out_for_delivery increments version to 5",
             r_out and r_out.get('success') and r_out.get('version') == 5, f"Version: {r_out.get('version') if r_out else None}")

    # Step E: out_for_delivery -> delivered (Successful handover)
    code, r_deliv, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_1_id}',
            p_new_status => 'delivered',
            p_expected_version => 5,
            p_staff_name => '{courier_name}',
            p_staff_role => 'courier',
            p_notes => 'تم تسليم الطلب للعميل واستلام المبلغ نقداً'
        );
    """)
    code, o1_final, err = run_psql_json(f"""
        SELECT jsonb_build_object('status', status, 'delivered_at', delivered_at, 'payment_status', payment_status)
        FROM public.orders WHERE id = '{order_1_id}';
    """)
    scenario_2e_pass = (
        r_deliv and r_deliv.get('success') and
        o1_final['status'] == 'delivered' and
        o1_final['delivered_at'] is not None and
        o1_final['payment_status'] == 'paid'
    )
    log_test("SCN-02E: Transition out_for_delivery -> delivered marks order delivered and paid",
             scenario_2e_pass, f"Delivered At: {o1_final.get('delivered_at')}, Payment: {o1_final.get('payment_status')}")

    # --------------------------------------------------------------------------
    # SCENARIO 3: Timeline & Status History Verification
    # --------------------------------------------------------------------------
    code, timeline_res, err = run_psql_json(f"""
        SELECT jsonb_agg(jsonb_build_object('from_status', from_status, 'to_status', to_status) ORDER BY created_at ASC)
        FROM public.order_status_history
        WHERE order_id = '{order_1_id}';
    """)
    timeline = timeline_res or []
    transitions_sequence = [(t.get('from_status'), t.get('to_status')) for t in timeline]
    expected_transitions = [
        (None, 'pending'),
        ('pending', 'confirmed'),
        ('confirmed', 'packing'),
        ('packing', 'assigned'),
        ('assigned', 'out_for_delivery'),
        ('out_for_delivery', 'delivered')
    ]
    timeline_valid = (transitions_sequence == expected_transitions)
    log_test("SCN-03: Order status history records exact 6-stage chronological audit timeline",
             timeline_valid, f"Recorded transitions: {transitions_sequence}")

    # --------------------------------------------------------------------------
    # SCENARIO 4: Strict Rejection of Invalid Transitions
    # --------------------------------------------------------------------------
    # A. Cannot transition delivered order to pending
    code, _, err = run_psql(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_1_id}',
            p_new_status => 'pending',
            p_staff_name => 'متسلل'
        );
    """)
    delivered_reopen_prevented = (code != 0 and ("INVALID_TRANSITION" in err or "already delivered" in err))
    log_test("SCN-04A: Terminal delivered order rejects reopening or reverting to pending",
             delivered_reopen_prevented, f"Error: {err.splitlines()[-1] if err else 'None'}")

    # B. Cannot jump pending order directly to delivered
    order_num_invalid = f"ORD-{test_run_id}-INV"
    code, res_inv, err = create_test_order(order_num_invalid, prod_id, 1, prod_price, "b-jed-01", "عميل اختبار قفز")
    order_inv_id = res_inv['id']

    code, _, err = run_psql(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_inv_id}',
            p_new_status => 'delivered',
            p_staff_name => 'كاشير'
        );
    """)
    jump_prevented = (code != 0 and "INVALID_TRANSITION" in err)
    log_test("SCN-04B: Illegal transition jumping directly from pending to delivered is blocked",
             jump_prevented, f"Error: {err.splitlines()[-1] if err else 'None'}")

    # --------------------------------------------------------------------------
    # SCENARIO 5: Order Cancellation with Mandatory Reason & Stock Restoration
    # --------------------------------------------------------------------------
    code, stock_before_c, err = run_psql_json(f"SELECT jsonb_build_object('stock', stock_quantity) FROM public.products WHERE id = '{prod_id}';")
    stock_before_cancel_test = int(stock_before_c['stock'])

    order_num_cancel = f"ORD-{test_run_id}-CAN"
    code, res_c, err = create_test_order(order_num_cancel, prod_id, 5, prod_price, "b-jed-01", "عميل إلغاء مع استرجاع مخزون")
    order_cancel_id = res_c['id']

    code, stock_during, err = run_psql_json(f"SELECT jsonb_build_object('stock', stock_quantity) FROM public.products WHERE id = '{prod_id}';")
    assert int(stock_during['stock']) == (stock_before_cancel_test - 5), "Stock should have decreased by 5"

    # Step A: Attempt cancellation WITHOUT reason -> REASON_REQUIRED
    code, _, err = run_psql(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_cancel_id}',
            p_new_status => 'cancelled',
            p_reason => '   ',
            p_staff_name => 'موظف الإلغاء'
        );
    """)
    empty_reason_blocked = (code != 0 and "REASON_REQUIRED" in err)
    log_test("SCN-05A: Cancellation without reason is strictly rejected (REASON_REQUIRED)",
             empty_reason_blocked, f"Error: {err.splitlines()[-1] if err else 'None'}")

    # Step B: Cancel WITH reason -> restores stock exactly once
    cancellation_reason_text = "طلب العميل إلغاء الطلب لتغيير العنوان وطلب أصناف إضافية"
    code, r_cancel, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_cancel_id}',
            p_new_status => 'cancelled',
            p_reason => '{cancellation_reason_text}',
            p_staff_name => 'ريم خدمة العملاء',
            p_staff_role => 'super_admin'
        );
    """)

    code, stock_after_c, err = run_psql_json(f"SELECT jsonb_build_object('stock', stock_quantity) FROM public.products WHERE id = '{prod_id}';")
    stock_after_cancel = int(stock_after_c['stock'])

    code, o_canc, err = run_psql_json(f"""
        SELECT jsonb_build_object('status', status, 'cancellation_reason', cancellation_reason, 'is_stock_restored', is_stock_restored)
        FROM public.orders WHERE id = '{order_cancel_id}';
    """)

    # Check inventory movements ledger
    code, inv_mov, err = run_psql_json(f"""
        SELECT jsonb_build_object('movement_type', movement_type, 'quantity_change', quantity_change)
        FROM public.inventory_movements
        WHERE reference_id = '{order_cancel_id}'
        ORDER BY created_at DESC LIMIT 1;
    """)

    cancel_and_restore_pass = (
        r_cancel and r_cancel.get('success') and
        o_canc['status'] == 'cancelled' and
        o_canc['cancellation_reason'] == cancellation_reason_text and
        o_canc['is_stock_restored'] is True and
        stock_after_cancel == stock_before_cancel_test and
        inv_mov is not None and
        inv_mov['movement_type'] == 'return' and
        float(inv_mov['quantity_change']) == 5.0
    )
    log_test("SCN-05B: Order cancellation restores +5 product stock and records return inventory movement",
             cancel_and_restore_pass, f"Restored Stock: {stock_after_cancel} (Prev: {stock_before_cancel_test})")

    # Step C: Prevent double stock restoration on already cancelled order
    code, r_rep, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_cancel_id}',
            p_new_status => 'cancelled',
            p_reason => 'محاولة إلغاء ثانية',
            p_staff_name => 'موظف'
        );
    """)
    code, stock_rep, err = run_psql_json(f"SELECT jsonb_build_object('stock', stock_quantity) FROM public.products WHERE id = '{prod_id}';")
    stock_after_repeat = int(stock_rep['stock'])
    no_double_restoration = (stock_after_repeat == stock_after_cancel)
    log_test("SCN-05C: Repeated cancellation attempts cannot double-restore stock",
             (r_rep and r_rep.get('is_noop') is True) and no_double_restoration, f"Stock after repeated cancel: {stock_after_repeat}")

    # --------------------------------------------------------------------------
    # SCENARIO 6: Delivery Failure with Mandatory Reason & Stock Restoration
    # --------------------------------------------------------------------------
    code, stock_before_f, err = run_psql_json(f"SELECT jsonb_build_object('stock', stock_quantity) FROM public.products WHERE id = '{prod_id}';")
    stock_before_fail_test = int(stock_before_f['stock'])

    order_num_fail = f"ORD-{test_run_id}-FAIL"
    code, res_f, err = create_test_order(order_num_fail, prod_id, 2, prod_price, "b-jed-01", "عميل تعذر الوصول إليه")
    order_fail_id = res_f['id']

    # Transition: pending -> confirmed -> packing -> assigned -> out_for_delivery
    run_psql(f"SELECT public.update_order_status_atomic(p_order_id => '{order_fail_id}', p_new_status => 'confirmed');")
    run_psql(f"SELECT public.update_order_status_atomic(p_order_id => '{order_fail_id}', p_new_status => 'packing');")
    run_psql(f"SELECT public.update_order_status_atomic(p_order_id => '{order_fail_id}', p_new_status => 'assigned', p_courier_id => '{courier_id}');")
    run_psql(f"SELECT public.update_order_status_atomic(p_order_id => '{order_fail_id}', p_new_status => 'out_for_delivery');")

    # Mark as failed with reason
    fail_reason_text = "العميل لم يستجب للاتصال بعد 4 محاولات وهاتفه مغلق"
    code, r_fail, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_fail_id}',
            p_new_status => 'failed',
            p_reason => '{fail_reason_text}',
            p_staff_name => '{courier_name}',
            p_staff_role => 'courier'
        );
    """)

    code, o_fail, err = run_psql_json(f"""
        SELECT jsonb_build_object('status', status, 'failure_reason', failure_reason, 'is_stock_restored', is_stock_restored)
        FROM public.orders WHERE id = '{order_fail_id}';
    """)
    code, stock_after_f, err = run_psql_json(f"SELECT jsonb_build_object('stock', stock_quantity) FROM public.products WHERE id = '{prod_id}';")
    stock_after_fail = int(stock_after_f['stock'])

    code, disp_fail, err = run_psql_json(f"SELECT jsonb_build_object('status', status) FROM public.courier_dispatches WHERE order_id = '{order_fail_id}';")

    scenario_6_pass = (
        r_fail and r_fail.get('success') and
        o_fail['status'] == 'failed' and
        o_fail['failure_reason'] == fail_reason_text and
        o_fail['is_stock_restored'] is True and
        stock_after_fail == stock_before_fail_test and
        disp_fail['status'] == 'failed'
    )
    log_test("SCN-06: Delivery failure with reason restores stock and marks courier dispatch failed",
             scenario_6_pass, f"Stock Restored: {stock_after_fail}, Failure Reason: {o_fail.get('failure_reason')}")

    # --------------------------------------------------------------------------
    # SCENARIO 7: Optimistic Concurrency Conflict Detection (Two Simultaneous Updates)
    # --------------------------------------------------------------------------
    order_num_race = f"ORD-{test_run_id}-RACE"
    code, res_race, err = create_test_order(order_num_race, prod_id, 1, prod_price, "b-jed-01", "عميل سباق التزامن")
    order_race_id = res_race['id']

    # Both clients read order at version 1
    code, o_v, err = run_psql_json(f"SELECT jsonb_build_object('version', version) FROM public.orders WHERE id = '{order_race_id}';")
    v_initial = o_v['version']
    assert v_initial == 1, "Initial version must be 1"

    # Client A executes update with expected_version = 1 -> succeeds, version becomes 2
    code, res_client_a, err = run_psql_json(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_race_id}',
            p_new_status => 'confirmed',
            p_expected_version => 1,
            p_staff_name => 'المشرف الأول'
        );
    """)
    assert res_client_a and res_client_a.get('success') and res_client_a.get('version') == 2

    # Client B executes competing update with stale expected_version = 1 -> FAILS with CONCURRENT_MODIFICATION_CONFLICT
    code, _, err = run_psql(f"""
        SELECT public.update_order_status_atomic(
            p_order_id => '{order_race_id}',
            p_new_status => 'cancelled',
            p_expected_version => 1,
            p_reason => 'إلغاء متزامن متعارض',
            p_staff_name => 'المشرف الثاني'
        );
    """)
    client_b_conflict_prevented = (code != 0 and "CONCURRENT_MODIFICATION_CONFLICT" in err)
    log_test("SCN-07: Competing concurrent update with stale expected_version is rejected (CONCURRENT_MODIFICATION_CONFLICT)",
             client_b_conflict_prevented, f"Server Error: {err.splitlines()[-1] if err else 'None'}")

    # --------------------------------------------------------------------------
    # SCENARIO 8: Branch Isolation & Cross-Branch Authorization
    # --------------------------------------------------------------------------
    order_num_branch = f"ORD-{test_run_id}-BRN"
    code, res_brn, err = create_test_order(order_num_branch, prod_id, 1, prod_price, "b-jed-01", "عميل فرع جدة المعزول")
    order_branch_id = res_brn['id']

    # Generate JWT for Riyadh Cashier
    code, jwt_res, err = run_psql_json("""
        SELECT jsonb_build_object('token', auth.sign_jwt(jsonb_build_object(
            'sub', 'staff-cashier-ruh',
            'role', 'authenticated',
            'user_role', 'cashier',
            'branch_id', 'b-ruh-01',
            'exp', 2524608000
        )));
    """)
    ruh_cashier_jwt = jwt_res['token']

    # Call PostgREST RPC as Riyadh Cashier trying to alter Jeddah order
    curl_cmd = [
        "curl", "-s", "-X", "POST",
        "http://localhost:54321/rpc/update_order_status_atomic",
        "-H", f"Authorization: Bearer {ruh_cashier_jwt}",
        "-H", "Content-Type: application/json",
        "-d", json.dumps({
            "p_order_id": order_branch_id,
            "p_new_status": "confirmed",
            "p_staff_name": "كاشير الرياض"
        })
    ]
    proc = subprocess.run(curl_cmd, capture_output=True, text=True)
    resp_cross_branch = proc.stdout
    cross_branch_blocked = "UNAUTHORIZED_BRANCH" in resp_cross_branch or "42501" in resp_cross_branch or "cannot modify order" in resp_cross_branch

    log_test("SCN-08: Cross-branch modification by non-super-admin staff is strictly rejected",
             cross_branch_blocked, f"Server response: {resp_cross_branch[:120]}")

    # --------------------------------------------------------------------------
    # SCENARIO 9: Persistence Verification After Session Close & Reopen
    # --------------------------------------------------------------------------
    code, persisted_cancel, err = run_psql_json(f"""
        SELECT jsonb_build_object('status', status, 'version', version, 'cancellation_reason', cancellation_reason)
        FROM public.orders WHERE id = '{order_cancel_id}';
    """)
    code, persisted_hist, err = run_psql_json(f"""
        SELECT jsonb_build_object('count', count(*))
        FROM public.order_status_history WHERE order_id = '{order_1_id}';
    """)
    persisted_history_count = int(persisted_hist['count'])

    scenario_9_pass = (
        persisted_cancel is not None and
        persisted_cancel['status'] == 'cancelled' and
        persisted_cancel['cancellation_reason'] == cancellation_reason_text and
        persisted_history_count == 6
    )
    log_test("SCN-09: Complete order state, version, reasons, and timeline persist cleanly in PostgreSQL",
             scenario_9_pass, f"Persisted History Count: {persisted_history_count}")

    print("==============================================================================")
    print(f"🎯 ALL {pass_count}/{total_tests} FORENSIC SCENARIOS PASSED WITH ZERO DEFECTS (100% SUCCESS)")
    print("==============================================================================")

if __name__ == '__main__':
    run_suite()
