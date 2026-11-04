#!/usr/bin/env python3
"""
Forensic End-to-End Verification Test for Coupon '5555' & Governance System
Aldeeb Mall & Hypermarket Enterprise Suite
"""

import sys
import json
import urllib.request
import urllib.error

POSTGREST_PORT = 54321
PROXY_PORT = 5173
POSTGREST_URL = f"http://127.0.0.1:{POSTGREST_PORT}"
PROXY_URL = f"http://127.0.0.1:{PROXY_PORT}/rest/v1"

ADMIN_JWT = (
    "eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9."
    "eyJyb2xlIjogImF1dGhlbnRpY2F0ZWQiLCAidXNlcl9yb2xlIjogInN1cGVyX2FkbWluIiwgInN1YiI6ICJhMDAwMDAwMC0wMDAwLTQwMDAtYTAwMC0wMDAwMDAwMDAwMDEiLCAiaXNzIjogImFsZGVlYi1tYWxsIiwgImV4cCI6IDI1MjQ2MDgwMDB9."
    "2pc6ae9e3RmAoSBwMniVLoBxpjTxrDB2i1Y34g_oiu8"
)

def run_test(name, fn):
    print(f"▶ Testing: {name}...", end=" ", flush=True)
    try:
        fn()
        print("✅ PASS")
        return True
    except Exception as e:
        print(f"❌ FAIL: {e}")
        return False

def test_coupon_exists_in_database():
    req = urllib.request.Request(f"{POSTGREST_URL}/coupons?code=eq.5555")
    with urllib.request.urlopen(req, timeout=5) as res:
        data = json.loads(res.read().decode())
        assert len(data) >= 1, "Coupon 5555 not found in coupons table"
        coupon = data[0]
        assert coupon["code"] == "5555", f"Expected code 5555, got {coupon['code']}"
        assert coupon["is_active"] is True, "Coupon 5555 is not active"
        assert float(coupon["discount_value"]) == 15.0, f"Expected 15.0% discount, got {coupon['discount_value']}"
        assert float(coupon["min_order_amount"]) == 0.0, f"Expected min order 0.0, got {coupon['min_order_amount']}"

def test_rpc_validate_coupon_calculation():
    payload = json.dumps({"p_code": "5555", "p_subtotal": 200.0}).encode("utf-8")
    req = urllib.request.Request(
        f"{POSTGREST_URL}/rpc/validate_coupon",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=5) as res:
        data = json.loads(res.read().decode())
        assert data.get("valid") is True, f"RPC returned valid=False: {data}"
        assert data.get("code") == "5555", f"Expected code 5555, got {data.get('code')}"
        # 15% of 200 = 30.00
        assert float(data.get("calculated_discount")) == 30.0, f"Expected 30.0, got {data.get('calculated_discount')}"

def test_rpc_validate_coupon_capped_at_max_discount():
    # Max discount is 50.0. 15% of 1000 = 150, should cap at 50.0
    payload = json.dumps({"p_code": "5555", "p_subtotal": 1000.0}).encode("utf-8")
    req = urllib.request.Request(
        f"{POSTGREST_URL}/rpc/validate_coupon",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=5) as res:
        data = json.loads(res.read().decode())
        assert data.get("valid") is True, f"RPC returned valid=False: {data}"
        assert float(data.get("calculated_discount")) == 50.0, f"Expected 50.0 capped discount, got {data.get('calculated_discount')}"

def test_rpc_validate_coupon_small_cart():
    # Subtotal 10.0. 15% of 10 = 1.50
    payload = json.dumps({"p_code": "5555", "p_subtotal": 10.0}).encode("utf-8")
    req = urllib.request.Request(
        f"{POSTGREST_URL}/rpc/validate_coupon",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=5) as res:
        data = json.loads(res.read().decode())
        assert data.get("valid") is True, f"Expected valid=True for small cart, got {data}"
        assert float(data.get("calculated_discount")) == 1.5, f"Expected 1.5, got {data.get('calculated_discount')}"

def test_proxy_route_coupon_resolution():
    req = urllib.request.Request(f"{PROXY_URL}/coupons?code=eq.5555")
    with urllib.request.urlopen(req, timeout=5) as res:
        data = json.loads(res.read().decode())
        assert len(data) >= 1, "Coupon 5555 not reachable via proxy port 5173"
        assert data[0]["code"] == "5555"

def test_admin_mutation_rls_authorization():
    # Verify upsert with authenticated staff token works cleanly (0% RLS 42501 rejections)
    payload = json.dumps({
        "id": "ca000000-0000-0000-0000-000000005555",
        "code": "5555",
        "discount_type": "percentage",
        "discount_value": 15.0,
        "min_order_amount": 0.0,
        "max_discount": 50.0,
        "is_active": True
    }).encode("utf-8")
    
    req = urllib.request.Request(
        f"{PROXY_URL}/coupons",
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {ADMIN_JWT}",
            "Prefer": "resolution=merge-duplicates"
        },
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=5) as res:
        assert res.status in (200, 201, 204), f"Unexpected status {res.status}"

def main():
    print("=" * 70)
    print("🎯 FORENSIC VERIFICATION SUITE: COUPON 5555 & BACKEND INTEGRITY")
    print("=" * 70)
    
    tests = [
        ("Database Verification (Coupon 5555 exists & active)", test_coupon_exists_in_database),
        ("Atomic RPC Calculation (15% on 200 = 30.00)", test_rpc_validate_coupon_calculation),
        ("Atomic RPC Max Discount Ceiling (15% on 1000 capped at 50.00)", test_rpc_validate_coupon_capped_at_max_discount),
        ("Atomic RPC Low Threshold (15% on 10 = 1.50 with 0 minOrder)", test_rpc_validate_coupon_small_cart),
        ("Web Proxy Routing (Port 5173 /rest/v1/coupons?code=eq.5555)", test_proxy_route_coupon_resolution),
        ("Admin RLS Mutation Guard (Zero 42501 Authorization Rejections)", test_admin_mutation_rls_authorization),
    ]

    all_passed = True
    for name, fn in tests:
        if not run_test(name, fn):
            all_passed = False

    print("=" * 70)
    if all_passed:
        print("🎉 ALL 6 FORENSIC COUPON 5555 TESTS PASSED WITH 100% SUCCESS!")
        sys.exit(0)
    else:
        print("⚠️ SOME TESTS FAILED.")
        sys.exit(1)

if __name__ == "__main__":
    main()
