-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Realistic Hypermarket Seed Data
-- Migration 004: Carrefour-style Categories, Subcategories, Products, Banners, Coupons
-- ==============================================================================

-- 1. Insert Categories
INSERT INTO public.categories (id, name_ar, name_en, slug, icon_name, image_url, sort_order) VALUES
('c0000000-0000-0000-0000-000000000001', 'خضار وفواكه طازجة', 'Fresh Fruits & Vegetables', 'fresh-produce', 'apple', 'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=600&q=80', 1),
('c0000000-0000-0000-0000-000000000002', 'ألبان وأجبان وبيض', 'Dairy, Cheese & Eggs', 'dairy-eggs', 'milk', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80', 2),
('c0000000-0000-0000-0000-000000000003', 'لحوم ودواجن وأسماك', 'Meat, Poultry & Seafood', 'meat-poultry', 'beef', 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=600&q=80', 3),
('c0000000-0000-0000-0000-000000000004', 'مخبوزات وحلويات طازجة', 'Bakery & Fresh Pastries', 'bakery-pastries', 'croissant', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80', 4),
('c0000000-0000-0000-0000-000000000005', 'مشروبات وعصائر ومياه', 'Beverages & Juices', 'beverages-water', 'cup-soda', 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80', 5),
('c0000000-0000-0000-0000-000000000006', 'أغذية مثلجة ومجمدات', 'Frozen Foods & Ice Cream', 'frozen-foods', 'snowflake', 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=600&q=80', 6),
('c0000000-0000-0000-0000-000000000007', 'معلبات ومؤن وطهي', 'Pantry & Canned Goods', 'pantry-cooking', 'package', 'https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?auto=format&fit=crop&w=600&q=80', 7),
('c0000000-0000-0000-0000-000000000008', 'منظفات وعناية منزلية', 'Cleaning & Household', 'cleaning-household', 'sparkles', 'https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80', 8),
('c0000000-0000-0000-0000-000000000009', 'أجهزة وإلكترونيات', 'Electronics & Appliances', 'electronics-appliances', 'tv', 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=600&q=80', 9)
ON CONFLICT (id) DO NOTHING;

-- 2. Insert Subcategories
INSERT INTO public.subcategories (id, category_id, name_ar, name_en, slug, sort_order) VALUES
('ba000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'فواكه طازجة', 'Fresh Fruits', 'fruits', 1),
('ba000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'خضار ورقية وجذرية', 'Vegetables', 'vegetables', 2),
('ba000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000002', 'حليب ولبن رائب', 'Milk & Laban', 'milk-laban', 1),
('ba000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000002', 'أجبان وزبدة وقشطة', 'Cheese & Butter', 'cheese-butter', 2),
('ba000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000003', 'دواجن طازجة ومجمدة', 'Fresh Poultry', 'poultry', 1),
('ba000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000003', 'لحوم بقر وضأن', 'Beef & Mutton', 'red-meat', 2),
('ba000000-0000-0000-0000-000000000007', 'c0000000-0000-0000-0000-000000000004', 'خبز وتوست طازج', 'Bread & Buns', 'bread-toast', 1),
('ba000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000005', 'مياه معدنية طبيعية', 'Mineral Water', 'water', 1),
('ba000000-0000-0000-0000-000000000009', 'c0000000-0000-0000-0000-000000000005', 'عصائر طازجة وطبيعية', 'Fresh Juices', 'juices', 2),
('ba000000-0000-0000-0000-000000000010', 'c0000000-0000-0000-0000-000000000008', 'مساحيق ومنعمات الغسيل', 'Laundry Care', 'laundry', 1)
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Products
INSERT INTO public.products (
    id, category_id, subcategory_id, barcode, name_ar, name_en, 
    description_ar, description_en, brand, price, original_price, discount_percent, 
    unit, weight_step, stock_quantity, images, is_featured, is_daily_deal, rating, sales_count
) VALUES
-- Fruits & Veg
(
    'a0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'ba000000-0000-0000-0000-000000000001',
    '629100000001',
    'موز فلبيني ممتاز كافنديش طازج',
    'Fresh Premium Cavendish Bananas',
    'موز طازج ومغذي غني بالبوتاسيوم والطاقة، مستورد يومياً من مزارع الفلبين الممتازة.',
    'Sweet and energy-packed fresh bananas imported directly from top farms.',
    'طازج',
    4.95, 6.50, 24,
    'kg', 0.50, 450,
    ARRAY['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 1280
),
(
    'a0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'ba000000-0000-0000-0000-000000000001',
    '629100000002',
    'تفاح رويال جالا إيطالي فاخر',
    'Italian Royal Gala Apples',
    'تفاح إيطالي مقرمش ولذيذ وحلو المذاق، مثالي لوجبات الأطفال الخفيفة وسلطات الفواكه.',
    'Crisp, sweet, and juicy fresh Gala apples directly from Italian orchards.',
    'طازج',
    7.50, 9.95, 25,
    'kg', 0.50, 300,
    ARRAY['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.8, 920
),
(
    'a0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000001',
    'ba000000-0000-0000-0000-000000000002',
    '629100000003',
    'طماطم مزارع محلية طازجة قطاف اليوم',
    'Fresh Local Vine Tomatoes',
    'طماطم حمراء نضرة وممتلئة تم قطافها صباح اليوم، ممتازة للطبخ والسلطات.',
    'Fresh red juicy vine-ripened tomatoes picked this morning from local farms.',
    'محلي',
    3.75, 5.00, 25,
    'kg', 0.50, 500,
    ARRAY['https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80'],
    false, true, 4.7, 1450
),

-- Dairy & Eggs
(
    'a0000000-0000-0000-0000-000000000004',
    'c0000000-0000-0000-0000-000000000002',
    'ba000000-0000-0000-0000-000000000003',
    '629100000004',
    'حليب المراعي طازج كامل الدسم 2 لتر',
    'Almarai Fresh Full Fat Milk 2L',
    'حليب بقري نقي 100% طازج كامل الدسم معزز بفيتامين د والكالسيوم لجميع أفراد الأسرة.',
    '100% pure fresh cow milk full cream rich in Calcium and Vitamin D.',
    'المراعي',
    11.00, 13.50, 19,
    'bottle', 1.0, 320,
    ARRAY['https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 2100
),
(
    'a0000000-0000-0000-0000-000000000005',
    'c0000000-0000-0000-0000-000000000002',
    'ba000000-0000-0000-0000-000000000004',
    '629100000005',
    'جبنة بوك كاسات بيضاء كريمية 500 غرام',
    'Puck Cream Cheese Spread 500g',
    'جبنة قابلة للدهن ناعمة وكريمية وغنية بالنكهة المحبوبة لإفطار مثالي كل صباح.',
    'Rich and smooth cream cheese spread jar loved by kids and adults.',
    'بوك',
    14.50, 18.00, 19,
    'piece', 1.0, 240,
    ARRAY['https://images.unsplash.com/photo-1589881133595-a3c085cb731d?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.8, 1150
),

-- Meat & Poultry
(
    'a0000000-0000-0000-0000-000000000006',
    'c0000000-0000-0000-0000-000000000003',
    'ba000000-0000-0000-0000-000000000005',
    '629100000006',
    'دجاج التنمية طازج مبرد 1000 غرام',
    'Tanmiah Fresh Chilled Whole Chicken 1000g',
    'دجاج طازج محلي مذبوح وفق الشريعة الإسلامية حلال 100% ومبرد دون هرمونات.',
    'Fresh local premium farm chicken 100% Halal certified.',
    'التنمية',
    16.75, 21.00, 20,
    'piece', 1.0, 180,
    ARRAY['https://images.unsplash.com/photo-1587593810167-a84920ea0781?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 870
),

-- Bakery
(
    'a0000000-0000-0000-0000-000000000007',
    'c0000000-0000-0000-0000-000000000004',
    'ba000000-0000-0000-0000-000000000007',
    '629100000007',
    'خبز كرواسان فرنسي طازج بالزبدة (4 قطع)',
    'Fresh Butter French Croissants (Pack of 4)',
    'مخبوز بالزبدة الطبيعية الفاخرة بطبقات هشة ومقرمشة يخبز طازجاً عدة مرات يومياً.',
    'Flaky, golden, and authentic butter croissants baked fresh multiple times daily.',
    'مخبز الديب',
    8.50, 11.00, 23,
    'pack', 1.0, 120,
    ARRAY['https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.9, 1340
),

-- Beverages
(
    'a0000000-0000-0000-0000-000000000008',
    'c0000000-0000-0000-0000-000000000005',
    'ba000000-0000-0000-0000-000000000008',
    '629100000008',
    'مياه معدنية العين كرتون (24 عبوة × 500 مل)',
    'Al Ain Mineral Water Carton (24 x 500ml)',
    'مياه شرب نقية متوازنة المعادن والصوديوم، معبأة بأعلى معايير النقاء.',
    'Pure natural bottled drinking water carton with low sodium balance.',
    'العين',
    12.95, 17.50, 26,
    'carton', 1.0, 600,
    ARRAY['https://images.unsplash.com/photo-1527661591475-527312dd65f5?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 3400
),

-- Cleaning & Household
(
    'a0000000-0000-0000-0000-000000000009',
    'c0000000-0000-0000-0000-000000000008',
    'ba000000-0000-0000-0000-000000000010',
    '629100000009',
    'مسحوق غسيل تايد الأصلي الأوتوماتيكي 5 كجم',
    'Tide Original Automatic Washing Powder 5kg',
    'نظافة ناصعة وبياض باهر وإزالة أصعب البقع من الغسلة الأولى مع رائحة منعشة تدوم.',
    'Deep stain removal for automatic washing machines with long-lasting freshness.',
    'تايد',
    42.00, 58.00, 28,
    'pack', 1.0, 210,
    ARRAY['https://images.unsplash.com/photo-1585421514738-01798e348b17?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.8, 1500
)
ON CONFLICT (id) DO NOTHING;

-- 4. Insert Banners
INSERT INTO public.banners (id, title_ar, title_en, subtitle_ar, subtitle_en, image_url, target_type, badge_ar, sort_order) VALUES
(
    'b0000000-0000-0000-0000-000000000001',
    'مهرجان التوفير الضخم والصفقات الكبرى',
    'Mega Supermarket Savings Festival',
    'خصومات تصل إلى 50% على آلاف المنتجات الطازجة والمؤن',
    'Up to 50% OFF on fresh groceries and daily essentials',
    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
    'deal',
    'خصم حتى 50%',
    1
),
(
    'b0000000-0000-0000-0000-000000000002',
    'سوق الخضار والفواكه الطازجة اليومية',
    'Fresh Daily Market',
    'من المزرعة إلى مائدتك مباشرة بتوصيل مبرد وسريع',
    'From direct farm harvest to your table chilled and fresh',
    'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=1200&q=80',
    'category',
    'طازج كل صباح',
    2
),
(
    'b0000000-0000-0000-0000-000000000003',
    'توصيل فوري سريع خلال 60 دقيقة',
    'Express 60-Min Delivery',
    'اطلب كل ما يلزم منزلك واستلمه على بابك بأسرع وقت',
    'Order home needs and get them delivered at your doorstep',
    'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=1200&q=80',
    'external',
    'إكسبريس سريع',
    3
)
ON CONFLICT (id) DO NOTHING;

-- 5. Insert Coupons
INSERT INTO public.coupons (id, code, discount_type, discount_value, min_order_amount, max_discount, usage_limit, is_active) VALUES
('ca000000-0000-0000-0000-000000000001', 'ALDEEB10', 'percentage', 10.00, 50.00, 30.00, 1000, true),
('ca000000-0000-0000-0000-000000000002', 'SAVE20', 'percentage', 20.00, 120.00, 50.00, 500, true),
('ca000000-0000-0000-0000-000000000003', 'WELCOME15', 'fixed', 15.00, 75.00, 15.00, 2000, true)
ON CONFLICT (id) DO NOTHING;
