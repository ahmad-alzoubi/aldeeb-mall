-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Expanded Catalog, Categories, and Banners
-- Migration 006: Dates, Appliances, Beauty, Pets, Moving Hero & Secondary Banners
-- ==============================================================================

-- 1. Insert/Update Categories
INSERT INTO public.categories (id, name_ar, name_en, slug, icon_name, image_url, sort_order) VALUES
('c0000000-0000-0000-0000-000000000005', 'تمور وفواكه مجففة فاخرة', 'Luxury Dates & Dried Fruits', 'dates-fruits', 'palm_tree', 'https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80', 5),
('c0000000-0000-0000-0000-000000000006', 'العناية بالجمال والنظافة الشخصية', 'Beauty & Personal Care', 'beauty-care', 'sparkles', 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80', 6),
('c0000000-0000-0000-0000-000000000007', 'المنظفات والعناية بالمنزل', 'Cleaning & Household Care', 'cleaning-household', 'spray-can', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80', 7),
('c0000000-0000-0000-0000-000000000008', 'مكونات الطبخ والتموين', 'Cooking Ingredients & Pantry', 'cooking-pantry', 'chef-hat', 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80', 8),
('c0000000-0000-0000-0000-000000000009', 'مستلزمات الحيوانات الأليفة', 'Pet Food & Supplies', 'pet-supplies', 'dog', 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=600&q=80', 9),
('c0000000-0000-0000-0000-000000000010', 'المنزل والحديقة والديكور', 'Home & Garden Living', 'home-garden', 'home', 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80', 10),
('c0000000-0000-0000-0000-000000000011', 'الأجهزة المنزلية والإلكترونيات', 'Home Appliances & Electronics', 'home-appliances', 'tv', 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80', 11)
ON CONFLICT (id) DO UPDATE SET 
  name_ar = EXCLUDED.name_ar, 
  name_en = EXCLUDED.name_en, 
  image_url = EXCLUDED.image_url;

-- 2. Insert Hero & Secondary Promotional Banners
INSERT INTO public.banners (id, title_ar, title_en, subtitle_ar, subtitle_en, image_url, target_type, target_id, badge_ar, sort_order, is_active) VALUES
('b0000000-0000-0000-0000-000000000001', 'مهرجان الصفقات الكبرى في الديب مول 🛒', 'Mega Supermarket Savings Festival', 'خصومات حصرية تصل إلى 50% على المواد الغذائية والتموينية', 'Up to 50% OFF on essentials', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80', 'deal', NULL, 'خصم حتى 50%', 1, true),
('b0000000-0000-0000-0000-000000000002', 'سوق الخضار والفواكه الطازجة قطاف اليوم 🍎', 'Fresh Daily Produce Market', 'من المزرعة إلى مائدتك بتوصيل فوري مبرد وسريع', 'Fresh morning harvest delivered chilled', 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=1200&q=80', 'category', 'c0000000-0000-0000-0000-000000000001', 'طازج يومياً', 2, true),
('b0000000-0000-0000-0000-000000000003', 'عروض الأسبوع التوفيرية للمنزل والأسرة 🌟', 'Mega Weekly Family Deals', 'تخفيضات كبرى على منتجات الألبان، اللحوم، والمؤن', 'Special prices on groceries', 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=1200&q=80', 'deal', NULL, 'عروض الأسبوع', 3, true),
('b0000000-0000-0000-0000-000000000004', 'توصيل فوري إكسبريس مجاني خلال 60 دقيقة 🛵', 'Express 60-Minute Fast Delivery', 'اطلب مستلزمات بيتك واستلمها على بابك مجاناً فوق 100 ر.س', 'Free delivery on orders above 100 SAR', 'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=1200&q=80', 'deal', NULL, 'سريع ومضمون', 4, true),
('b0000000-0000-0000-0000-000000000005', 'مهرجان التمور الملكية والبن الفاخر 🌴', 'Royal Dates & Specialty Coffee Fest', 'أجود تمور سكري وخلاص مع خصم إضافي 20% عند شراء عبوتين', 'Buy 2 Get 20% Extra OFF', 'https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=1200&q=80', 'category', 'c0000000-0000-0000-0000-000000000005', 'إعلان فاصل 1', 5, true),
('b0000000-0000-0000-0000-000000000006', 'عروض الأجهزة المنزلية وقلايات الهواء الذكية ⚡', 'Smart Appliances & Airfryer Mega Sale', 'وفّر حتى 300 ر.س مع ضمان سنتين صيانة معتمدة شاملة', 'Save up to 300 SAR with 2yr warranty', 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=1200&q=80', 'category', 'c0000000-0000-0000-0000-000000000011', 'إعلان فاصل 2', 6, true)
ON CONFLICT (id) DO UPDATE SET 
  title_ar = EXCLUDED.title_ar,
  image_url = EXCLUDED.image_url,
  badge_ar = EXCLUDED.badge_ar;

-- 3. Insert Additional Hypermarket Products
INSERT INTO public.products (
    id, category_id, barcode, name_ar, name_en, description_ar, brand, price, original_price, discount_percent, unit, weight_step, stock_quantity, images, is_featured, is_daily_deal, rating, sales_count
) VALUES
(
    'p0000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000005',
    '629100000008',
    'تمور خلاص الأحساء فاخرة ملكية 1 كجم',
    'Royal Khalas Premium Dates 1kg',
    'تمور خلاص سعودية منتقاة حبة بحبة، معبأة بعناية وحلوة المذاق وغنية بالألياف الطبيعية.',
    'تمورنا',
    24.00, 32.00, 25,
    'pack', 1.0, 210,
    ARRAY['https://images.unsplash.com/photo-1596707328406-8c4c7943c2c5?auto=format&fit=crop&w=600&q=80'],
    true, false, 5.0, 1420
),
(
    'p0000000-0000-0000-0000-000000000009',
    'c0000000-0000-0000-0000-000000000006',
    '629100000009',
    'شامبو لوريال إلفيف للشعر الجاف 400 مل',
    'L''Oreal Elvive Extraordinary Oil Shampoo 400ml',
    'شامبو مغذي بزيوت الزهور النادرة لتغذية الشعر من الجذور حتى الأطراف ولمعان لا يضاهى.',
    'L''Oreal',
    18.50, 25.00, 26,
    'bottle', 1.0, 85,
    ARRAY['https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.8, 760
),
(
    'p0000000-0000-0000-0000-000000000010',
    'c0000000-0000-0000-0000-000000000007',
    '629100000010',
    'مسحوق غسيل أريال أوتوماتيك للغسالات 5 كجم',
    'Ariel Automatic Laundry Detergent 5kg',
    'مسحوق غسيل المركز يزيل أصعب البقع من أول غسلة ويمنح الملابس انتعاشاً يدوم طويلاً.',
    'Ariel',
    49.90, 68.00, 27,
    'pack', 1.0, 110,
    ARRAY['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 1890
),
(
    'p0000000-0000-0000-0000-000000000011',
    'c0000000-0000-0000-0000-000000000008',
    '629100000011',
    'أرز بسمتي الشعلان سيلا فاخر 5 كجم',
    'Al Shalan Basmati Sella Rice 5kg',
    'أرز بسمتي أبيض حبة طويلة ونكهة أصيلة، مثالي للكبسة والأطباق الخليجية والمناسف.',
    'الشعلان',
    36.50, 45.00, 19,
    'pack', 1.0, 340,
    ARRAY['https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 2200
),
(
    'p0000000-0000-0000-0000-000000000012',
    'c0000000-0000-0000-0000-000000000009',
    '629100000012',
    'طعام قطط ويلاس دجاج وتونة وخضار 1.5 كجم',
    'Whiskas Adult Cat Food Chicken & Tuna 1.5kg',
    'وجبة متوازنة ومحببة للقطط غنية بالبروتينات وأوميغا 3 لدعم صحة الفرو والمناعة.',
    'Whiskas',
    28.00, 35.00, 20,
    'pack', 1.0, 65,
    ARRAY['https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=600&q=80'],
    false, false, 4.7, 420
),
(
    'p0000000-0000-0000-0000-000000000013',
    'c0000000-0000-0000-0000-000000000011',
    '629100000013',
    'قلاية هوائية رقمية فيليبس XXL بدون زيت 7.2 لتر',
    'Philips Digital Airfryer XXL 7.2L',
    'قلاية صحية بدون زيت بتقنية الهواء الساخن السريع وسعة عائلية مع شاشة لمس وبرامج متعددة.',
    'Philips',
    389.00, 529.00, 26,
    'piece', 1.0, 35,
    ARRAY['https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 310
)
ON CONFLICT (id) DO UPDATE SET 
  name_ar = EXCLUDED.name_ar,
  price = EXCLUDED.price,
  discount_percent = EXCLUDED.discount_percent;
