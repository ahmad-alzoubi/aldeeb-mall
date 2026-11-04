#!/usr/bin/env python3
"""
================================================================================
🚚 ALDEEB MALL — TASK 15 FORENSIC VERIFICATION SUITE
   Delivery Zones, Boundaries, Fulfillment & Real-time Fee Engine
   PostgreSQL 16, PostgREST 12, Haversine Distance, Dynamic Surge & RLS Audit
================================================================================
Tests comprehensive server-authoritative validations:
1. Schema integrity & Monotonic migration sequence (025)
2. Delivery zones query via PostgREST API (public read)
3. Active zone coverage check &Haversine distance computation
4. Free delivery threshold dynamic calculation (subtotal >= 150,000)
5. Zone radius boundary precision (inside vs outside radius)
6. Out-of-coverage coordinates explicit server rejection
7. Deactivated zone rejection (Daraa excluded by default)
8. Closed branch server rejection and recovery on reopening
9. Admin surge pricing toggle and real-time fee calculation reflection
10. Admin base delivery fee change and immediate client quote reflection
11. Click & Collect / Curbside pickup zero-fee coverage bypass
12. Row Level Security (RLS) protection against anonymous tampering
13. Atomic order placement with server-validated delivery fee
14. Anti-tampering rejection: Negative delivery fee blocked by server
15. Anti-tampering rejection: Fee on free-delivery-eligible order blocked
16. Multi-device persistence and PostgREST schema reload resilience
================================================================================
"""

import subprocess
import json
import urllib.request
import urllib.error
import time
import sys

DB_NAME = "aldeeb_mall_prod"
DB_USER = "ahmad_alzoubi"
POSTGREST_URL = "http://127.0.0.1:54321"

def run_psql(query: str, as_json=False):
    """Executes a SQL query against PostgreSQL returning returncode, stdout, stderr."""
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

def http_get(path: str):
    url = f"{POSTGREST_URL}{path}"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = resp.read().decode("utf-8")
            return resp.status, json.loads(data)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, body
    except Exception as e:
        return 500, str(e)

def http_post(path: str, payload: dict, token: str = None):
    url = f"{POSTGREST_URL}{path}"
    body_bytes = json.dumps(payload).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=body_bytes, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = resp.read().decode("utf-8")
            return resp.status, json.loads(data) if data else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(err_body)
        except Exception:
            return e.code, err_body
    except Exception as e:
        return 500, str(e)

pass_count = 0
fail_count = 0

def assert_test(name: str, condition: bool, details: str = ""):
    global pass_count, fail_count
    if condition:
        pass_count += 1
        print(f"  ✅ [PASS] {name} {details}")
    else:
        fail_count += 1
        print(f"  ❌ [FAIL] {name} {details}")

print("================================================================================")
print("🚀 STARTING TASK 15 FORENSIC SUITE: DELIVERY ZONES & FULFILLMENT ENGINE")
print("================================================================================")

# ------------------------------------------------------------------------------
# Test 1: Monotonic Sequence & Migration Audit
# ------------------------------------------------------------------------------
print("\n[SCENARIO 1] Monotonic Sequence & Migration Audit...")
code, out, _ = run_psql("SELECT filename FROM public._schema_migrations WHERE filename = '20261104_025_delivery_zones_and_fulfillment_engine.sql';")
assert_test("Migration 025 in _schema_migrations", code == 0 and "20261104_025_delivery_zones_and_fulfillment_engine.sql" in out)

code, out, _ = run_psql("SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'delivery_zones';")
assert_test("delivery_zones table exists in public schema", code == 0 and "1" in out)

code, out, _ = run_psql("SELECT concat(relrowsecurity, ':', relforcerowsecurity) FROM pg_class WHERE relname = 'delivery_zones';")
assert_test("delivery_zones RLS and FORCE RLS enabled", "t:t" in out)

# ------------------------------------------------------------------------------
# Test 2: Query Delivery Zones via PostgREST
# ------------------------------------------------------------------------------
print("\n[SCENARIO 2] PostgREST API Query for Delivery Zones...")
status, zones = http_get("/delivery_zones?select=id,zone_name_ar,city,is_active,base_delivery_fee&order=city.asc")
assert_test("PostgREST returns 200 OK for delivery_zones", status == 200 and isinstance(zones, list))
zone_ids = [z['id'] for z in zones]
assert_test("Damascus Central zone exists", 'zn-dam-central' in zone_ids)
assert_test("Aleppo Central zone exists", 'zn-alp-central' in zone_ids)
assert_test("Latakia Coastal zone exists", 'zn-lat-central' in zone_ids)
assert_test("Daraa Station zone exists", 'zn-dra-station' in zone_ids)

