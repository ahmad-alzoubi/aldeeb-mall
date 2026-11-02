import re

with open('aldeeb_mall_app/lib/core/services/supabase_service.dart', 'r', encoding='utf-8') as f:
    dart_code = f.read()

cat_map = {
    'c1': 'c0000000-0000-0000-0000-000000000001',
    'c2': 'c0000000-0000-0000-0000-000000000002',
    'c3': 'c0000000-0000-0000-0000-000000000003',
    'c4': 'c0000000-0000-0000-0000-000000000004',
    'c5': 'c0000000-0000-0000-0000-000000000005',
    'c6': 'c0000000-0000-0000-0000-000000000006',
    'c7': 'c0000000-0000-0000-0000-000000000007',
    'c8': 'c0000000-0000-0000-0000-000000000008',
    'c9': 'c0000000-0000-0000-0000-000000000009',
    'c10': 'c0000000-0000-0000-0000-000000000010',
    'c11': 'c0000000-0000-0000-0000-000000000011',
}

pattern = re.compile(r'ProductModel\((.*?)\),', re.DOTALL)
block = dart_code[dart_code.find('static final List<ProductModel> _defaultProducts = ['):]
block = block[:block.find('  ];\n\n  // Active/Cached Products in Memory')]

items = pattern.findall(block)

rows = []
for idx, it in enumerate(items, 1):
    id_m = re.search(r"id:\s*'([^']+)'", it)
    cat_m = re.search(r"categoryId:\s*'([^']+)'", it)
    name_ar_m = re.search(r"nameAr:\s*'([^']+)'", it)
    name_en_m = re.search(r"nameEn:\s*'([^']+)'", it)
    desc_ar_m = re.search(r"descriptionAr:\s*'([^']+)'", it)
    brand_m = re.search(r"brand:\s*'([^']+)'", it)
    price_m = re.search(r"price:\s*([0-9.]+)", it)
    orig_price_m = re.search(r"originalPrice:\s*([0-9.]+)", it)
    disc_m = re.search(r"discountPercent:\s*([0-9]+)", it)
    unit_m = re.search(r"unit:\s*'([^']+)'", it)
    weight_m = re.search(r"weightStep:\s*([0-9.]+)", it)
    stock_m = re.search(r"stockQuantity:\s*([0-9]+)", it)
    img_m = re.findall(r"'https://[^']+'", it)
    is_feat_m = re.search(r"isFeatured:\s*(true|false)", it)
    is_deal_m = re.search(r"isDailyDeal:\s*(true|false)", it)

    short_id = id_m.group(1) if id_m else f'p{idx}'
    uuid_str = f'a0000000-0000-0000-0000-{idx:012d}'
    cat_id = cat_map.get(cat_m.group(1), 'c0000000-0000-0000-0000-000000000001') if cat_m else 'c0000000-0000-0000-0000-000000000001'
    name_ar = name_ar_m.group(1).replace("'", "''") if name_ar_m else 'منتج'
    name_en = name_en_m.group(1).replace("'", "''") if name_en_m else 'Product'
    desc_ar = desc_ar_m.group(1).replace("'", "''") if desc_ar_m else ''
    brand = brand_m.group(1).replace("'", "''") if brand_m else 'الديب'
    price = float(price_m.group(1)) if price_m else 10.0
    orig_price = float(orig_price_m.group(1)) if orig_price_m else price
    disc = int(disc_m.group(1)) if disc_m else 0
    unit = unit_m.group(1) if unit_m else 'piece'
    weight = float(weight_m.group(1)) if weight_m else 1.0
    stock = int(stock_m.group(1)) if stock_m else 100
    images = ', '.join(img_m) if img_m else "'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600'"
    is_feat = is_feat_m.group(1) if is_feat_m else 'false'
    is_deal = is_deal_m.group(1) if is_deal_m else 'false'
    barcode = f'62910000{idx:04d}'

    sql_row = f"(\n    '{uuid_str}', '{cat_id}', '{barcode}', '{name_ar}', '{name_en}', '{desc_ar}', '{brand}', {price:.2f}, {orig_price:.2f}, {disc}, '{unit}', {weight:.2f}, {stock}, ARRAY[{images}], {is_feat}, {is_deal}, 4.8, 150\n  )"
    rows.append(sql_row)

upsert_block = """
-- ==============================================================================
-- Full Comprehensive 34-Product Seed Dataset (Clean Upsert)
-- ==============================================================================
INSERT INTO public.products (
    id, category_id, barcode, name_ar, name_en, description_ar, brand, price, original_price, discount_percent, unit, weight_step, stock_quantity, images, is_featured, is_daily_deal, rating, sales_count
) VALUES
""" + ",\n".join(rows) + """
ON CONFLICT (id) DO UPDATE SET
    category_id = EXCLUDED.category_id,
    barcode = EXCLUDED.barcode,
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    description_ar = EXCLUDED.description_ar,
    brand = EXCLUDED.brand,
    price = EXCLUDED.price,
    original_price = EXCLUDED.original_price,
    discount_percent = EXCLUDED.discount_percent,
    unit = EXCLUDED.unit,
    weight_step = EXCLUDED.weight_step,
    stock_quantity = EXCLUDED.stock_quantity,
    images = EXCLUDED.images,
    is_featured = EXCLUDED.is_featured,
    is_daily_deal = EXCLUDED.is_daily_deal;
"""

with open('supabase/PRODUCTION_MASTER_DEPLOYMENT.sql', 'a', encoding='utf-8') as f:
    f.write("\n\n" + upsert_block)

print(f"Appended {len(rows)} products to PRODUCTION_MASTER_DEPLOYMENT.sql successfully!")
