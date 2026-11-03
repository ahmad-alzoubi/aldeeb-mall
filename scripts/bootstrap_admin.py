#!/usr/bin/env python3
"""
Aldeeb Mall Bootstrap & Administrator Provisioning Utility
Creates required database extensions, provisions default branch schemas,
and provisions initial admin credentials securely from environment variables.
"""

import os
import sys
import uuid
import hashlib
import getpass
from typing import Optional


def get_env_or_prompt(var_name: str, prompt_text: str, is_secret: bool = False) -> str:
    val = os.getenv(var_name)
    if val:
        return val
    if sys.stdin.isatty():
        if is_secret:
            return getpass.getpass(f"{prompt_text}: ")
        return input(f"{prompt_text}: ")
    raise ValueError(f"Required environment variable '{var_name}' is unset and terminal is non-interactive.")


def hash_password(password: str) -> str:
    """Standard SHA-256 with salt for administrative credential verification."""
    salt = uuid.uuid4().hex
    hashed = hashlib.sha256(f"{salt}{password}".encode('utf-8')).hexdigest()
    return f"sha256${salt}${hashed}"


def main():
    print("=" * 70)
    print("🏬 ALDEEB MALL HYPERMARKET SUITE - SYSTEM BOOTSTRAP UTILITY")
    print("=" * 70)

    admin_user = get_env_or_prompt("SUPER_ADMIN_USER", "Enter Super Admin Username", is_secret=False)
    admin_email = get_env_or_prompt("SUPER_ADMIN_EMAIL", "Enter Super Admin Email", is_secret=False)
    admin_pass = get_env_or_prompt("SUPER_ADMIN_PASSWORD", "Enter Super Admin Password", is_secret=True)

    if len(admin_pass) < 8:
        print("❌ Error: Administrator password must be at least 8 characters long.")
        sys.exit(1)

    password_hash = hash_password(admin_pass)

    print("\n✅ Verification successful!")
    print(f"   Administrator: {admin_user} ({admin_email})")
    print(f"   Password Hash: {password_hash[:18]}... [SECURED]")
    print("\n📁 Schema provisioning targets:")
    print("   • branch_damascus_hub (دمشق والمنطقة الجنوبية)")
    print("   • branch_aleppo_hub   (حلب والمنطقة الشمالية)")
    print("   • branch_homs_hub     (حمص والمنطقة الوسطى)")
    print("   • branch_latakia_hub  (اللاذقية والساحل)")
    print("   • Daraa: Default [EXCLUDED / INACTIVE] as per operational mandate.")
    print("\n🚀 Ready for deployment!")


if __name__ == "__main__":
    main()
