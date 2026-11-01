-- ==============================================================================
-- 20261031_007_store_theme_and_dynamic_settings.sql
-- Store Theme Settings & Realtime Dynamic Branding Support
-- ==============================================================================

-- 1. Ensure settings JSONB column exists on public.store_settings
ALTER TABLE public.store_settings 
ADD COLUMN IF NOT EXISTS settings JSONB DEFAULT '{}'::jsonb;

-- 2. Ensure RLS policies allow view and update/insert on store_settings
DROP POLICY IF EXISTS "Store settings are viewable by everyone" ON public.store_settings;
CREATE POLICY "Store settings are viewable by everyone"
    ON public.store_settings FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Anyone can insert store settings" ON public.store_settings;
CREATE POLICY "Anyone can insert store settings"
    ON public.store_settings FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can update store settings" ON public.store_settings;
CREATE POLICY "Anyone can update store settings"
    ON public.store_settings FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- 3. Upsert default active_theme record
INSERT INTO public.store_settings (id, store_name_ar, store_name_en, currency, delivery_fee, free_delivery_threshold, settings)
VALUES (
    'active_theme',
    'الديب مول',
    'Aldeeb Mall',
    'ل.س',
    10.00,
    100.00,
    '{
      "primaryColor": "#0D47A1",
      "primaryDarkColor": "#0A2E6B",
      "secondaryColor": "#E53935",
      "accentColor": "#FFB300",
      "backgroundColor": "#F8FAFC",
      "surfaceColor": "#FFFFFF",
      "textPrimaryColor": "#0F172A",
      "textSecondaryColor": "#64748B",
      "storeNameAr": "الديب مول",
      "storeNameEn": "Aldeeb Mall",
      "taglineAr": "هايبرماركت العائلة الأول - جودة وتوفير بلا حدود",
      "announcementText": "🚚 توصيل مجاني للطلبات فوق 100 ل.س | صفقات حصرية يومياً",
      "expressDeliveryText": "توصيل إكسبريس فوري خلال 15 دقيقة ⚡",
      "smartExperiencesTitle": "تجارب الديب الذكية",
      "smartExperiencesSubtitle": "وفّر مع الجيران، ونظّم مقاضيك الشهرية بذكاء وسرعة",
      "groupDealsTitle": "الشراء الجماعي الذكي",
      "groupDealsSubtitle": "وفّر حتى 40% مع عروض الجيران التشاركية الحية",
      "groceryListTitle": "القائمة الذكية ومخطط المقاضي",
      "groceryListSubtitle": "تنظيم ومزامنة المقاضي العائلية بذكاء",
      "currency": "ل.س"
    }'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
    settings = EXCLUDED.settings,
    updated_at = timezone('utc'::text, now());
