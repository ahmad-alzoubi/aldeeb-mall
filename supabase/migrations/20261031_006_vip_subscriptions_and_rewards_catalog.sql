-- ==============================================================================
-- Migration: 20261031_006_vip_subscriptions_and_rewards_catalog.sql
-- Description: VIP Prime Subscriptions, Rewards Catalog (Coupons & Free Gifts),
--              and Customer Claimed Rewards Tracking
-- Platform: Aldeeb Mall
-- ==============================================================================

-- 1. Subscription Plans Table
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_key VARCHAR(64) UNIQUE NOT NULL,
    name_ar VARCHAR(128) NOT NULL,
    name_en VARCHAR(128) NOT NULL,
    badge_tag_ar VARCHAR(64) NOT NULL,
    price_monthly DECIMAL(10, 2) NOT NULL,
    price_annual DECIMAL(10, 2) NOT NULL,
    points_multiplier DECIMAL(3, 2) NOT NULL DEFAULT 1.5,
    cashback_percent DECIMAL(4, 2) NOT NULL DEFAULT 2.5,
    free_express_delivery BOOLEAN NOT NULL DEFAULT TRUE,
    min_order_free_delivery DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    features_ar JSONB NOT NULL DEFAULT '[]'::jsonb,
    accent_color VARCHAR(32) NOT NULL DEFAULT '#047857',
    is_popular BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User Subscriptions Table
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_key VARCHAR(64) NOT NULL REFERENCES public.subscription_plans(plan_key) ON DELETE CASCADE,
    billing_cycle VARCHAR(16) NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'annual')),
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled', 'expired')),
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    renews_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
    cancelled_at TIMESTAMPTZ,
    total_deliveries_saved INT NOT NULL DEFAULT 0,
    total_money_saved DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Loyalty Reward Coupons Catalog
CREATE TABLE IF NOT EXISTS public.loyalty_reward_coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code_prefix VARCHAR(32) NOT NULL,
    title_ar VARCHAR(128) NOT NULL,
    description_ar TEXT,
    points_cost INT NOT NULL CHECK (points_cost > 0),
    discount_amount DECIMAL(10, 2) NOT NULL CHECK (discount_amount > 0),
    min_order_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    days_valid INT NOT NULL DEFAULT 30,
    total_claimed INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Loyalty Reward Products Catalog (Free Items via Points)
CREATE TABLE IF NOT EXISTS public.loyalty_reward_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    title_ar VARCHAR(128) NOT NULL,
    title_en VARCHAR(128) NOT NULL,
    image_url TEXT NOT NULL,
    category_ar VARCHAR(64) NOT NULL,
    points_cost INT NOT NULL CHECK (points_cost > 0),
    stock_quota INT NOT NULL DEFAULT 50,
    claimed_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. User Claimed Rewards History
CREATE TABLE IF NOT EXISTS public.user_claimed_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reward_type VARCHAR(32) NOT NULL CHECK (reward_type IN ('coupon', 'product', 'invoice_discount')),
    reward_title_ar VARCHAR(128) NOT NULL,
    points_spent INT NOT NULL CHECK (points_spent >= 0),
    coupon_code VARCHAR(64),
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for lightning performance
CREATE INDEX IF NOT EXISTS idx_user_subs_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subs_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_claimed_rewards_user_id ON public.user_claimed_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_reward_coupons_active ON public.loyalty_reward_coupons(is_active);
CREATE INDEX IF NOT EXISTS idx_reward_products_active ON public.loyalty_reward_products(is_active);

-- Enable RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_reward_coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_reward_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_claimed_rewards ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Anyone can view subscription plans" ON public.subscription_plans;
CREATE POLICY "Anyone can view subscription plans" ON public.subscription_plans
    FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Users can view their own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view their own subscriptions" ON public.user_subscriptions
    FOR SELECT TO authenticated USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Anyone can view active reward coupons" ON public.loyalty_reward_coupons;
CREATE POLICY "Anyone can view active reward coupons" ON public.loyalty_reward_coupons
    FOR SELECT TO public USING (is_active = true);

DROP POLICY IF EXISTS "Anyone can view active reward products" ON public.loyalty_reward_products;
CREATE POLICY "Anyone can view active reward products" ON public.loyalty_reward_products
    FOR SELECT TO public USING (is_active = true);

DROP POLICY IF EXISTS "Users can view their own claimed rewards" ON public.user_claimed_rewards;
CREATE POLICY "Users can view their own claimed rewards" ON public.user_claimed_rewards
    FOR ALL TO authenticated USING ((select auth.uid()) = user_id);

