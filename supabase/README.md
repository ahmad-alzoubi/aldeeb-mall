# 🚀 دليل إعداد سوبابيز (Supabase Setup Guide) — الديب مول (Aldeeb Mall)

يوضح هذا الدليل خطوات إعداد قاعدة بيانات **Supabase** وربط تسجيل الدخول بحساب **Google** وتفعيل نظام الإشعارات والتخزين السحابي لمشروع الديب مول.

---

## 1. تطبيق ملفات الـ SQL (Database Migrations)

افتح لوحة تحكم مشروعك في [Supabase Dashboard](https://supabase.com/dashboard) ثم انتقل إلى **SQL Editor**، ونفّذ الملفات التالية بالترتيب:

1. **`20261031_001_initial_schema.sql`**:
   - ينشئ جميع الجداول (المنتجات، الأقسام، السلة، الطلبات، الكوبونات، نقاط الولاء، الإشعارات، إعدادات المتجر).
   - ينشئ الفهارس السريعة (Indexes) لتسريع عمليات البحث والتصفية.

2. **`20261031_002_rls_security.sql`**:
   - يفعّل سياسات أمان مستوى الصف (Row-Level Security - RLS).
   - يضمن حماية بيانات العملاء والطلبات وتأمين لوحة الإدارة للمدراء فقط.

3. **`20261031_003_triggers_and_functions.sql`**:
   - تريجر إنشاء وتحديث بروفايل المستخدم تلقائياً عند تسجيل الدخول بقوقل مع منح 50 نقطة ترحيبية.
   - تريجر تتبع حالات الطلبات وتحديث المخزون وإيداع نقاط الولاء تلقائياً عند التسليم.
   - دالة التحقق من الكوبونات وحساب الخصم `validate_coupon`.

4. **`20261031_004_seed_hypermarket.sql`**:
   - يملأ قاعدة البيانات بكتالوج كارفور الافتراضي (9 أقسام رئيسية، منتجات بأسعار وصور وتفاصيل حقيقية، عروض ترويجية، وكوبونات نشطة: `ALDEEB10`, `SAVE20`, `WELCOME15`).

---

## 2. تفعيل تسجيل الدخول بواسطة قوقل (Google Authentication)

1. في **Supabase Dashboard**، انتقل إلى:
   `Authentication` -> `Providers` -> `Google`.
2. اضغط على **Enable Google**.
3. احصل على `Client ID` و `Client Secret` من [Google Cloud Console](https://console.cloud.google.com/):
   - أنشئ مشروعاً جديداً أو اختر مشروعاً موجوداً.
   - انتقل إلى **APIs & Services** -> **Credentials** -> **Create Credentials** -> **OAuth client ID**.
   - اختر نوع التطبيق **Web application**.
   - أضف الرابط المعطى في سوبابيز داخل **Authorized redirect URIs** (غالباً: `https://<YOUR-PROJECT-ID>.supabase.co/auth/v1/callback`).
4. الصق `Client ID` و `Client Secret` في سوبابيز واضغط **Save**.

---

## 3. إعداد سلات التخزين السحابي (Supabase Storage Buckets)

في لوحة سوبابيز، انتقل إلى **Storage** وأنشئ السلات التالية واجعلها **Public**:

| اسم السلة (Bucket Name) | النوع | الاستخدام |
| :--- | :--- | :--- |
| `products` | Public | صور المنتجات المصورة والمرفوعة من لوحة الإدارة |
| `banners` | Public | لافتات العروض الترويجية والصفقات اليومية |
| `avatars` | Public | صور الملف الشخصي للعملاء والموظفين |

---

## 4. متغيرات البيئة (Environment Variables)

احفظ المفاتيح الخاصة بمشروعك لاستخدامها في تطبيق الهاتف ولوحة الإدارة:
```env
SUPABASE_URL=https://xxxxxxxxxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
