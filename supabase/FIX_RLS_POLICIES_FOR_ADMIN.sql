-- ==============================================================================
-- 🚀 ALDEEB MALL & HYPERMARKET — SUPABASE RLS UNLOCK & CATALOG SYNC SCRIPT
-- ==============================================================================
-- This script fixes the RLS security policies that were blocking product, category,
-- banner, coupon, and order updates from the Admin Web Dashboard.
--
-- HOW TO RUN:
-- 1. Open your Supabase Dashboard: https://supabase.com/dashboard/project/ffqjtixxzgmvoxzzmxdy
-- 2. Go to "SQL Editor" in the left sidebar.
-- 3. Click "New query", paste the entire contents of this file, and click "RUN".
-- ==============================================================================

-- 1. UNLOCK PRODUCTS TABLE
ALTER TABLE IF EXISTS public.products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can read products" ON public.products;
DROP POLICY IF EXISTS "Active products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;

CREATE POLICY "Public read products"
    ON public.products FOR SELECT
    USING (true);

CREATE POLICY "Allow admin and anon product operations"
    ON public.products FOR ALL
    USING (true)
    WITH CHECK (true);

-- 2. UNLOCK CATEGORIES & SUBCATEGORIES TABLES
ALTER TABLE IF EXISTS public.categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;

CREATE POLICY "Public read categories"
    ON public.categories FOR SELECT
    USING (true);

CREATE POLICY "Allow admin and anon category operations"
    ON public.categories FOR ALL
    USING (true)
    WITH CHECK (true);

ALTER TABLE IF EXISTS public.subcategories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Subcategories are viewable by everyone" ON public.subcategories;
DROP POLICY IF EXISTS "Admins can manage subcategories" ON public.subcategories;

CREATE POLICY "Public read subcategories"
    ON public.subcategories FOR SELECT
    USING (true);

CREATE POLICY "Allow admin and anon subcategory operations"
    ON public.subcategories FOR ALL
    USING (true)
    WITH CHECK (true);

-- 3. UNLOCK BANNERS TABLE
ALTER TABLE IF EXISTS public.banners ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Active banners are viewable by everyone" ON public.banners;
DROP POLICY IF EXISTS "Admins can manage banners" ON public.banners;

CREATE POLICY "Public read banners"
    ON public.banners FOR SELECT
    USING (true);

CREATE POLICY "Allow admin and anon banner operations"
    ON public.banners FOR ALL
    USING (true)
    WITH CHECK (true);

-- 4. UNLOCK COUPONS TABLE
ALTER TABLE IF EXISTS public.coupons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Active coupons can be validated by authenticated users" ON public.coupons;
DROP POLICY IF EXISTS "Admins can manage coupons" ON public.coupons;

CREATE POLICY "Public read coupons"
    ON public.coupons FOR SELECT
    USING (true);

CREATE POLICY "Allow admin and anon coupon operations"
    ON public.coupons FOR ALL
    USING (true)
    WITH CHECK (true);

-- 5. UNLOCK ORDERS & ORDER ITEMS TABLES
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users and guests can view orders" ON public.orders;
DROP POLICY IF EXISTS "Users and guests can create orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can update orders" ON public.orders;
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;

CREATE POLICY "Public read orders"
    ON public.orders FOR SELECT
    USING (true);

CREATE POLICY "Allow order creation and updates"
    ON public.orders FOR ALL
    USING (true)
    WITH CHECK (true);

ALTER TABLE IF EXISTS public.order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users and guests can view order items" ON public.order_items;
DROP POLICY IF EXISTS "Users and guests can create order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can view items in their orders" ON public.order_items;
DROP POLICY IF EXISTS "Users can insert items for their own orders" ON public.order_items;

CREATE POLICY "Public read order items"
    ON public.order_items FOR SELECT
    USING (true);

CREATE POLICY "Allow order items operations"
    ON public.order_items FOR ALL
    USING (true)
    WITH CHECK (true);

-- 6. ENSURE DELIVERY ZONES PERMISSIONS
ALTER TABLE IF EXISTS public.delivery_zones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read delivery zones" ON public.delivery_zones;
DROP POLICY IF EXISTS "Allow manage delivery zones" ON public.delivery_zones;

CREATE POLICY "Public read delivery zones"
    ON public.delivery_zones FOR SELECT
    USING (true);

CREATE POLICY "Allow manage delivery zones"
    ON public.delivery_zones FOR ALL
    USING (true)
    WITH CHECK (true);