# ------------------------------------------------------------------------------
# Test 3: Damascus Mezzeh Active Coverage Check
# ------------------------------------------------------------------------------
print("\n[SCENARIO 3] Active Zone Coverage & Fee Calculation (Damascus Mezzeh)...")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 33.5138,
    "p_longitude": 36.2765,
    "p_city": "دمشق",
    "p_district": "المزة",
    "p_subtotal": 50000.0
})
assert_test("Coverage check returns 200 OK", status == 200)
assert_test("Damascus Mezzeh is covered", res.get("is_covered") is True)
assert_test("Matched zone is zn-dam-central", res.get("zone_id") == "zn-dam-central")
assert_test("Assigned branch is b-dam-01", res.get("branch_id") == "b-dam-01")
assert_test("Base delivery fee is 5000.00", float(res.get("base_delivery_fee", 0)) == 5000.0)
assert_test("Final delivery fee is 5000.00", float(res.get("final_delivery_fee", 0)) == 5000.0)
assert_test("Estimated minutes is 20", res.get("estimated_minutes") == 20)

# ------------------------------------------------------------------------------
# Test 4: Free Delivery Threshold Application
# ------------------------------------------------------------------------------
print("\n[SCENARIO 4] Free Delivery Threshold Calculation...")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 33.5138,
    "p_longitude": 36.2765,
    "p_subtotal": 180000.0
})
assert_test("Order above threshold qualifies for free delivery", res.get("is_free_delivery") is True)
assert_test("Final delivery fee is 0.00 for free delivery", float(res.get("final_delivery_fee", 99)) == 0.0)

# ------------------------------------------------------------------------------
# Test 5: Zone Radius Boundary Precision
# ------------------------------------------------------------------------------
print("\n[SCENARIO 5] Zone Radius Boundary Precision (Haversine)...")
# Center of Damascus Central is (33.5138, 36.2765) with radius 6.0km
# Offset ~0.03 deg lat is approx 3.3km (inside 6km radius)
code, res_inside, _ = run_psql_json("SELECT public.check_delivery_coverage(33.5400, 36.2765, 'دمشق', NULL, 50000);")
assert_test("Point at 3km from center is covered", res_inside.get("is_covered") is True and res_inside.get("zone_id") == "zn-dam-central")

# Offset ~0.25 deg is ~28km (outside Damascus Central radius)
code, res_outside, _ = run_psql_json("SELECT public.check_delivery_coverage(33.7500, 36.2765, NULL, NULL, 50000);")
assert_test("Point at 28km is outside Damascus Central radius", res_outside.get("zone_id") != "zn-dam-central")

# ------------------------------------------------------------------------------
# Test 6: Uncovered Location Server Rejection
# ------------------------------------------------------------------------------
print("\n[SCENARIO 6] Out-of-Coverage Location Server Rejection...")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 30.0000,
    "p_longitude": 30.0000,
    "p_subtotal": 50000.0
})
assert_test("Remote desert point is rejected", res.get("is_covered") is False)
assert_test("Rejection reason is OUT_OF_COVERAGE", res.get("rejection_reason") == "OUT_OF_COVERAGE")
assert_test("Rejection status is REJECTED", res.get("status") == "REJECTED")

# ------------------------------------------------------------------------------
# Test 7: Deactivated Zone Rejection (Daraa Excluded by Default)
# ------------------------------------------------------------------------------
print("\n[SCENARIO 7] Deactivated Zone Rejection (Daraa Excluded)...")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 32.6250,
    "p_longitude": 36.1050,
    "p_city": "درعا",
    "p_district": "درعا المحطة",
    "p_subtotal": 50000.0
})
assert_test("Daraa coordinates are not covered", res.get("is_covered") is False)
assert_test("Rejection reason is ZONE_INACTIVE", res.get("rejection_reason") == "ZONE_INACTIVE")

# ------------------------------------------------------------------------------
# Test 8: Closed Branch Rejection & Recovery
# ------------------------------------------------------------------------------
print("\n[SCENARIO 8] Closed Branch Rejection & Recovery...")
# Deactivate branch b-dam-01 temporarily
run_psql("UPDATE public.branches SET is_active = false WHERE id = 'b-dam-01';")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 33.5138,
    "p_longitude": 36.2765,
    "p_subtotal": 50000.0
})
assert_test("Coverage rejected when branch is closed", res.get("is_covered") is False)
assert_test("Rejection reason is BRANCH_CLOSED", res.get("rejection_reason") == "BRANCH_CLOSED")

# Re-activate branch b-dam-01
run_psql("UPDATE public.branches SET is_active = true WHERE id = 'b-dam-01';")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 33.5138,
    "p_longitude": 36.2765,
    "p_subtotal": 50000.0
})
assert_test("Coverage restored immediately when branch reopens", res.get("is_covered") is True)

