-- =========================================================================
-- Customer Service & Realtime Support Ticket System Migration
-- =========================================================================

CREATE TABLE IF NOT EXISTS public.support_tickets (
    id TEXT PRIMARY KEY,
    ticket_number TEXT NOT NULL UNIQUE,
    customer_name TEXT NOT NULL,
    customer_phone TEXT DEFAULT '',
    order_number TEXT,
    subject TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    last_message TEXT DEFAULT '',
    messages JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Indexing for high-performance lookup
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_order ON public.support_tickets(order_number);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON public.support_tickets(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Public & Authenticated Read/Write policies for frictionless operation
DROP POLICY IF EXISTS "Public and authenticated users can view support tickets" ON public.support_tickets;
CREATE POLICY "Public and authenticated users can view support tickets"
ON public.support_tickets FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Users and admins can insert and update support tickets" ON public.support_tickets;
CREATE POLICY "Users and admins can insert and update support tickets"
ON public.support_tickets FOR ALL
USING (true)
WITH CHECK (true);

-- Enable Supabase Realtime Replication (Safely conditional)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.support_tickets;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END IF;
END $$;

-- Seed Initial Realistic Support Tickets
INSERT INTO public.support_tickets (id, ticket_number, customer_name, customer_phone, order_number, subject, category, status, priority, last_message, messages)
VALUES 
(
  'tkt-1',
  'TKT-4412',
  'فاطمة المنصوري',
  '+971501234567',
  'DEEB-8843',
  'طلب إضافة صنف إضافي مع الطلب قبل خروج المندوب',
  'order_issue',
  'open',
  'high',
  'مرحباً، هل يمكن إضافة عبوة بيض بلدي إلى طلبي إذا كان لا يزال قيد التجهيز؟',
  '[{"id":"m-1","sender":"customer","sender_name":"فاطمة المنصوري","text":"مرحباً، هل يمكن إضافة عبوة بيض بلدي إلى طلبي إذا كان لا يزال قيد التجهيز؟","timestamp":"10:42 ص"},{"id":"m-2","sender":"agent","sender_name":"فريق خدمة العملاء","text":"أهلاً بك أختي فاطمة! تم التحقق وطلبك لا يزال في مرحلة التجهيز في المستودع المظلم. جاري إضافة الصنف فوراً.","timestamp":"10:44 ص"}]'::jsonb
),
(
  'tkt-2',
  'TKT-4410',
  'خالد السعدي',
  '+971559876543',
  'DEEB-8844',
  'استفسار عن موعد وصول الكابتن لبرج مارينا كراون',
  'delivery',
  'in_progress',
  'medium',
  'الكابتن محمد في الطريق ويصلك خلال 7 دقائق بالضبط.',
  '[{"id":"m-3","sender":"customer","sender_name":"خالد السعدي","text":"السلام عليكم، كم المتبقي على وصول طلب الغداء؟","timestamp":"10:15 ص"},{"id":"m-4","sender":"agent","sender_name":"فريق العمليات والدعم","text":"وعليكم السلام ورحمة الله، الكابتن محمد في الطريق وموقعه يبعد 1.2 كم، يصلك خلال 7 دقائق بالضبط.","timestamp":"10:18 ص"}]'::jsonb
),
(
  'tkt-3',
  'TKT-4401',
  'أحمد الزعبي',
  '+971508889900',
  NULL,
  'استفسار عن تحويل نقاط ولاء العضوية الذهبية لكوبون خصم',
  'general',
  'resolved',
  'low',
  'تم تفعيل كود الخصم في حسابك بقيمة 25 ل.س، تسوق ممتع!',
  '[{"id":"m-5","sender":"customer","sender_name":"أحمد الزعبي","text":"كيف يمكنني استبدال رصيد نقاط الولاء برصيد محفظة؟","timestamp":"أمس 04:30 م"},{"id":"m-6","sender":"agent","sender_name":"مشرف الدعم الفني","text":"تم تفعيل كود الخصم في حسابك بقيمة 25 ل.س، تسوق ممتع!","timestamp":"أمس 04:35 م"}]'::jsonb
)
ON CONFLICT (id) DO UPDATE 
SET messages = EXCLUDED.messages,
    last_message = EXCLUDED.last_message,
    status = EXCLUDED.status;
