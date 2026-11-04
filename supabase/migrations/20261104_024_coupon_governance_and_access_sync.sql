-- ==============================================================================
-- Migration 024: Coupon Governance, Access Roles, and Atomic Validation Sync
-- ==============================================================================
-- 1. Updates RLS policies to allow marketing managers, branch managers, and 
--    all administrative staff to manage coupons.
-- 2. Enhances the validate_coupon stored procedure to support both 'percent' and 'percentage'.
-- 3. Guarantees coupon '5555' is active with 0.00 minimum order threshold.
-- ==============================================================================

-- 1. Ensure table and constraints support percent & percentage
ALTER TABLE public.coupons 
    DROP CONSTRAINT IF EXISTS coupons_discount_type_check;

ALTER TABLE public.coupons 
    ADD CONSTRAINT coupons_discount_type_check 
    CHECK (discount_type = ANY (ARRAY['percentage'::text, 'fixed'::text, 'percent'::text]));

-- 2. Update RLS policies
DROP POLICY IF EXISTS "coupons_select_policy" ON public.coupons;
DROP POLICY IF EXISTS "coupons_mutate_policy" ON public.coupons;
DROP POLICY IF EXISTS "Active coupons can be validated by authenticated users" ON public.coupons;
DROP POLICY IF EXISTS "Admins can manage coupons" ON public.coupons;

-- Anyone (public / anon / authenticated) can select active coupons to validate at checkout
CREATE POLICY coupons_select_policy ON public.coupons 
    FOR SELECT TO public 
    USING (is_active = true OR auth.is_staff());

-- Staff and administrators can manage coupons
CREATE POLICY coupons_mutate_policy ON public.coupons 
    FOR ALL TO authenticated
    USING (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'marketing_manager', 'auditor', 'accountant'))
    WITH CHECK (auth.user_role() IN ('super_admin', 'general_manager', 'branch_manager', 'marketing_manager', 'auditor', 'accountant'));

-- 3. Stored Procedure: Atomic Coupon Validation with detailed error feedback
CREATE OR REPLACE FUNCTION public.validate_coupon(
    p_code TEXT,
    p_subtotal NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_coupon RECORD;
    v_discount NUMERIC := 0;
BEGIN
    SELECT * INTO v_coupon
    FROM public.coupons
    WHERE UPPER(code) = UPPER(TRIM(p_code))
      AND is_active = true
      AND (expires_at IS NULL OR expires_at > now())
      AND (usage_limit IS NULL OR times_used < usage_limit);

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'valid', false,
            'message_ar', 'كود الخصم غير صحيح أو منتهي الصلاحية',
            'message_en', 'Invalid or expired promo code',
            'discount', 0
        );
    END IF;

    IF p_subtotal < v_coupon.min_order_amount THEN
        RETURN jsonb_build_object(
            'valid', false,
            'message_ar', 'الحد الأدنى لتفعيل هذا الكوبون هو ' || v_coupon.min_order_amount || ' ل.س (قيمة سلتك الحالية: ' || p_subtotal || ' ل.س)',
            'message_en', 'Minimum order amount for this coupon is ' || v_coupon.min_order_amount || ' (Current: ' || p_subtotal || ')',
            'discount', 0,
            'min_order_amount', v_coupon.min_order_amount,
            'amount_needed', ROUND(v_coupon.min_order_amount - p_subtotal, 2)
        );
    END IF;

    IF v_coupon.discount_type IN ('percentage', 'percent') THEN
        v_discount := (p_subtotal * v_coupon.discount_value) / 100.0;
        IF v_coupon.max_discount IS NOT NULL AND v_discount > v_coupon.max_discount THEN
            v_discount := v_coupon.max_discount;
        END IF;
    ELSE
        v_discount := LEAST(v_coupon.discount_value, p_subtotal);
    END IF;

    RETURN jsonb_build_object(
        'valid', true,
        'coupon_id', v_coupon.id,
        'code', v_coupon.code,
        'discount_type', v_coupon.discount_type,
        'discount_value', v_coupon.discount_value,
        'min_order_amount', v_coupon.min_order_amount,
        'max_discount', v_coupon.max_discount,
        'calculated_discount', ROUND(v_discount, 2),
        'message_ar', 'تم تفعيل الكوبون بنجاح!',
        'message_en', 'Coupon applied successfully!'
    );
END;
$$;

-- 4. Upsert coupon '5555' with full production guarantees
INSERT INTO public.coupons (
    id, 
    code, 
    discount_type, 
    discount_value, 
    min_order_amount, 
    max_discount, 
    usage_limit, 
    times_used, 
    is_active
) VALUES (
    'ca000000-0000-0000-0000-000000005555',
    '5555',
    'percentage',
    15.00,
    0.00,
    50.00,
    1000,
    0,
    true
)
ON CONFLICT (code) DO UPDATE SET
    discount_type = EXCLUDED.discount_type,
    discount_value = EXCLUDED.discount_value,
    min_order_amount = 0.00,
    max_discount = EXCLUDED.max_discount,
    is_active = true;