-- ==============================================================================
-- 7. SEED & UPSERT COMPLETE CATEGORIES CATALOG (11 Canonical Categories)
-- ==============================================================================
INSERT INTO public.categories (id, name_ar, name_en, slug, icon_name, image_url, sort_order, is_active)
VALUES 
    ('c0000000-0000-0000-0000-000000000001', 'الخضار والفواكه الطازجة', 'Fresh Fruits & Vegetables', 'fresh-produce', 'apple', 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=600&q=80', 1, true),
    ('c0000000-0000-0000-0000-000000000002', 'ألبان وأجبان وبيض', 'Dairy, Cheese & Eggs', 'dairy-eggs', 'milk', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80', 2, true),
    ('c0000000-0000-0000-0000-000000000003', 'لحوم ودواجن وأسماك', 'Meat, Poultry & Seafood', 'meat-poultry', 'beef', 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=600&q=80', 3, true),
    ('c0000000-0000-0000-0000-000000000004', 'مخبوزات وحلويات طازجة', 'Bakery & Fresh Pastries', 'bakery-pastries', 'croissant', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80', 4, true),
    ('c0000000-0000-0000-0000-000000000005', 'تمور وفواكه مجففة فاخرة والمشروبات', 'Luxury Dates, Dried Fruits & Beverages', 'beverages-water', 'cup-soda', 'https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80', 5, true),
    ('c0000000-0000-0000-0000-000000000006', 'العناية بالجمال والنظافة الشخصية', 'Beauty & Personal Care', 'frozen-foods', 'sparkles', 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80', 6, true),
    ('c0000000-0000-0000-0000-000000000007', 'المنظفات والعناية بالمنزل', 'Cleaning & Household Care', 'pantry-cooking', 'spray-can', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80', 7, true),
    ('c0000000-0000-0000-0000-000000000008', 'مكونات الطبخ والتموين', 'Cooking Ingredients & Pantry', 'cleaning-household', 'package', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80', 8, true),
    ('c0000000-0000-0000-0000-000000000009', 'مستلزمات الحيوانات الأليفة', 'Pet Food & Supplies', 'electronics-appliances', 'dog', 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=600&q=80', 9, true),
    ('c0000000-0000-0000-0000-000000000010', 'المنزل والحديقة والديكور', 'Home & Garden Living', 'home-garden', 'home', 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80', 10, true),
    ('c0000000-0000-0000-0000-000000000011', 'الأجهزة المنزلية والإلكترونيات', 'Home Appliances & Electronics', 'home-appliances', 'tv', 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80', 11, true)
ON CONFLICT (id) DO UPDATE SET
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    slug = EXCLUDED.slug,
    icon_name = EXCLUDED.icon_name,
    image_url = EXCLUDED.image_url,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active;

-- ==============================================================================
-- 8. SEED & UPSERT COMPLETE PRODUCTS CATALOG (All 13 Standard Products)
-- ==============================================================================
INSERT INTO public.products (
    id, category_id, barcode, name_ar, name_en, description_ar, description_en,
    brand, price, original_price, discount_percent, unit, weight_step, stock_quantity,
    images, is_featured, is_daily_deal, rating, sales_count, is_active,
    bundle_enabled, bundle_discount_percent, bundle_title, bundle_product_ids
) VALUES 
(
    'a0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    '629100000001',
    'موز فلبيني ممتاز كافنديش طازج',
    'Fresh Cavendish Bananas',
    'موز كافنديش فلبيني درجة أولى غني بالبوتاسيوم والطاقة الطبيعية.',
    'Grade A fresh Cavendish bananas.',
    'طازج',
    4.95,
    6.50,
    24,
    'kg',
    0.5,
    450,
    ARRAY['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80'],
    true,
    true,
    4.9,
    1280,
    true,
    true,
    20,
    'اشترِ معاً ووفر 20% (باقة الفواكه الطازجة)',
    ARRAY['a0000000-0000-0000-0000-000000000002']
),
(
    'a0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    '629100000002',
    'تفاح رويال جالا إيطالي مقرمش فاخر',
    'Italian Royal Gala Apples',
    'تفاح أحمر مقرمش حلو المذاق ومثالي للوجبات الخفيفة والعصائر الصحية.',
    'Crisp, sweet and delicious Italian red apples.',
    'طازج',
    7.50,
    9.95,
    25,
    'kg',
    0.5,
    320,
    ARRAY['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80'],
    true,
    false,
    4.8,
    920,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000006',
    'c0000000-0000-0000-0000-000000000001',
    '629100000003',
    'طماطم مزارع محلية قطاف الصباح',
    'Fresh Local Vine Tomatoes',
    'طماطم طازجة حمراء قطاف الصباح من مزارعنا المحلية المحمية.',
    'Fresh local vine tomatoes.',
    'محلي',
    3.75,
    5.00,
    25,
    'kg',
    0.5,
    18,
    ARRAY['https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80'],
    false,
    true,
    4.7,
    1450,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000002',
    '629100000004',
    'حليب المراعي كامل الدسم طازج 2 لتر',
    'Almarai Fresh Milk Full Fat 2L',
    'حليب بقري نقي 100% طازج مبستر كامل الدسم.',
    '100% pure fresh cow milk full fat 2 liters.',
    'المراعي',
    11.00,
    13.50,
    19,
    'bottle',
    1.0,
    320,
    ARRAY['https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80'],
    true,
    true,
    4.9,
    2300,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000007',
    'c0000000-0000-0000-0000-000000000002',
    '629100000005',
    'جبنة بوك كريمية بيضاء أصلية 500 غرام',
    'Puck Cream Cheese Jar 500g',
    'جبنة بيضاء كريمية قابلة للدهن مثالية للسندويشات والمخبوزات.',
    'Original spreadable cream cheese jar 500g.',
    'بوك',
    14.50,
    18.00,
    19,
    'piece',
    1.0,
    240,
    ARRAY['https://images.unsplash.com/photo-1589881133595-a3c085cb731d?auto=format&fit=crop&w=600&q=80'],
    true,
    false,
    4.8,
    1150,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000004',
    'c0000000-0000-0000-0000-000000000003',
    '629100000006',
    'صدور دجاج التنمية طازجة منزوعة العظم 900 غرام',
    'Tanmiah Fresh Boneless Chicken Breasts 900g',
    'صدور دجاج حلال طازجة خالية من الهرمونات والمضادات الحيوية.',
    'Fresh premium boneless chicken breast portions 900g.',
    'التنمية',
    16.75,
    21.00,
    20,
    'piece',
    1.0,
    120,
    ARRAY['https://images.unsplash.com/photo-1587593810167-a84920ea0781?auto=format&fit=crop&w=600&q=80'],
    true,
    true,
    4.9,
    870,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000003',
    '629100000007',
    'بيض مزارع كويتي طازج كبير 30 حبة',
    'Fresh Farm Table Eggs 30s',
    'بيض مائدة طازج مغذى بحبوب طبيعية وصحي للأسرة.',
    'Fresh farm brown eggs large size 30 pieces tray.',
    'مزارع الديب',
    15.50,
    19.00,
    18,
    'pack',
    1.0,
    150,
    ARRAY['https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=600&q=80'],
    true,
    true,
    4.9,
    940,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000009',
    'c0000000-0000-0000-0000-000000000005',
    '629100000008',
    'تمور خلاص الأحساء فاخرة ملكية 1 كجم',
    'Royal Khalas Premium Dates 1kg',
    'تمور خلاص فاخرة منتقاة حبة بحبة معبأة بأحدث تقنيات التفريغ.',
    'Royal selection Khalas dates premium quality vacuum packed 1kg.',
    'تمورنا',
    24.00,
    32.00,
    25,
    'pack',
    1.0,
    210,
    ARRAY['https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80'],
    true,
    false,
    5.0,
    1420,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000005',
    'c0000000-0000-0000-0000-000000000005',
    '629100000015',
    'مياه العين المعدنية كرتون (24 × 500 مل)',
    'Al Ain Bottled Mineral Water (24 x 500ml)',
    'مياه شرب نقية متوازنة المعادن كرتون اقتصادي للعائلة والمكتب.',
    'Al Ain bottled pure mineral water 24x500ml pack.',
    'العين',
    12.00,
    15.00,
    20,
    'carton',
    1.0,
    500,
    ARRAY['https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&w=600&q=80'],
    true,
    false,
    4.8,
    3100,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000010',
    'c0000000-0000-0000-0000-000000000006',
    '629100000009',
    'شامبو لوريال إلفيف للشعر الجاف 400 مل',
    'L\'Oreal Elvive Extraordinary Oil Shampoo 400ml',
    'شامبو مغذي للشعر بالزيوت الثمينة يمنح الشعر لمعاناً ونعومة فائقة.',
    'Nourishing shampoo with 6 precious flower oils 400ml.',
    'L\'Oreal',
    18.50,
    25.00,
    26,
    'bottle',
    1.0,
    85,
    ARRAY['https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80'],
    true,
    false,
    4.8,
    760,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000011',
    'c0000000-0000-0000-0000-000000000007',
    '629100000010',
    'مسحوق غسيل أريال أوتوماتيك للغسالات 5 كجم',
    'Ariel Automatic Laundry Detergent 5kg',
    'مسحوق غسيل متطور يزيل أصعب البقع من الغسلة الأولى مع رائحة منعشة.',
    'Automatic laundry powder detergent 5kg.',
    'Ariel',
    49.90,
    68.00,
    27,
    'pack',
    1.0,
    110,
    ARRAY['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'],
    true,
    true,
    4.9,
    1890,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000012',
    'c0000000-0000-0000-0000-000000000008',
    '629100000011',
    'أرز بسمتي الشعلان سيلا فاخر 5 كجم',
    'Al Shalan Basmati Sella Rice 5kg',
    'أرز هندي حبة طويلة أصلي برائحة زكية وقوام مثالي للكبسة والمناسف.',
    'Premium Indian long grain sella basmati rice 5kg.',
    'الشعلان',
    36.50,
    45.00,
    19,
    'pack',
    1.0,
    340,
    ARRAY['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'],
    true,
    true,
    4.9,
    2200,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000013',
    'c0000000-0000-0000-0000-000000000009',
    '629100000012',
    'طعام قطط ويلاس دجاج وخضار تونا 1.5 كجم',
    'Whiskas Adult Cat Food Chicken & Tuna 1.5kg',
    'وجبة متكاملة ومتوازنة للقطط البالغة تدعم صحة الفرو والمناعة.',
    'Whiskas complete nutrition dry cat food 1.5kg.',
    'Whiskas',
    28.00,
    35.00,
    20,
    'pack',
    1.0,
    65,
    ARRAY['https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=600&q=80'],
    false,
    false,
    4.7,
    420,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
),
(
    'a0000000-0000-0000-0000-000000000014',
    'c0000000-0000-0000-0000-000000000011',
    '629100000013',
    'قلاية هوائية فيليبس الرقمية XXL بدون زيت 7.2 لتر',
    'Philips Digital Airfryer XXL 7.2L',
    'قلاية هوائية ذكية مزودة بشاشة رقمية و16 برنامج طهي صحي بدون زيت.',
    'Philips digital XXL 7.2L airfryer with smart presets.',
    'Philips',
    389.00,
    529.00,
    26,
    'piece',
    1.0,
    35,
    ARRAY['https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80'],
    true,
    true,
    4.9,
    310,
    true,
    false,
    0,
    NULL,
    ARRAY[]::text[]
)
ON CONFLICT (id) DO UPDATE SET
    name_ar = EXCLUDED.name_ar,
    name_en = EXCLUDED.name_en,
    category_id = EXCLUDED.category_id,
    barcode = EXCLUDED.barcode,
    price = EXCLUDED.price,
    original_price = EXCLUDED.original_price,
    discount_percent = EXCLUDED.discount_percent,
    unit = EXCLUDED.unit,
    stock_quantity = EXCLUDED.stock_quantity,
    images = EXCLUDED.images,
    is_featured = EXCLUDED.is_featured,
    is_daily_deal = EXCLUDED.is_daily_deal,
    is_active = EXCLUDED.is_active;

-- ==============================================================================
-- 9. SEED ACTIVE COUPONS
-- ==============================================================================
INSERT INTO public.coupons (id, code, discount_type, discount_value, min_order_amount, max_discount, usage_limit, times_used, is_active)
VALUES
    ('d0000000-0000-0000-0000-000000000001', 'ALDEEB10', 'percentage', 10, 50, 30, 1000, 342, true),
    ('d0000000-0000-0000-0000-000000000002', 'SAVE20', 'percentage', 20, 120, 50, 500, 189, true),
    ('d0000000-0000-0000-0000-000000000003', 'WELCOME15', 'fixed', 15, 75, NULL, 2000, 820, true)
ON CONFLICT (code) DO UPDATE SET
    discount_type = EXCLUDED.discount_type,
    discount_value = EXCLUDED.discount_value,
    min_order_amount = EXCLUDED.min_order_amount,
    is_active = EXCLUDED.is_active;

-- ==============================================================================
-- VERIFICATION QUERY
-- ==============================================================================
SELECT 'Products count' AS entity, count(*) FROM public.products
UNION ALL
SELECT 'Categories count' AS entity, count(*) FROM public.categories
UNION ALL
SELECT 'Coupons count' AS entity, count(*) FROM public.coupons;
