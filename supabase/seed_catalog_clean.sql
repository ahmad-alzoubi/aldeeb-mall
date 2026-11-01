-- ==============================================================================
-- Aldeeb Mall - Clean Valid Hex UUID Seed Data
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
('b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'فواكه طازجة', 'Fresh Fruits', 'fruits', 1),
('b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'خضار ورقية وجذرية', 'Vegetables', 'vegetables', 2),
('b0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000002', 'حليب ولبن رائب', 'Milk & Laban', 'milk-laban', 1),
('b0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000002', 'أجبان وزبدة وقشطة', 'Cheese & Butter', 'cheese-butter', 2),
('b0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000003', 'دواجن طازجة ومجمدة', 'Fresh Poultry', 'poultry', 1),
('b0000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000003', 'لحوم بقر وضأن', 'Beef & Mutton', 'red-meat', 2),
('b0000000-0000-0000-0000-000000000007', 'c0000000-0000-0000-0000-000000000004', 'خبز وتوست طازج', 'Bread & Buns', 'bread-toast', 1),
('b0000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000005', 'مياه معدنية طبيعية', 'Mineral Water', 'water', 1),
('b0000000-0000-0000-0000-000000000009', 'c0000000-0000-0000-0000-000000000005', 'عصائر طازجة وطبيعية', 'Fresh Juices', 'juices', 2),
('b0000000-0000-0000-0000-000000000010', 'c0000000-0000-0000-0000-000000000008', 'مساحيق ومنعمات الغسيل', 'Laundry Care', 'laundry', 1)
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Products
INSERT INTO public.products (
    id, category_id, subcategory_id, barcode, name_ar, name_en, 
    description_ar, description_en, brand, price, original_price, discount_percent, 
    unit, weight_step, stock_quantity, images, is_featured, is_daily_deal, rating, sales_count
) VALUES
(
    'a0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    '629100000001',
    'موز فلبيني ممتاز كافنديش طازج',
    'Fresh Premium Cavendish Bananas',
    'موز طازج ومغذي غني بالبوتاسيوم والطاقة، مستورد يومياً من مزارع الفلبين الممتازة.',
    'Sweet and energy-packed fresh bananas imported directly from top farms.',
    'طازج',
    4.95, 6.50, 24,
    'kg', 0.5, 450,
    ARRAY['https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 1280
),
(
    'a0000000-0000-0000-0000-000000000002',
    'c0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    '629100000002',
    'تفاح رويال جالا إيطالي مقرمش فاخر',
    'Italian Royal Gala Apples',
    'تفاح أحمر مقرمش حلو المذاق ومثالي للوجبات الخفيفة والعصائر الصحية.',
    'Crisp, sweet and delicious Italian red apples.',
    'طازج',
    7.50, 9.95, 25,
    'kg', 0.5, 320,
    ARRAY['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.8, 850
),
(
    'a0000000-0000-0000-0000-000000000003',
    'c0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000003',
    '629100000003',
    'حليب المراعي كامل الدسم طازج 2 لتر',
    'Almarai Fresh Full Fat Milk 2L',
    'حليب بقري نقي 100% مدعم بفيتامين د وأ، طازج من المزرعة إلى مائدتك يومياً.',
    'Pure cow fresh milk rich in calcium and vitamins.',
    'المراعي',
    11.00, 11.00, 0,
    'piece', 1.0, 600,
    ARRAY['https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=600&q=80'],
    true, false, 4.9, 3420
),
(
    'a0000000-0000-0000-0000-000000000004',
    'c0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000005',
    '629100000004',
    'صدور دجاج التنمية طازجة منزوعة العظم 900 غرام',
    'Al Tanmiah Fresh Chicken Breasts 900g',
    'صدور دجاج محلية طازجة بدون عظم أو جلد، خالية من الهرمونات والمضادات الحيوية.',
    'Premium tender boneless and skinless fresh chicken breasts.',
    'التنمية',
    28.50, 34.00, 16,
    'piece', 1.0, 180,
    ARRAY['https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 1150
),
(
    'a0000000-0000-0000-0000-000000000005',
    'c0000000-0000-0000-0000-000000000005',
    'b0000000-0000-0000-0000-000000000008',
    '629100000005',
    'مياه العين المعدنية كرتون (24 × 500 مل)',
    'Al Ain Pure Drinking Water (24x500ml)',
    'مياه شرب نقية متوازنة المعادن لترطيب مثالي وانتعاش يومي.',
    'Pure, balanced mineral bottled water for daily hydration.',
    'العين',
    12.50, 16.00, 22,
    'carton', 1.0, 500,
    ARRAY['https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&w=600&q=80'],
    true, true, 4.9, 4100
)
ON CONFLICT (id) DO NOTHING;

-- 4. Insert Initial Notifications
INSERT INTO public.notifications (user_id, title, message, type, is_read) VALUES
(NULL, 'أهلاً بك في الديب مول 🛒', 'استمتع بتجربة تسوق هايبرماركت متكاملة مع توصيل إكسبريس فوري.', 'system', false),
(NULL, 'خصم ترحيبي 20% 🎉', 'استخدم الكود ALDEEB20 للحصول على خصم 20% على أول طلب لك!', 'promo', false),
(NULL, 'مضاعفة نقاط الولاء 🌟', 'اكسب نقاطاً مضاعفة على جميع مشتريات الخضار والفواكه اليوم!', 'loyalty', false);
