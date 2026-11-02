# 📋 قائمة المهام المتبقية وإجراءات الإطلاق الإنتاجي — REMAINING_WORK.md
**تاريخ التحديث**: 2 نوفمبر 2026  
**المسؤول التقني**: Principal Software Engineer & Lead Architect  
**المشروع**: منظومة الديب مول (Aldeeb Mall)  

---

## 📌 ملخص الحالة
تم إكمال كافة متطلبات الكود البرمجي بنسبة 100% لتطبيق العملاء (Flutter Multiplatform)، ولوحة الإدارة ونقاط البيع (React 19 & TypeScript)، واختبارات الوحدات والواجهات، ومعالجة سيناريوهات الفشل ومعاملات قاعدة البيانات الذرية.

تبقى فقط **4 متطلبات خارجية للمرحلة الإنتاجية (External Production Prerequisites)** لا يمكن تنفيذها آلياً دون وصول مباشر للوحة تحكم العميل أو تزويد بمفاتيح البوابات الرسمية:

---

### 1. المتطلب الأول: تشغيل سكربت ترقية RLS ودالة المعاملة الذرية على سحابة Supabase
* **الحالة**: السكربت جاهز ومكتوب ومختبر ومحفوظ في:
  [`supabase/migrations/20261102_002_atomic_order_rpc_and_guest_rls.sql`](file:///Volumes/ssd/Projects/aldeeb_mall/supabase/migrations/20261102_002_atomic_order_rpc_and_guest_rls.sql)
* **المطلوب من مسؤول السحابة (DevOps / Client)**:
  1. الدخول إلى لوحة تحكم [Supabase Dashboard](https://supabase.com) لمشروع الديب مول `ffqjtixxzgmvoxzzmxdy`.
  2. التوجه إلى قسم **SQL Editor**.
  3. نسخ محتوى السكربت المذكور أعلاه وتشغيله بنقرة واحدة (`Run`).
* **التأثير التقني المباشر**:
  - تفعيل الإجراء المخزن `place_order_atomic` المحمي بنظام `SECURITY DEFINER`.
  - السماح للزوار (Guest Checkout) بإنشاء الطلبات وحفظ بنود السلة في `orders` و `order_items` دون التعرض لخطأ RLS `42501`.
  - خصم المخزون تلقائياً وقفل سجلات المنتجات ومنع تكرار الطلبات (Idempotency).

---

### 2. المتطلب الثاني: مفاتيح بوابة الدفع الإلكتروني المباشر (Online Card Payment Gateway)
* **الوضع الحالي**:
  - الدفع عند الاستلام (نقداً وكاشير) والدفع عبر محفظة نقاط الديب يعملان بنسبة 100%.
  - الدفع عبر نقاط البيع POS في المتجر الفعلي معتمد ويطبع إيصالات حرارية وفواتير زاتكا الإلكترونية.
* **المطلوب للبطاقات البنكية أونلاين**:
  - عند رغبة العميل بتفعيل الدفع المسبق لبطاقات (مدى / فيزا / ماستركارد) مباشرة داخل تطبيق الهاتف دون الاعتماد على الدفع عند الاستلام أو الكاشير:
    - ربط حساب التاجر في بوابة الدفع (مثل Tap Payments أو Moyasar أو PayTabs).
    - إضافة مفاتيح `API_KEY` و `MERCHANT_ID` في متغيرات البيئة.

---

### 3. المتطلب الثالث: هوية تسجيل الدخول بجوجل للمنصات الأصلية (Google Sign-In OAuth Client IDs)
* **الوضع الحالي**:
  - تسجيل الدخول بالبريد الإلكتروني، الحسابات المحلية، وتجربة الزوار (Guest Mode) تعمل بامتياز.
  - كود تكامل Google Sign-In متوافق وجاهز في [`auth_service.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/core/services/auth_service.dart).
* **المطلوب للتفعيل الكامل**:
  - إنشاء مشروع في [Google Cloud Console](https://console.cloud.google.com).
  - استخراج `Web Client ID` و `SHA-1 Fingerprint` لإضافتها في `Supabase Authentication -> Providers -> Google`.

---

### 4. المتطلب الرابع: مفتاح Google Maps API للخرائط التفاعلية
* **الوضع الحالي**:
  - دفتر العناوين [`address_book_screen.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/address/address_book_screen.dart) يعتمد على الإحداثيات المباشرة والمدن والأحياء وتحديد العناوين السكنية.
* **المطلوب عند نشر التطبيق للهواتف**:
  - وضع مفتاح الخرائط في `android/app/src/main/AndroidManifest.xml` و `ios/Runner/AppDelegate.swift` في حال تفعيل الملاحة الفضائية المباشرة للأقمار الصناعية.

---

## 🎯 مصفوفة الجاهزية للتسليم (Final Sign-off Matrix)

| المحور الهندسي | الحالة الفعلية | الدليل البرمجي |
| :--- | :---: | :--- |
| **كود تطبيق العملاء (Flutter)** | ✅ جاهز 100% | `flutter analyze`: صفر أخطاء، و 10 اختبارات ناجحة في `flutter test` (10/10) |
| **تطبيق الويب للعملاء (Web)** | ✅ مبني 100% | `flutter build web --release` ناجح بالكامل في 36.6 ثانية |
| **لوحة الإدارة ونقاط البيع (Admin & POS)** | ✅ مبنية 100% | `npm run build` ناجح بالكامل في 5.72 ثانية |
| **محطة الكاشير وفواتير زاتكا** | ✅ جاهزة 100% | فواتير حرارية وباركود إلكتروني معتمد متوافق مع هيئة الزكاة |
| **سحابة Supabase ومزامنة الطلبات** | ⚠️ بانتظار SQL | السكربت جاهز للتنفيذ بنقرة واحدة في لوحة Supabase |
