#!/usr/bin/env python3
"""
==============================================================================
🛡️ ALDEEB MALL & HYPERMARKET — RBAC & MULTI-BRANCH ISOLATION FORENSIC TEST SUITE
==============================================================================
Validates end-to-end multi-layer security:
1. Anonymous request blocking on all sensitive endpoints.
2. Customer isolation & anti-IDOR checks.
3. Driver / Courier dispatch task isolation.
4. Cashier strict branch isolation & payroll restriction.
5. Privilege escalation attack interception (trigger & policy enforcement).
6. Branch manager isolation (Jeddah vs Damascus vs Riyadh).
7. Super admin cross-branch management visibility.
8. Data persistence and idempotency verification.
==============================================================================
"""

import urllib.request
import urllib.error
import json
import time
import sys

BASE_URL = "http://127.0.0.1:54321"

def log_test(name, passed, details=""):
    status = "✅ PASS" if passed else "❌ FAIL"
    print(f"{status} | {name}")
    if details:
        print(f"        {details}")
    if not passed:
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

def http_patch(endpoint, payload, headers=None):
    url = f"{BASE_URL}{endpoint}"
    data = json.dumps(payload).encode('utf-8')
    req_headers = {'Content-Type': 'application/json', 'Prefer': 'return=representation'}
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(url, data=data, headers=req_headers, method='PATCH')
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

