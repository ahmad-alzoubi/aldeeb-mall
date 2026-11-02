-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Banners Management & Dynamic In-App Navigation
-- Migration 005: Extended Banners Schema (Hero Carousel & Side Promotional Cards)
-- ==============================================================================

-- 1. Add slot column and badge color
ALTER TABLE public.banners 
    ADD COLUMN IF NOT EXISTS slot TEXT NOT NULL DEFAULT 'hero',
    ADD COLUMN IF NOT EXISTS badge_color TEXT DEFAULT '#EF4444';

-- 2. Drop old check constraints and add updated ones
ALTER TABLE public.banners DROP CONSTRAINT IF EXISTS banners_target_type_check;
ALTER TABLE public.banners ADD CONSTRAINT banners_target_type_check 
    CHECK (target_type IN ('category', 'screen', 'product', 'deal', 'coupon', 'external'));

ALTER TABLE public.banners DROP CONSTRAINT IF EXISTS banners_slot_check;
ALTER TABLE public.banners ADD CONSTRAINT banners_slot_check 
    CHECK (slot IN ('hero', 'side_top', 'side_bottom', 'promo'));

-- 3. Update existing banners to slot 'hero'
UPDATE public.banners SET slot = 'hero' WHERE slot IS NULL OR slot = '';

-- 4. Insert or update default side promotional cards
INSERT INTO public.banners (
    id, 
    title_ar, 
    title_en, 
    subtitle_ar, 
    subtitle_en, 
    image_url, 
    slot, 
    target_type, 
    target_id, 
    badge_ar, 
    badge_color, 
    sort_order, 
    is_active
) VALUES
(
    'b0000000-0000-0000-0000-000000000010',
    'صفقة اليوم الطازجة 🍅',
    'Fresh Daily Deal 🍅',
    'طماطم مزارع محلية قطاف الصباح بخصم 25%',
    'Fresh local vine tomatoes morning harvest 25% OFF',
    'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80',
    'side_top',
    'product',
    'a0000000-0000-0000-0000-000000000003',
    '3.75 د.أ / كجم',
    '#EF4444',
    1,
    true
),
(
    'b0000000-0000-0000-0000-000000000011',
    'توصيل فوري خلال 60 دقيقة 🛵',
    'Instant Delivery within 60 Mins 🛵',
    'اطلب طلبات البيت واستلمها على بابك',
    'Order your home essentials and receive them at your doorstep',
    'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=600&q=80',
    'side_bottom',
    'coupon',
    'FREE100',
    'مجاناً للطلبات فوق 100 د.أ',
    '#0284C7',
    2,
    true
)
ON CONFLICT (id) DO UPDATE SET
    title_ar = EXCLUDED.title_ar,
    subtitle_ar = EXCLUDED.subtitle_ar,
    image_url = EXCLUDED.image_url,
    slot = EXCLUDED.slot,
    target_type = EXCLUDED.target_type,
    target_id = EXCLUDED.target_id,
    badge_ar = EXCLUDED.badge_ar,
    badge_color = EXCLUDED.badge_color;
