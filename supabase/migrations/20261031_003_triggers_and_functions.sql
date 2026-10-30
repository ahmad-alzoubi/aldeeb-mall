-- ==============================================================================
-- الديب مول (Aldeeb Mall) - Database Functions & Automated Triggers
-- Migration 003: User Profile Sync, Loyalty Points Calculation, Inventory Management
-- ==============================================================================

-- 1. Function & Trigger: Automatic Profile Sync from Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_full_name TEXT;
    v_avatar_url TEXT;
BEGIN
    -- Extract full name from Google metadata or email
    v_full_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1),
        'عميل الديب مول'
    );
    v_avatar_url := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture',
        ''
    );

    -- Insert into public.profiles
    INSERT INTO public.profiles (id, full_name, email, phone, avatar_url, loyalty_points, role)
    VALUES (
        NEW.id,
        v_full_name,
        NEW.email,
        NEW.phone,
        v_avatar_url,
        50, -- 50 Welcome bonus points
        'customer'
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        full_name = EXCLUDED.full_name,
        avatar_url = CASE WHEN profiles.avatar_url IS NULL OR profiles.avatar_url = '' THEN EXCLUDED.avatar_url ELSE profiles.avatar_url END,
        updated_at = timezone('utc'::text, now());

    -- Record welcome loyalty points transaction
    INSERT INTO public.loyalty_transactions (user_id, points, transaction_type, description_ar, description_en)
    VALUES (
        NEW.id,
        50,
        'bonus',
        'هدية ترحيبية 50 نقطة عند الانضمام لنادي عملاء الديب مول',
        'Welcome bonus 50 points for joining Aldeeb Mall Club'
    );

    -- Send Welcome Notification
    INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type)
    VALUES (
        NEW.id,
        'أهلاً بك في الديب مول 🛒',
        'Welcome to Aldeeb Mall 🛒',
        'تمت إضافة 50 نقطة ولاء ترحيبية إلى محفظتك. نتمنى لك تجربة تسوق ممتعة!',
        '50 loyalty points have been added to your wallet. Enjoy shopping!',
        'loyalty'
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Function & Trigger: Order Status Change Automation
CREATE OR REPLACE FUNCTION public.handle_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_item RECORD;
    v_points_earned INTEGER;
    v_user_profile RECORD;
BEGIN
    -- Only trigger if status has changed
    IF (OLD.status IS DISTINCT FROM NEW.status) THEN
        
        -- A. When Order is Confirmed: Decrement Stock and Increment Sales Count
        IF (NEW.status = 'confirmed' AND OLD.status = 'pending') THEN
            FOR v_item IN SELECT product_id, quantity FROM public.order_items WHERE order_id = NEW.id LOOP
                IF v_item.product_id IS NOT NULL THEN
                    UPDATE public.products
                    SET 
                        stock_quantity = GREATEST(0, stock_quantity - v_item.quantity::integer),
                        sales_count = sales_count + v_item.quantity::integer
                    WHERE id = v_item.product_id;
                END IF;
            END LOOP;

            -- Notify user
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                'تم تأكيد طلبك #' || NEW.order_number,
                'Order #' || NEW.order_number || ' Confirmed',
                'طلبك قيد المراجعة وسيبدأ فريق المستودع بتجهيز المنتجات الطازجة لك الآن.',
                'Your order has been confirmed and our warehouse is preparing your fresh items.',
                'order',
                jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number)
            );
        END IF;

        -- B. When Order is Packing
        IF (NEW.status = 'packing') THEN
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                'طلبك قيد التجهيز 📦',
                'Your order is being packed 📦',
                'يقوم فريقنا الآن بانتقاء أفضل المنتجات وتغليف طلبك بعناية فائقة.',
                'Our team is picking the freshest items and carefully packaging your order.',
                'order',
                jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number)
            );
        END IF;

        -- C. When Order is Out for Delivery
        IF (NEW.status = 'out_for_delivery') THEN
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                'طلبك في الطريق إليك 🛵',
                'Your order is on the way 🛵',
                'مندوب التوصيل في طريقه إلى موقعك الآن. يرجى إبقاء هاتفك متاحاً.',
                'Your delivery driver is on the way. Please keep your phone available.',
                'order',
                jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number)
            );
        END IF;

        -- D. When Order is Delivered: Award Loyalty Points & Finalize
        IF (NEW.status = 'delivered' AND OLD.status != 'delivered') THEN
            -- Calculate points (1 point per 1 unit of total_amount)
            v_points_earned := FLOOR(NEW.total_amount)::INTEGER;

            IF v_points_earned > 0 AND NEW.user_id IS NOT NULL THEN
                -- Add points to profile
                UPDATE public.profiles
                SET loyalty_points = loyalty_points + v_points_earned
                WHERE id = NEW.user_id;

                -- Record transaction
                INSERT INTO public.loyalty_transactions (user_id, order_id, points, transaction_type, description_ar, description_en)
                VALUES (
                    NEW.user_id,
                    NEW.id,
                    v_points_earned,
                    'earned',
                    'نقاط مكتسبة من إتمام الطلب #' || NEW.order_number,
                    'Points earned from order #' || NEW.order_number
                );
            END IF;

            -- Notify user
            INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, payload)
            VALUES (
                NEW.user_id,
                'تم تسليم طلبك بنجاح 🎉',
                'Order Delivered Successfully 🎉',
                'شكراً لتسوقك من الديب مول! تمت إضافة ' || v_points_earned || ' نقطة إلى محفظتك.',
                'Thank you for shopping at Aldeeb Mall! ' || v_points_earned || ' points added to your wallet.',
                'order',
                jsonb_build_object('order_id', NEW.id, 'points_earned', v_points_earned)
            );
        END IF;

    END IF;

    NEW.updated_at := timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_order_status_updated ON public.orders;
CREATE TRIGGER on_order_status_updated
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.handle_order_status_change();

-- 3. Stored Procedure: Validate Coupon
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
    WHERE UPPER(code) = UPPER(p_code)
      AND is_active = true
      AND (expires_at IS NULL OR expires_at > now())
      AND (usage_limit IS NULL OR times_used < usage_limit);

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'valid', false,
            'message_ar', 'كوبون الخصم غير صحيح أو منتهي الصلاحية',
            'message_en', 'Invalid or expired promo code',
            'discount', 0
        );
    END IF;

    IF p_subtotal < v_coupon.min_order_amount THEN
        RETURN jsonb_build_object(
            'valid', false,
            'message_ar', 'الحد الأدنى لتفعيل هذا الكوبون هو ' || v_coupon.min_order_amount,
            'message_en', 'Minimum order amount for this coupon is ' || v_coupon.min_order_amount,
            'discount', 0
        );
    END IF;

    IF v_coupon.discount_type = 'percentage' THEN
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
        'calculated_discount', ROUND(v_discount, 2),
        'message_ar', 'تم تفعيل الكوبون بنجاح!',
        'message_en', 'Coupon applied successfully!'
    );
END;
$$;