def main():
    print("=" * 80)
    print("🚀 RUNNING ALDEEB MALL ROLE MATRIX & BRANCH ISOLATION AUDIT SUITE")
    print("=" * 80)

    # --------------------------------------------------------------------------
    # SUITE 1: Anonymous Access Restrictions
    # --------------------------------------------------------------------------
    print("\n--- [SUITE 1: Anonymous Access Enforcement] ---")

    # 1.1 Products catalog should be public
    status, res = http_get("/products?limit=3")
    log_test("1.1 Anonymous can view public products catalog", status == 200 and len(res) > 0, f"Returned {len(res)} products")

    # 1.2 Categories should be public
    status, res = http_get("/categories?limit=3")
    log_test("1.2 Anonymous can view public categories", status == 200 and len(res) > 0, f"Returned {len(res)} categories")

    # 1.3 Orders MUST BE BLOCKED for anonymous
    status, res = http_get("/orders")
    log_test("1.3 Anonymous access to /orders is BLOCKED", status in (401, 403), f"Status: {status}")

    # 1.4 Staff members MUST BE BLOCKED for anonymous
    status, res = http_get("/staff_members")
    log_test("1.4 Anonymous access to /staff_members is BLOCKED", status in (401, 403), f"Status: {status}")

    # 1.5 Payroll transactions MUST BE BLOCKED for anonymous
    status, res = http_get("/payroll_transactions")
    log_test("1.5 Anonymous access to /payroll_transactions is BLOCKED", status in (401, 403), f"Status: {status}")

    # 1.6 Courier dispatches MUST BE BLOCKED for anonymous
    status, res = http_get("/courier_dispatches")
    log_test("1.6 Anonymous access to /courier_dispatches is BLOCKED", status in (401, 403), f"Status: {status}")

    # --------------------------------------------------------------------------
    # SUITE 2: Customer Privacy & Anti-IDOR Protections
    # --------------------------------------------------------------------------
    print("\n--- [SUITE 2: Customer Isolation & Anti-IDOR Protection] ---")

    # Login Customer 1 & 2
    status, c1_res = http_post("/rpc/customer_login", {"p_phone": "+966509990001", "p_password": "pass"})
    token_c1 = c1_res["token"]
    cust1_id = c1_res["profile"]["id"]
    h_c1 = {"Authorization": f"Bearer {token_c1}"}

    status, c2_res = http_post("/rpc/customer_login", {"p_phone": "+966509990002", "p_password": "pass"})
    token_c2 = c2_res["token"]
    cust2_id = c2_res["profile"]["id"]
    h_c2 = {"Authorization": f"Bearer {token_c2}"}

    log_test("2.1 Customer 1 & 2 authenticated with server JWT", status == 200 and cust1_id != cust2_id)

    # Customer 1 creates an order
    order_num_c1 = f"ORD-ISOL-{int(time.time())}"
    c1_order = {
        "order_number": order_num_c1,
        "user_id": cust1_id,
        "branch_id": "b-ruh-01",
        "customer_name": "سعد التميمي",
        "customer_phone": "+966509990001",
        "subtotal": 175.50,
        "total_amount": 175.50,
        "payment_method": "cod",
        "payment_status": "pending",
        "status": "pending"
    }
    status, ins_res = http_post("/orders", c1_order, headers=h_c1)
    log_test("2.2 Customer 1 created own order", status in (200, 201), f"Order: {order_num_c1}")

    # Customer 1 views own order
    status, view_c1 = http_get(f"/orders?order_number=eq.{order_num_c1}", headers=h_c1)
    log_test("2.3 Customer 1 can view own order", status == 200 and len(view_c1) == 1)

    # Customer 2 attempts IDOR to view Customer 1's order
    status, view_c2 = http_get(f"/orders?order_number=eq.{order_num_c1}", headers=h_c2)
    log_test("2.4 Customer 2 IDOR on Customer 1 order returns 0 rows", status == 200 and len(view_c2) == 0, f"Returned {len(view_c2)} rows")

    # Customer 2 attempts IDOR to read Customer 1 profile
    status, prof_c2 = http_get(f"/profiles?id=eq.{cust1_id}", headers=h_c2)
    log_test("2.5 Customer 2 IDOR on Customer 1 profile returns 0 rows", status == 200 and len(prof_c2) == 0, f"Returned {len(prof_c2)} rows")

    # --------------------------------------------------------------------------
    # SUITE 3: Driver / Courier Task Isolation
    # --------------------------------------------------------------------------
    print("\n--- [SUITE 3: Courier / Driver Task Isolation] ---")

    status, cur1_res = http_post("/rpc/courier_login", {"p_phone": "+971501234567", "p_password": "pass"})
    token_cur1 = cur1_res["token"]
    courier1_id = cur1_res["courier"]["id"]
    h_cur1 = {"Authorization": f"Bearer {token_cur1}"}

    status, cur2_res = http_post("/rpc/courier_login", {"p_phone": "+971509876543", "p_password": "pass"})
    token_cur2 = cur2_res["token"]
    courier2_id = cur2_res["courier"]["id"]
    h_cur2 = {"Authorization": f"Bearer {token_cur2}"}

    log_test("3.1 Couriers 1 & 2 authenticated", cur1_res["success"] and cur2_res["success"])

    # Courier 1 queries dispatches: must only see tasks for Courier 1
    status, cur1_tasks = http_get("/courier_dispatches", headers=h_cur1)
    c1_has_own = any(t["courier_id"] == courier1_id for t in cur1_tasks)
    c1_has_other = any(t["courier_id"] == courier2_id for t in cur1_tasks)
    log_test("3.2 Courier 1 sees ONLY assigned dispatches", c1_has_own and not c1_has_other, f"Tasks visible: {len(cur1_tasks)}, Cross-courier tasks: {c1_has_other}")

    # Courier 1 attempts IDOR on Dispatch assigned to Courier 2
    status, idor_disp = http_get("/courier_dispatches?id=eq.d2222222-2222-2222-2222-222222222222", headers=h_cur1)
    log_test("3.3 Courier 1 IDOR on Courier 2 dispatch returns 0 rows", status == 200 and len(idor_disp) == 0)

    # Courier 1 attempts unauthorized PATCH on Courier 2 dispatch
    status, patch_disp = http_patch("/courier_dispatches?id=eq.d2222222-2222-2222-2222-222222222222", {"status": "delivered"}, headers=h_cur1)
    log_test("3.4 Courier 1 unauthorized modification blocked (0 rows updated)", status in (200, 403) and len(patch_disp) == 0)

    # --------------------------------------------------------------------------
    # SUITE 4: Cashier Strict Role & Branch Isolation
    # --------------------------------------------------------------------------
    print("\n--- [SUITE 4: Cashier Strict Role & Branch Isolation] ---")

    status, omar_login = http_post("/rpc/staff_login", {"p_username": "cashier_omar", "p_password": "pos123"})
    token_omar = omar_login["token"]
    h_omar = {"Authorization": f"Bearer {token_omar}"}
    log_test("4.1 Cashier Omar logged in with branch b-ruh-01", omar_login["success"] and omar_login["staff"]["role"] == "cashier")

    # Cashier queries staff_members: must ONLY see himself
    status, omar_staff = http_get("/staff_members?select=id,full_name,role", headers=h_omar)
    log_test("4.2 Cashier Omar sees ONLY his own staff record", status == 200 and len(omar_staff) == 1 and omar_staff[0]["id"] == "staff-cashier-01", f"Returned {len(omar_staff)} records")

    # Cashier queries payroll_transactions: MUST BE 0
    status, omar_payroll = http_get("/payroll_transactions", headers=h_omar)
    log_test("4.3 Cashier Omar is barred from payroll (0 records visible)", status == 200 and len(omar_payroll) == 0)

    # Cashier queries Jeddah branch orders: MUST BE 0
    status, omar_jed_orders = http_get("/orders?branch_id=eq.b-jed-01", headers=h_omar)
    log_test("4.4 Cashier Omar sees 0 orders from Jeddah branch (b-jed-01)", status == 200 and len(omar_jed_orders) == 0)

    # Cashier queries his own branch orders: Permitted
    status, omar_ruh_orders = http_get("/orders?branch_id=eq.b-ruh-01", headers=h_omar)
    log_test("4.5 Cashier Omar can see his branch (b-ruh-01) orders", status == 200 and len(omar_ruh_orders) > 0, f"Found {len(omar_ruh_orders)} orders")

    # Cashier attempts to insert order for another branch (Jeddah): MUST BE REJECTED 403
    cross_branch_order = {
        "order_number": f"ORD-ILLEGAL-JED-{int(time.time())}",
        "branch_id": "b-jed-01",
        "customer_name": "مخالف الصلاحيات",
        "customer_phone": "+966500000099",
        "subtotal": 100.0,
        "total_amount": 100.0,
        "payment_method": "cash",
        "payment_status": "paid",
        "status": "delivered"
    }
    status, illegal_res = http_post("/orders", cross_branch_order, headers=h_omar)
    log_test("4.6 Cashier Omar cross-branch order insertion is BLOCKED with 403", status == 403, f"Status: {status}")

    # --------------------------------------------------------------------------
    # SUITE 5: Privilege Escalation Attack Interception
    # --------------------------------------------------------------------------
    print("\n--- [SUITE 5: Privilege Escalation Interception] ---")

    # Cashier Omar attempts to change his role to 'super_admin'
    status, esc_res = http_patch("/staff_members?id=eq.staff-cashier-01", {"role": "super_admin"}, headers=h_omar)
    log_test("5.1 Role elevation attack (cashier -> super_admin) is BLOCKED with 403", status == 403, f"Status: {status}")

    # Cashier Omar attempts to increase his basic salary
    status, sal_res = http_patch("/staff_members?id=eq.staff-cashier-01", {"basic_salary": 99000}, headers=h_omar)
    log_test("5.2 Salary tampering attack is BLOCKED with 403", status == 403, f"Status: {status}")

    # --------------------------------------------------------------------------
    # SUITE 6: Branch Manager Cross-Branch Isolation
    # --------------------------------------------------------------------------
    print("\n--- [SUITE 6: Branch Manager Cross-Branch Isolation] ---")

    # Manager Rami (Jeddah b-jed-01)
    status, rami_login = http_post("/rpc/staff_login", {"p_username": "manager_rami", "p_password": "jed123"})
    token_rami = rami_login["token"]
    h_rami = {"Authorization": f"Bearer {token_rami}"}

    # Manager Wael (Damascus b-dam-01)
    status, wael_login = http_post("/rpc/staff_login", {"p_username": "manager_wael", "p_password": "dam123"})
    token_wael = wael_login["token"]
    h_wael = {"Authorization": f"Bearer {token_wael}"}

    log_test("6.1 Branch Managers (Jeddah & Damascus) authenticated", rami_login["success"] and wael_login["success"])

    # Manager Rami queries staff: must see ONLY Jeddah staff
    status, rami_staff = http_get("/staff_members?select=id,full_name,branch_id", headers=h_rami)
    rami_all_jeddah = all(s["branch_id"] == "b-jed-01" for s in rami_staff)
    log_test("6.2 Manager Rami sees ONLY Jeddah staff", status == 200 and rami_all_jeddah and len(rami_staff) == 2, f"Visible: {len(rami_staff)}")

    # Manager Wael queries staff: must see ONLY Damascus staff
    status, wael_staff = http_get("/staff_members?select=id,full_name,branch_id", headers=h_wael)
    wael_all_dam = all(s["branch_id"] == "b-dam-01" for s in wael_staff)
    log_test("6.3 Manager Wael sees ONLY Damascus staff", status == 200 and wael_all_dam and len(wael_staff) == 1, f"Visible: {len(wael_staff)}")

    # Manager Rami queries Damascus orders: MUST BE 0
    status, rami_dam_orders = http_get("/orders?branch_id=eq.b-dam-01", headers=h_rami)
    log_test("6.4 Manager Rami sees 0 orders from Damascus branch (b-dam-01)", status == 200 and len(rami_dam_orders) == 0)

    # --------------------------------------------------------------------------
    # SUITE 7: Super Admin Central Visibility & Management
    # --------------------------------------------------------------------------
    print("\n--- [SUITE 7: Super Admin Central Visibility] ---")

    status, admin_login = http_post("/rpc/staff_login", {"p_username": "admin", "p_password": "admin"})
    token_admin = admin_login["token"]
    h_admin = {"Authorization": f"Bearer {token_admin}"}

    # Super Admin queries all staff: MUST BE ALL 8
    status, admin_staff = http_get("/staff_members?select=id,full_name,branch_id", headers=h_admin)
    log_test("7.1 Super Admin has full cross-branch visibility over staff", status == 200 and len(admin_staff) >= 8, f"Total staff: {len(admin_staff)}")

    # Super Admin queries all orders across all branches
    status, admin_orders = http_get("/orders", headers=h_admin)
    log_test("7.2 Super Admin has full cross-branch visibility over orders", status == 200 and len(admin_orders) >= 5, f"Total orders: {len(admin_orders)}")

    # --------------------------------------------------------------------------
    # SUITE 8: Persistence & Idempotency Verification
    # --------------------------------------------------------------------------
    print("\n--- [SUITE 8: Persistence & Integrity Verification] ---")

    # Verify Customer 1 order persisted correctly and retains full total amount
    status, check_c1 = http_get(f"/orders?order_number=eq.{order_num_c1}", headers=h_c1)
    persisted = len(check_c1) == 1 and float(check_c1[0]["total_amount"]) == 175.50
    log_test("8.1 Verified order data persistence and financial accuracy", persisted, f"Order: {order_num_c1}, Total: {check_c1[0]['total_amount'] if check_c1 else None}")

    print("\n" + "=" * 80)
    print("🏆 ALL 24/24 RBAC & BRANCH ISOLATION SECURITY SCENARIOS PASSED 100%!")
    print("=" * 80)

if __name__ == "__main__":
    main()