# ------------------------------------------------------------------------------
# Test 9: Admin Surge Fee Modification & Realtime Reflection
# ------------------------------------------------------------------------------
print("\n[SCENARIO 9] Admin Surge Fee Modification & Dynamic Realtime Reflection...")
# Enable surge pricing on zn-dam-central: +3,000 SYP
run_psql("UPDATE public.delivery_zones SET is_surge_pricing_active = true, surge_fee = 3000.00 WHERE id = 'zn-dam-central';")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 33.5138,
    "p_longitude": 36.2765,
    "p_subtotal": 50000.0
})
assert_test("Surge pricing is active on server", res.get("is_surge_active") is True)
assert_test("Surge fee is 3000.00", float(res.get("surge_fee", 0)) == 3000.0)
assert_test("Final fee includes surge (5000 + 3000 = 8000)", float(res.get("final_delivery_fee", 0)) == 8000.0)

# Reset surge pricing
run_psql("UPDATE public.delivery_zones SET is_surge_pricing_active = false, surge_fee = 0.00 WHERE id = 'zn-dam-central';")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 33.5138,
    "p_longitude": 36.2765,
    "p_subtotal": 50000.0
})
assert_test("Surge fee disabled returns normal fee 5000", float(res.get("final_delivery_fee", 0)) == 5000.0)

# ------------------------------------------------------------------------------
# Test 10: Admin Base Fee Modification
# ------------------------------------------------------------------------------
print("\n[SCENARIO 10] Admin Base Fee Modification...")
run_psql("UPDATE public.delivery_zones SET base_delivery_fee = 6500.00 WHERE id = 'zn-dam-central';")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 33.5138,
    "p_longitude": 36.2765,
    "p_subtotal": 50000.0
})
assert_test("Updated base fee 6500 reflected immediately in client quote", float(res.get("final_delivery_fee", 0)) == 6500.0)
# Restore
run_psql("UPDATE public.delivery_zones SET base_delivery_fee = 5000.00 WHERE id = 'zn-dam-central';")

# ------------------------------------------------------------------------------
# Test 11: Click & Collect Bypass
# ------------------------------------------------------------------------------
print("\n[SCENARIO 11] Click & Collect / Pickup Zero-Fee Bypass...")
status, res = http_post("/rpc/check_delivery_coverage", {
    "p_latitude": 30.0000,
    "p_longitude": 30.0000,
    "p_delivery_slot": "استلام من فرع المول (Click & Collect)",
    "p_subtotal": 25000.0
})
assert_test("Click & Collect is covered even from remote coordinates", res.get("is_covered") is True)
assert_test("Click & Collect delivery fee is 0.00", float(res.get("final_delivery_fee", 99)) == 0.0)

# ------------------------------------------------------------------------------
# Test 12: Anonymous Mutation Defense (RLS)
# ------------------------------------------------------------------------------
print("\n[SCENARIO 12] Anonymous Mutation Defense (RLS)...")
# Attempt to PATCH delivery_zones as anon
req = urllib.request.Request(
    f"{POSTGREST_URL}/delivery_zones?id=eq.zn-dam-central",
    data=json.dumps({"base_delivery_fee": 1.0}).encode("utf-8"),
    headers={"Content-Type": "application/json", "Prefer": "return=representation"},
    method="PATCH"
)
try:
    with urllib.request.urlopen(req) as resp:
        anon_status = resp.status
        anon_data = resp.read().decode("utf-8")
except urllib.error.HTTPError as e:
    anon_status = e.code
    anon_data = ""
except Exception:
    anon_status = 500
    anon_data = ""

# With RLS, anon mutation is blocked: either 401/403 or 200 with empty [] (0 rows updated due to RLS)
assert_test("Anonymous mutation blocked by RLS / 0 rows affected", anon_status in [401, 403] or (anon_status in [200, 204] and anon_data in ["", "[]"]))

# Verify value unchanged
code, out, _ = run_psql("SELECT base_delivery_fee FROM public.delivery_zones WHERE id = 'zn-dam-central';")
assert_test("Base fee remained secure at 5000", "5000" in out)

# ------------------------------------------------------------------------------
# Test 13: Order Placement with Server-Validated Delivery Fee
# ------------------------------------------------------------------------------
print("\n[SCENARIO 13] Order Placement with Server-Validated Delivery Fee...")
# Get an active product
code, prod_json, _ = run_psql_json("SELECT jsonb_build_object('id', id, 'price', price, 'stock', stock_quantity) FROM public.products WHERE is_active = true AND stock_quantity > 5 LIMIT 1;")
prod_id = prod_json['id']
prod_price = float(prod_json['price'])

order_num = f"ORD-ZONETEST-{int(time.time())}"
items_payload = json.dumps([{"product_id": prod_id, "quantity": 1, "unit_price": prod_price}])

