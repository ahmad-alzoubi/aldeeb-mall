# 🔍 تقرير المراجعة الهندسية واكتشاف الأخطاء لمنظومة الديب مول
## ALDEEB MALL & HYPERMARKET — COMPREHENSIVE ENGINEERING AUDIT & CODE REVIEW
**تقرير التدقيق الهندسي الصارم المعتمد على الشيفرة الفعلية للمشروع (Facts-Based Audit)**

---

## 1. ملخص تنفيذي للمراجعة (Executive Audit Summary)

تم فحص كامل شجرة الملفات والشيفرات المصدرية لـ:
- تطبيق فلاتر (`aldeeb_mall_app`)
- لوحة إدارة العمليات React 19 (`aldeeb_mall_admin`)
- مخططات قاعدة البيانات (`supabase/`)

### الخلاصة الهندسية:
الواجهات الأمامية مصممة ومبنية باحترافية بصرية وتفاعلية فائقة (Ultra-High Polish)، ولكن المشروع يعاني من **انفصال جوهري (Architectural Decoupling)** بين الواجهات وقاعدة البيانات السحابية:
1. لوحة التحكم الإدارية تعمل بنسبة 95% على **بيانات وهمية مخزنة في ذاكرة المتصفح (In-Memory React State)**، ولا ترسل عمليات الإضافة أو التعديل على المنتجات والطلبات والكوبونات إلى قاعدة بيانات Supabase.
2. هناك خطأ برمجي حرج في تطبيق فلاتر (`aldeeb_mall_app`) يؤدي إلى فشل تخزين الطلبات الحقيقية في Supabase بصمت نتيجة تعارض صيغة نصوص طرق الدفع مع قيود الـ SQL (`CHECK constraint violation`)، بالإضافة لعدم تسجيل بنود الطلب في جدول `order_items`.
3. العديد من الميزات المتقدمة (مثل المساعد الصوتي، الذكاء الاصطناعي الغذائي، إنترنت الأشياء لعربات التسوق، وتوصيل الدرون) هي **نماذج واجهة أمامية محاكية (Front-End Simulations)** وليست متصلة بخدمات سحابية حقيقية.

---

## 2. جدول تصنيف الأخطاء والمشكلات المكتشفة (Defect Registry)