-- Seed VIP Subscription Plans
INSERT INTO public.subscription_plans (
    plan_key, name_ar, name_en, badge_tag_ar, price_monthly, price_annual,
    points_multiplier, cashback_percent, free_express_delivery, min_order_free_delivery,
    features_ar, accent_color, is_popular, sort_order
) VALUES 
(
    'prime_plus',
    'باقة الديب بلس (Aldeeb Plus)',
    'Aldeeb Prime Plus',
    'الباقة الاقتصادية',
    29.00,
    290.00,
    1.50,
    2.50,
    TRUE,
    50.00,
    '[
        "توصيل سريع مجاني للطلبات فوق 50 د.إ",
        "عروض أسبوعية وتخفيضات خاصة للأعضاء",
        "كاش باك 2.5% نقدي في المحفظة",
        "نقاط ولاء مضاعفة 1.5x على كل فاتورة",
        "تنبيهات فورية قبل نفاد العروض الكبرى"
    ]'::jsonb,
    '#2563EB',
    FALSE,
    1
),
(
    'prime_vip_ultra',
    'باقة الترا VIP (Prime Ultra)',
    'Aldeeb Prime Ultra VIP',
    'الأكثر طلباً واختياراً ⭐',
    59.00,
    590.00,
    2.50,
    5.00,
    TRUE,
    0.00,
    '[
        "توصيل فائق السرعة 15 دقيقة مجاني بدون أي حد أدنى نهائياً",
        "عروض فلاش وسرية VIP يومية قبل إتاحتها للجمهور",
        "بوكس هدايا وعينات منتجات متميزة مجانية شهرياً",
        "نقاط ولاء مضاعفة 2.5x على كافة أقسام الهايبرماركت",
        "كاش باك 5.0% نقدي فوري بعد استلام كل طلب",
        "أولوية قصوى في فرز السلات وخط ساخن VIP مخصص"
    ]'::jsonb,
    '#D97706',
    TRUE,
    2
),
(
    'prime_family_royal',
    'الباقة الملكية العائلية (Royal Crown)',
    'Aldeeb Royal Crown Family',
    'الفخامة المطلقة 👑',
    99.00,
    990.00,
    3.00,
    8.00,
    TRUE,
    0.00,
    '[
        "مشاركة الاشتراك مع 4 حسابات عائلية في نفس المنزل",
        "توصيل فوري مجاني 24/7 حتى في أوقات الذروة والأعياد",
        "كاش باك 8.0% مباشر مع كل طلب يتجاوز 100 د.إ",
        "نقاط ولاء ثلاثية 3x (كل 100 درهم تمنح 300 نقطة)",
        "بوكس شهري من المخبوزات والحلويات الفرنسية الفاخرة مجاناً",
        "استبدال فوري أو استرجاع مضمون للمنتجات الطازجة بدون أسئلة",
        "مساعد مشتريات شخصي وحجز مسبق للطلبيات الضخمة"
    ]'::jsonb,
    '#7C3AED',
    FALSE,
    3
)
ON CONFLICT (plan_key) DO UPDATE SET 
    name_ar = EXCLUDED.name_ar,
    price_monthly = EXCLUDED.price_monthly,
    points_multiplier = EXCLUDED.points_multiplier,
    cashback_percent = EXCLUDED.cashback_percent,
    features_ar = EXCLUDED.features_ar;

-- Seed Loyalty Reward Coupons
INSERT INTO public.loyalty_reward_coupons (code_prefix, title_ar, description_ar, points_cost, discount_amount, min_order_amount, days_valid)
VALUES 
    ('REWARD15', 'قسيمة خصم 15 د.إ فوري', 'وفر 15 درهم على أي طلب فوق 60 د.إ', 1200, 15.00, 60.00, 30),
    ('REWARD30', 'قسيمة خصم 30 د.إ كبرى', 'وفر 30 درهم على مشتريات السوبرماركت فوق 120 د.إ', 2200, 30.00, 120.00, 45),
    ('REWARD50', 'قسيمة خصم 50 د.إ VIP النخبة', 'وفر 50 درهم على الطلبات العائلية فوق 200 د.إ', 3500, 50.00, 200.00, 60),
    ('FREESHIP', 'قسيمة توصيل فوري مجاني', 'توصيل مجاني بالكامل بدون حد أدنى لـ 3 طلبات', 500, 15.00, 0.00, 30)
ON CONFLICT DO NOTHING;

-- Seed Loyalty Reward Free Products
INSERT INTO public.loyalty_reward_products (title_ar, title_en, image_url, category_ar, points_cost, stock_quota)
VALUES 
    (
        'سلة فواكه طازجة عضوية مختارة (3 كجم)',
        'Organic Fresh Fruit Basket 3kg',
        'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=600&q=80',
        'فواكه وخضار طازجة',
        1100,
        45
    ),
    (
        'زيت زيتون فلسطيني بكر ممتاز معصور على البارد 1 لتر',
        'Extra Virgin Cold-Pressed Olive Oil 1L',
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80',
        'مؤن وتموين فاخر',
        850,
        60
    ),
    (
        'بوكس شوكولاتة بلجيكية فاخرة محشوة 500 غرام',
        'Belgian Luxury Artisan Chocolates 500g',
        'https://images.unsplash.com/photo-1549007994-cb92caebd54b?auto=format&fit=crop&w=600&q=80',
        'حلويات وسكاكر',
        950,
        30
    ),
    (
        'كرتونة مياه أروى معدنية نقية (24 × 500 مل)',
        'Arwa Mineral Bottled Water (24 x 500ml)',
        'https://images.unsplash.com/photo-1559839914-1b346d6d3764?auto=format&fit=crop&w=600&q=80',
        'مشروبات ومياه',
        350,
        120
    ),
    (
        'كعكة كراميل وفراولة طازجة من مخبز الديب الحرفي',
        'Artisan Strawberry Caramel Fresh Cake',
        'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=600&q=80',
        'المخبز والحلويات',
        1400,
        25
    )
ON CONFLICT DO NOTHING;
