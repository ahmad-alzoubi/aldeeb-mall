# ⚙️ دليل الإعداد والتشغيل والنشر لمنظومة الديب مول
## ALDEEB MALL & HYPERMARKET — SETUP, DEPLOYMENT & OPERATIONS GUIDE
**مرجع شامل لتشغيل المنظومة محلياً، ربط قاعدة البيانات، وحزم ونشر التطبيقات للإنتاج**

---

## 1. المتطلبات البرمجية الأساسية (Prerequisites)

قبل البدء، تأكد من تثبيت الأدوات التالية على بيئة التطوير الخاصة بك:
- **Flutter SDK**: الإصدار 3.22 فما فوق (مع Dart 3.11 فما فوق).
- **Node.js**: الإصدار 18 أو 20 LTS (مع مدير الحزم npm).
- **Python**: الإصدار 3.9 فما فوق (لتشغيل خادم المزامنة المحلي `serve_lan.py`).
- **Git**: لإدارة النسخ وتتبع التعديلات.
- **Chrome Browser**: لاختبار التطبيق ولوحة الإدارة بنمط الويب.
- **Android Studio / Xcode** (اختياري): لتجميع واختبار حزم الهواتف الذكية (APK / IPA).

---

## 2. خطوات التشغيل المحلي خطوة بخطوة (Local Development)

### 2.1 تشغيل لوحة التحكم والإدارة (`aldeeb_mall_admin`)

1. انتقل لمجلد لوحة الإدارة:
   ```bash
   cd aldeeb_mall_admin
   ```
2. تثبيت الحزم والمكتبات:
   ```bash
   npm install
   ```