| الرقم | اسم المشكلة | الملف والسطر التقريبي | الخطورة | الحالة | التأثير على الإنتاج |
| :---: | :--- | :--- | :---: | :---: | :--- |
| **BUG-01** | فشل إدراج الطلبات بسبب تعارض `payment_method` | [`supabase_service.dart:175`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/core/services/supabase_service.dart#L170-L195) و [`checkout_screen.dart:466`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/checkout/checkout_screen.dart#L460-L480) | **حرجة (Critical)** | مؤكد بالفحص | الطلبات لا تسجل في السيرفر وتضيع بمجرد إغلاق التطبيق |
| **BUG-02** | عدم حفظ بنود الطلب في جدول `order_items` | [`supabase_service.dart:165`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/core/services/supabase_service.dart#L160-L185) | **حرجة (Critical)** | مؤكد بالفحص | يتم إنشاء رأس الطلب دون تسجيل السلع والكميات المشتراة |
| **BUG-03** | انفصال لوحة الإدارة الكامل عن قاعدة بيانات المنتجات والطلبات | [`App.tsx:100-140`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/src/App.tsx#L100-L150) و [`ProductsPage.tsx`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/src/pages/ProductsPage.tsx) | **حرجة (Critical)** | مؤكد بالفحص | أي منتج يضيفه المدير يختفي عند التحديث ولا يراه تطبيق الهاتف |
| **BUG-04** | تضارب معرفات التصنيفات والمنتجات (UUIDs مقابل Short IDs) | [`supabase.ts`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/src/lib/supabase.ts) و [`seed_catalog_clean.sql`](file:///Volumes/ssd/Projects/aldeeb_mall/supabase/seed_catalog_clean.sql) | **عالية (High)** | مؤكد بالفحص | البيانات المحلية تستخدم `c1`, `p1` بينما السحابة تستخدم `UUIDv4` |
| **BUG-05** | عدم وجود إدارة مصادقة (Auth Guard) في لوحة الإدارة | [`App.tsx:60-90`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/src/App.tsx#L60-L90) | **عالية (High)** | مؤكد بالفحص | يمكن لأي شخص فتح لوحة الإدارة ونقاط البيع بدون تسجيل دخول |
| **BUG-06** | استبدال نقاط الولاء يتم محلياً دون استدعاء دالة قاعدة بيانات آمنة | [`loyalty_screen.dart:188`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/loyalty/loyalty_screen.dart#L185-L210) | **متوسطة (Medium)**| مؤكد بالفحص | ثغرة تسمح بتكرار استبدال المكافآت أو التلاعب برصيد النقاط محلياً |
| **BUG-07** | محاذاة العناوين في الفواتير الحرارية تعتمد على مقاسات شاشات ثابتة | [`ThermalReceiptView.tsx`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/src/components/ThermalReceiptView.tsx) | **منخفضة (Low)** | مؤكد بالفحص | قد يحدث تشوه بسيط عند الطباعة على طابعات 58mm مقابل 80mm |

---

## 3. تفاصيل الأخطاء البرمجية المؤكدة والحلول الجذرية

### 3.1 خطأ BUG-01: تعارض نص طريقة الدفع مع قيد قاعدة البيانات (`payment_method CHECK`)
- **الوصف والتأثير**: 
  في قاعدة البيانات، جدول `orders` يحتوي على القيد التالي:
  ```sql
  payment_method TEXT NOT NULL DEFAULT 'cod' CHECK (payment_method IN ('cod', 'card_on_delivery', 'card', 'loyalty_points', 'apple_pay'))
  ```
  بينما في تطبيق العميل [`checkout_screen.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/checkout/checkout_screen.dart#L466)، يتم إرسال النص العربي الظاهر في الواجهة:
  `'محفظة الديب الذكية (Aldeeb Pay)'` أو `'الدفع نقداً عند الاستلام'`.
  عند تنفيذ الاستدعاء في [`supabase_service.dart:175`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/core/services/supabase_service.dart#L175)، يرفض محرك PostgreSQL العملية فوراً بسبب مخالفة القيد (`Check Constraint Violation`). ولأن الكود محاط بـ `try { ... } catch (e) { // Log silently }`، يفشل الاستدعاء بدون تنبيه، ويظن المستخدم أن الطلب أُرسل، بينما لم يُسجل في السيرفر إطلاقاً!
- **الحل الجذري**:
  إنشاء دالة تحويل صريحة (`mapPaymentMethodToEnum(String arabicTitle)`) تحول النص العربي إلى الرموز المقبولة في الـ SQL (`cod`, `card_on_delivery`, `card`, إلخ) قبل إرسالها إلى Supabase.

### 3.2 خطأ BUG-02: تجاهل إدراج بنود الطلب في جدول `order_items`
- **الوصف والتأثير**:
  دالة `createOrder` في [`supabase_service.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/core/services/supabase_service.dart#L170-L195) تقوم بإدخال رأس الطلب فقط في جدول `orders`. قائمة السلع `items` التي تحتوي على تفاصيل المنتجات المشتراة، الكمية، وسعر الوحدة لا يتم إرسالها إلى جدول `order_items` المخصص لها في قاعدة البيانات!
- **الحل الجذري**:
  بعد نجاح إدراج صف الطلب والحصول على الـ `order_id` المتولد، يتم تنفيذ إدراج مجمع (`batch insert`) لجميع البنود في جدول `public.order_items`:
  ```dart
  final itemsPayload = items.map((item) => {
    'order_id': orderId,
    'product_id': item.product.id,
    'quantity': item.quantity,
    'unit_price': item.product.price,
    'total_price': item.totalPrice,
  }).toList();
  await client.from('order_items').insert(itemsPayload);
  ```

### 3.3 خطأ BUG-03: انفصال لوحة الإدارة التام عن Supabase في إدارة المنتجات والطلبات
- **الوصف والتأثير**:
  لوحة الإدارة مبنية بنظام React State مركزي في [`App.tsx`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/src/App.tsx). عند فتح صفحة المنتجات [`ProductsPage.tsx`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/src/pages/ProductsPage.tsx) أو صفحة الطلبات [`OrdersPage.tsx`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/src/pages/OrdersPage.tsx)، يتم قراءة وتعديل مصفوفات الذاكرة `initialProducts` و `initialOrders`.
  لا يوجد أي كود يستدعي `supabase.from('products').insert(...)` أو `supabase.from('orders').select(...)`. 
  المحصلة: لوحة الإدارة معزولة كلياً عن قاعدة البيانات وتطبيق الهاتف (باستثناء شاشتي الدعم والإعدادات).
- **الحل الجذري**:
  إعادة بناء مزامنة لوحة الإدارة عبر استبدال `useState(initialProducts)` بـ React Query أو خطاف مخصص (`useProducts` و `useOrders`) يقرأ من Supabase عبر الاشتراك اللحظي (`supabase.channel().on(...)`) وينفذ عمليات الـ CRUD مباشرة على الجداول السحابية.

### 3.4 خطأ BUG-04: تضارب نظام المعرفات (Short Mock IDs vs Supabase UUIDs)
- **الوصف والتأثير**:
  - في البيانات الوهمية المضمنة: المعرفات تأتي بصيغة نصوص قصيرة (`c1`, `c2`, `p1`, `p2`).
  - في قاعدة بيانات Supabase الحقيقية المنشأة بملف [`seed_catalog_clean.sql`](file:///Volumes/ssd/Projects/aldeeb_mall/supabase/seed_catalog_clean.sql): المفاتيح الرئيسية هي من نوع `UUID` حصراً (مثل `c0000000-0000-0000-0000-000000000001`).
  عندما يطلب تطبيق فلاتر المنتجات بحسب القسم (`getProducts(categoryId: 'c1')`)، لن يعثر على أي منتج في السيرفر لأن معرفات الأقسام في السحابة هي UUIDs، فيقوم التطبيق بالرجوع الصامت إلى البيانات الوهمية المحلية.
- **الحل الجذري**:
  توحيد جميع المعرفات في البيانات الاحتياطية والتطبيق ولوحة الإدارة لتتوافق تماماً مع الـ UUIDs المنشأة في قاعدة بيانات الإنتاج.

---

## 4. قائمة الوظائف والميزات غير المكتملة أو المحاكاة (Mock / Simulated Features)

خلال الفحص، تم رصد وظائف تظهر في الواجهة بمظهر مكتمل ولكنها في الحقيقة محاكاة من جانب العميل فقط (Client-Side Simulations):
1. **المساعد الصوتي الذكي ([`voice_assistant_modal.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/voice/voice_assistant_modal.dart))**:
   يستخدم حزمة `speech_to_text` لتحويل الصوت لنص، ثم يطبق شروط `if / else` وفلترة بالكلمات المفتاحية البسيطة محلياً. غير متصل بأي نموذج ذكاء اصطناعي حقيقي (مثل Gemini API أو LLM).
2. **أخصائي التغذية الذكي ([`ai_nutritionist_screen.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/ai_nutritionist/ai_nutritionist_screen.dart))**:
   يقوم بتركيب نصوص وإرشادات غذائية من قوالب مسبقة الإعداد محلياً، واقتراح سلع ثابتة من قائمة `defaultProducts`.
3. **عربة التسوق الذكية IoT وتوصيل الدرون ([`smart_cart_iot_screen.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/smart_cart_iot/smart_cart_iot_screen.dart))**:
   تولد أوزان وقراءات حساسات عبر `Random()` ومؤقتات زمنية (`Timer.periodic`) لمحاكاة الربط مع أجهزة المتجر.
4. **شاشات البث المباشر للتسوق ([`live_shopping_screen.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/live_shopping/live_shopping_screen.dart))**:
   تعرض واجهة فيديو ثابتة وشريط تعليقات ومشتريات وهمية متحركة تلقائياً عبر مؤقت دون خادم بث WebRTC أو HLS فعلي.
5. **صيدلية الديب والتأمين ([`pharmacy_screen.dart`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_app/lib/features/pharmacy/pharmacy_screen.dart))**:
   تتيح رفع صورة الوصفة الطبية محلياً وتظهر حالة "قيد المراجعة من الصيدلي" دون إرسال الملف أو الوصفة إلى نظام إدارة صيدلاني أو سحابة Supabase Storage.
6. **اشتراكات المقاضي الدورية (Subscribe & Save)**:
   البيانات محفوظة فقط داخل حالة الـ Widget وتنتهي وتعود للوضع الافتراضي عند إعادة فتح الشاشة.

---

## 5. مراجعة الأمان والصلاحيات (Security & Access Control Audit)

1. **تسريب المفاتيح العامة (Anon Key)**:
   مفتاح `VITE_SUPABASE_ANON_KEY` ومفتاح `SUPABASE_ANON_KEY` مضمنان بقيم افتراضية في الكود المصدري وفي ملف `.env`. هذا المفتاح مخصص للقراءة العامة في Supabase، ولكنه يتطلب تفعيل سياسات الـ RLS الصارمة لمنع المستخدمين من تعديل أسعار المنتجات أو حذف بيانات الآخرين.
2. **غياب جدار الحماية عن لوحة التحكم (Missing Admin Authentication)**:
   لوحة الإدارة في `aldeeb_mall_admin` تفتح مباشرة على لوحة التحكم وشاشات الـ POS ودفاتر الرواتب والموظفين دون شاشة تسجيل دخول أو التحقق من دور المستخدم (`role = 'admin'`). يجب بناء شاشة تسجيل دخول تتحقق من جدول `staff_members` قبل فتح اللوحة.
3. **سياسات RLS على جدول الطلبات (`orders`)**:
   سياسة الأمان تتطلب في بعض الحالات `auth.uid() = user_id`. ولكن التطبيق يدعم "الطلب كزائر" (Guest Checkout) مما يؤدي إلى رفض قاعدة البيانات للطلب في حال كان المستخدم غير مسجل دخول. يجب السماح بإدراج الطلبات المجهولة أو إنشاء حساب زائر مجهول تلقائياً (`Anonymous Sign-In`).

---

## 6. تقرير نتائج الاختبارات الفعلية للكود

- **اختبارات فلاتر (`flutter test`)**:
  - تم تشغيل أمر `flutter test` على مجلد `aldeeb_mall_app/test/widget_test.dart`.
  - **النتيجة**: نجاح 4 من 4 اختبارات بنسبة 100% (تشمل: عزل المنتجات المسودة، حسابات السلة والضرائب والتوصيل، حسابات مناطق درعا ورسوم الذروة، وفلترة التصنيفات).
- **فحص جودة كود فلاتر (`flutter analyze`)**:
  - تم تشغيل أمر `flutter analyze` على مشروع `aldeeb_mall_app`.
  - **النتيجة**: `No issues found! (ran in 14.0s)`، كود نظيف وخالٍ تماماً من أخطاء الـ Syntax والتحذيرات المعطلة.
- **بناء لوحة الإدارة (`npm run build`)**:
  - تم تشغيل `tsc && vite build` على مشروع `aldeeb_mall_admin`.
  - **النتيجة**: نجاح البناء في 3.7 ثوانٍ بدون أي أخطاء من مترجم TypeScript أو مُحزّم Vite.
