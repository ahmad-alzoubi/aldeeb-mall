import re

files_to_merge = [
    "supabase/DEPLOY_TO_REMOTE_SUPABASE_ALL_STAFF_AUTH.sql",
    "supabase/migrations/20261104_019_real_inventory_and_movements.sql",
    "supabase/migrations/20261104_025_delivery_zones_and_fulfillment_engine.sql",
    "supabase/migrations/20261104_025_pos_shifts_cashier_and_atomic_checkout.sql",
    "supabase/migrations/20261104_026_fix_pos_and_order_atomic_governance.sql"
]

all_sql = []
all_sql.append("-- ==============================================================================")
all_sql.append("-- ALDEEB MALL PRODUCTION REMOTE SUPABASE MASTER DEPLOYMENT")
all_sql.append("-- Generated for https://ffqjtixxzgmvoxzzmxdy.supabase.co")
all_sql.append("-- ==============================================================================\n")
all_sql.append("CREATE EXTENSION IF NOT EXISTS pgcrypto;\n")

# Remove any auth schema creation since Supabase manages auth
for fpath in files_to_merge:
    with open(fpath, "r", encoding="utf-8") as f:
        content = f.read()
        # Clean out any CREATE SCHEMA auth or DROP SCHEMA auth
        content = re.sub(r'CREATE SCHEMA IF NOT EXISTS auth;?', '', content)
        all_sql.append(f"-- --- START OF {fpath} ---\n" + content + f"\n-- --- END OF {fpath} ---\n")

all_sql.append("""
-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
""")

merged = "\n".join(all_sql)
with open("supabase/DEPLOY_TO_PROD_SUPABASE_COMPLETE_SUITE.sql", "w", encoding="utf-8") as out:
    out.write(merged)

print(f"Successfully created supabase/DEPLOY_TO_PROD_SUPABASE_COMPLETE_SUITE.sql (Length: {len(merged)} characters)")