3. التحقق من ملف المتغيرات البيئية `.env`:
   تأكد من وجود الملف [`aldeeb_mall_admin/.env`](file:///Volumes/ssd/Projects/aldeeb_mall/aldeeb_mall_admin/.env) ويحتوي على:
   ```env
   VITE_SUPABASE_URL=https://ffqjtixxzgmvoxzzmxdy.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI...
   ```
4. تشغيل خادم التطوير:
   ```bash
   npm run dev
   ```
   سيتم تشغيل اللوحة على: `http://localhost:3000` أو المنفذ المحدد في مخرجات Vite.

5. بناء نسخة الإنتاج والتحقق من عدم وجود أخطاء برمجية:
   ```bash
   npm run build
   ```

---

### 2.2 تشغيل متجر وتطبيق فلاتر (`aldeeb_mall_app`)

1. انتقل لمجلد التطبيق:
   ```bash
   cd aldeeb_mall_app
   ```
2. جلب وتحديث حزم فلاتر:
   ```bash
   flutter pub get
   ```
3. فحص الكود والتأكد من خلوه من الأخطاء:
   ```bash
   flutter analyze
   flutter test
   ```
4. تشغيل التطبيق في المتصفح كمتجر ويب:
   ```bash
   flutter run -d chrome
   ```
5. لتشغيل التطبيق وتمرير مفاتيح Supabase عبر خيارات البناء (موصى به في بيئات الإنتاج):
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL="https://ffqjtixxzgmvoxzzmxdy.supabase.co" \
     --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI..."
   ```

---

### 2.3 تشغيل الخادم المحلي عبر الشبكة للتجربة الحية بين الهاتف والكمبيوتر (`serve_lan.py`)

إذا كنت تريد تجربة التطبيق على هاتفك الشخصي مع لوحة التحكم على جهاز الكمبيوتر عبر شبكة الواي فاي المنزلية:
1. ارجع لمجلد المشروع الجذري:
   ```bash
   cd /Volumes/ssd/Projects/aldeeb_mall
   ```
2. شغّل خادم البايثون المخصص:
   ```bash
   python3 serve_lan.py
   ```
   سيقوم الخادم تلقائياً بما يلي:
   - اكتشاف عنوان IP المحلي لجهازك (مثل `http://192.168.1.50:8080`).
   - خدمة ملفات تطبيق فلاتر المبنية.
   - خدمة ملفات لوحة الإدارة المبنية.
   - توفير مسارات API محلية للمزامنة اللحظية بين المتصفحين (`/api/store_settings` و `/api/support_tickets`).

---

## 3. إعداد وتهيئة قاعدة بيانات سوبابيز (Supabase Setup)

إذا كنت تنشئ مشروع Supabase جديداً أو تعيد ضبط البيئة الحالية:

1. أنشئ مشروعاً جديداً في لوحة [Supabase Dashboard](https://supabase.com).
2. افتح محرر الـ SQL (`SQL Editor`) في لوحة سوبابيز.
3. افتح الملف [`supabase/MASTER_FULL_SCHEMA_DEPLOYMENT.sql`](file:///Volumes/ssd/Projects/aldeeb_mall/supabase/MASTER_FULL_SCHEMA_DEPLOYMENT.sql) وانسخ محتواه بالكامل ثم الصقه وشغّله.
   - سيقوم هذا الملف بإنشاء كافة الجداول (31 جدولاً)، والقيود، والفهارس، وسياسات RLS، والدوال التلقائية.
4. لتعبئة المتجر بالكتالوج الرسمي النظيف للأقسام والمنتجات:
   - افتح الملف [`supabase/seed_catalog_clean.sql`](file:///Volumes/ssd/Projects/aldeeb_mall/supabase/seed_catalog_clean.sql) وشغّله في محرر الـ SQL.
5. إعداد مجلدات التخزين السحابي (Storage Buckets):
   في قسم **Storage** داخل سوبابيز، تأكد من إنشاء المجلدات التالية وتفعيل خيار **Public**:
   - `products`: لصور المنتجات.
   - `banners`: للافتات الإعلانية.
   - `avatars`: لصور الملفات الشخصية.

---

## 4. دليل النشر في بيئات الإنتاج (Production Deployment)

### 4.1 النشر التلقائي عبر GitHub Pages
المشروع مزود بمسار عمل مؤتمت كامل في [`.github/workflows/deploy.yml`](file:///Volumes/ssd/Projects/aldeeb_mall/.github/workflows/deploy.yml):
- بمجرد رفع التعديلات إلى فرع `main` (`git push origin main`)، يقوم الـ Workflow ببناء تطبيق فلاتر وبناء لوحة تحكم React، ودمجها ونشرها في مجلد موحد.
- الرابط المباشر للمتجر: `https://[username].github.io/aldeeb-mall/`
- الرابط المباشر للوحة الإدارة: `https://[username].github.io/aldeeb-mall/admin/`

### 4.2 بناء تطبيقات الهواتف الذكية (Android & iOS)

#### 1. نظام أندرويد (Android):
- توليد حزمة متجر قوقل بلاي الرسمية (AAB):
  ```bash
  cd aldeeb_mall_app
  flutter build appbundle --release
  ```
  الملف الناتج: `build/app/outputs/bundle/release/app-release.aab`
- توليد ملف التثبيت المباشر (APK) للتجربة السريعة:
  ```bash
  flutter build apk --release
  ```
  الملف الناتج: `build/app/outputs/flutter-apk/app-release.apk`

#### 2. نظام أبل (iOS):
```bash
cd aldeeb_mall_app
flutter build ipa --release
```
ثم فتح مسار `build/ios/archive/Runner.xcarchive` عبر برنامج Xcode لنشر النسخة على منصة **TestFlight**.

---

## 5. جدول المتغيرات البيئية (Environment Variables Reference)

| المتغير | الموقع المخصص | الغرض منه | هل هو سري؟ |
| :--- | :--- | :--- | :---: |
| `VITE_SUPABASE_URL` | `aldeeb_mall_admin/.env` | رابط مشروع سوبابيز للوحة الإدارة | لا (عام) |
| `VITE_SUPABASE_ANON_KEY` | `aldeeb_mall_admin/.env` | مفتاح الـ Anon العام لسوبابيز في لوحة الإدارة | لا (عام) |
| `SUPABASE_URL` | `aldeeb_mall_app/` (`--dart-define`) | رابط مشروع سوبابيز لتطبيق فلاتر | لا (عام) |
| `SUPABASE_ANON_KEY` | `aldeeb_mall_app/` (`--dart-define`) | مفتاح الـ Anon العام لسوبابيز في فلاتر | لا (عام) |
| `GOOGLE_WEB_CLIENT_ID` | `aldeeb_mall_app/` (`--dart-define`) | معرف عميل قوقل لتسجيل الدخول بـ Google | لا (عام) |

---

## 6. دليل استكشاف الأخطاء الشائعة وحلها (Troubleshooting Runbook)

1. **المشكلة**: الصوت لا يعمل عند وصول طلب جديد أو في شاشة الـ POS.
   - **السبب**: قيود المتصفحات الحديثة تمنع تشغيل `AudioContext` تلقائياً دون تفاعل مباشر من المستخدم.
   - **الحل**: انقر في أي مكان داخل الصفحة لتفعيل الصوت، وتأكد من تفعيل زر مكبر الصوت أعلى لوحة الإدارة.
2. **المشكلة**: ظهور شاشة بيضاء أو خطأ 404 عند النقر على روابط لوحة الإدارة على GitHub Pages.
   - **السبب**: مسار الـ Base HREF يحتاج مطابقة اسم المستودع.
   - **الحل**: يتم تمرير `--base=/aldeeb-mall/admin/` في أمر البناء داخل GitHub Actions لضمان توجيه المسارات بصورة صحيحة.
3. **المشكلة**: تغييرات الثيم لا تظهر فوراً في المتصفح.
   - **السبب**: الـ Service Worker يقوم بتخزين ملفات الـ Web App مؤقتاً.
   - **الحل**: قم بعمل Hard Refresh (`Cmd + Shift + R` أو `Ctrl + F5`) أو امسح الـ Cache من أدوات المطور (DevTools > Application > Storage > Clear site data).