# Damascus Central fee is 5000.00, subtotal is prod_price, total is prod_price + 5000
total_val = prod_price + 5000.00

order_sql = f"""
SELECT public.place_order_atomic(
    '{order_num}',
    NULL,
    'توصيل فوري خلال 60 دقيقة',
    'cod',
    {prod_price},
    5000.00,
    0.00,
    0,
    0.00,
    {total_val},
    'اختبار ربط مناطق ورسوم التوصيل الحقيقية',
    '{items_payload}'::jsonb,
    'b-dam-01',
    NULL,
    'IDEMP-ZONE-{int(time.time())}',
    'عميل تجربة النطاقات',
    '+963944111222'
);
"""
code, order_res, err = run_psql_json(order_sql)
assert_test("Order placement with valid delivery fee succeeded", code == 0 and order_res.get("order_number") == order_num)
assert_test("Order stored authoritative delivery_fee 5000.00", float(order_res.get("delivery_fee", 0)) == 5000.0)

# ------------------------------------------------------------------------------
# Test 14: Tampered Negative Delivery Fee Rejection
# ------------------------------------------------------------------------------
print("\n[SCENARIO 14] Tampered Negative Delivery Fee Server Rejection...")
bad_order_num = f"ORD-BADFEE-{int(time.time())}"
bad_sql = f"""
SELECT public.place_order_atomic(
    '{bad_order_num}',
    NULL,
    'توصيل فوري خلال 60 دقيقة',
    'cod',
    {prod_price},
    -500.00,
    0.00,
    0,
    0.00,
    {prod_price - 500.00},
    'تلاعب برسم توصيل سالب',
    '{items_payload}'::jsonb,
    'b-dam-01'
);
"""
code, _, err = run_psql(bad_sql)
assert_test("Negative delivery fee rejected by server", code != 0 and "DELIVERY_FEE_TAMPERED" in err)

# ------------------------------------------------------------------------------
# Test 15: Tampered Fee on Free Delivery Order Rejection
# ------------------------------------------------------------------------------
print("\n[SCENARIO 15] Tampered Fee on Free Delivery Order Rejection...")
# Buy enough items to exceed free delivery threshold 150000 using high-stock product
code, free_prod_json, _ = run_psql_json("""
SELECT jsonb_build_object('id', p.id, 'price', p.price, 'stock', bi.quantity_on_hand)
FROM public.products p
JOIN public.branch_inventory bi ON bi.product_id = p.id
WHERE bi.branch_id = 'b-dam-01' AND p.is_active = true AND bi.quantity_on_hand >= 5 AND p.price >= 1000
ORDER BY p.price DESC
LIMIT 1;
""")
free_prod_id = free_prod_json.get('id', 'b2b00000-0000-0000-0000-000000000001')
free_prod_price = float(free_prod_json.get('price', 50000.00))
needed_qty = 4
large_subtotal = round(needed_qty * free_prod_price, 2)
large_items = json.dumps([{"product_id": free_prod_id, "quantity": needed_qty, "unit_price": free_prod_price}])
bad_free_order = f"ORD-BADFREE-{int(time.time())}"

bad_free_sql = f"""
SELECT public.place_order_atomic(
    '{bad_free_order}',
    NULL,
    'توصيل فوري خلال 60 دقيقة',
    'cod',
    {large_subtotal},
    5000.00,
    0.00,
    0,
    0.00,
    {large_subtotal + 5000.00},
    'محاولة فرض رسوم توصيل لطلب يستحق شحناً مجانياً',
    '{large_items}'::jsonb,
    'b-dam-01'
);
"""
code, _, err = run_psql(bad_free_sql)
assert_test("Charging delivery fee on free-delivery-eligible order rejected", code != 0 and "DELIVERY_FEE_TAMPERED" in err)

# ------------------------------------------------------------------------------
# Test 16: Persistence Across Reloads & Session Resiliency
# ------------------------------------------------------------------------------
print("\n[SCENARIO 16] Persistence Across PostgREST Schema Reloads & Multi-Client...")
run_psql("NOTIFY pgrst, 'reload schema';")
time.sleep(0.5)

status, final_check = http_get("/delivery_zones?id=eq.zn-dam-central")
assert_test("Delivery zone persists after PostgREST schema reload", status == 200 and len(final_check) == 1)
assert_test("Damascus zone base fee intact", float(final_check[0]["base_delivery_fee"]) == 5000.0)

print("\n================================================================================")
print(f"📊 TASK 15 FORENSIC VERIFICATION RESULTS: {pass_count} PASSED, {fail_count} FAILED")
print("================================================================================")

if fail_count > 0:
    print(f"❌ Verification failed with {fail_count} failures.")
    sys.exit(1)
else:
    print("✅ All 24 assertions passed with 100% Zero Defect!")
    sys.exit(0)
