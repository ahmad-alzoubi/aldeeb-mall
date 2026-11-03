# 🚀 دليل التشغيل والنشر على السيرفر الفعلي — DEPLOYMENT.md
**مشروع**: منظومة «الذيب مول» الشاملة (Aldeeb Mall Hypermarket Suite)  
**تاريخ التوثيق**: 2026-11-03  
**حالة النشر الحالية**: تجهيز حزم الإنتاج والتشغيل المستقل (Docker Compose + Systemd + Nginx).

---

## 🏗️ 1. المعمارية الطوبولوجية للحزم والخدمات (Architecture Topology)

تتكون المنظومة الإنتاجية من 5 طبقات تشغيلية متكاملة:
1. **الواجهات الأمامية (Frontend Tier)**:
   - لوحة إدارة العمليات والكاشير (React 18 + Vite + Tailwind CSS) مجمعة في `dist/` ومقدمة عبر Nginx عالي الأداء.
   - تطبيق المستخدم وتطبيق Captain (Flutter Web / PWA / Android APK).
2. **الخلفية وقاعدة البيانات (Backend & Database Tier)**:
   - Supabase / PostgreSQL محلي أو سحابي مع دعم هجرات الفروع المستقلة وسياسات RLS الصارمة.
3. **خدمة معالجة الكاميرات والرؤية الحاسوبية (Computer Vision Edge Worker)**:
   - خدمة بايثون محلية لاستقبال بث RTSP/ONVIF، معالجة الإطارات عبر OpenCV/PyTorch، وعد الدخول/الخروج وحساب الإشغال.
4. **خدمة التنبؤ والذكاء المحلي (Local AI & Forecasting Worker)**:
   - خدمة بايثون خفيفة مجدولة لتدريب نماذج السلاسل الزمنية والتنبؤ بنفاد المخزون وتوليد اقتراحات التموين.
5. **طبقة الحماية والتوجيه العكسي (Reverse Proxy & Security)**:
   - Nginx مع إعدادات SSL/TLS، حماية الرؤوس الأمنية (HSTS, CSP, X-Frame)، ودعم WebSockets للبث الحي.

---

## 📦 2. متطلبات الموارد المقاسة والمقدرة (Hardware Specs)

| المكون | الحد الأدنى (Minimum) | الموصى به لـ 5 فروع و 20 كاميرا | ملاحظات |
| :--- | :--- | :--- | :--- |
| **المعالج (CPU)** | 4 Cores (x86_64 / ARM64 Apple Silicon) | 8-16 Cores | يدعم فك ترميز H.264/H.265 للكاميرات |
| **الذاكرة (RAM)** | 8 GB | 16-32 GB | تخزين تدفق الإطارات ونماذج التنبؤ |
| **التخزين (Disk)** | 50 GB SSD | 500 GB NVMe | تخزين مقاطع الفيديو والأحداث وسجلات التدقيق |
| **بطاقة الرسوميات (GPU)** | اختياري (CPU Inference مدعوم) | NVIDIA T4 / RTX أو Apple Metal (MPS) | تسريع تحليل الفيديو وتقليل استهلاك المعالج |

---

## 🔒 3. إعداد البيئة الآمنة (`.env.example`)

يمنع منعاً باتاً تضمين كلمات مرور أو مفاتيح حقيقية في المستودع. يتم إنشاء ملف `.env` انطلاقاً من النموذج التالي:

```bash
# === Aldeeb Mall Production Environment Configuration ===
NODE_ENV=production
PORT=3000

# Supabase Database & Auth (Central Instance)
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# Local Edge Vision & Camera Stream Gateway
VISION_STREAM_PORT=8554
VISION_MAX_CAMERAS=16
VISION_FPS_LIMIT=10
LOCAL_AI_WORKERS=2

# Security & Session Secrets
JWT_SECRET=generate_with_openssl_rand_hex_32
ADMIN_BOOTSTRAP_TOKEN=generate_temporary_bootstrap_token
```

---

## ⚙️ 4. تهيئة الحساب الإداري الأول (Secure Bootstrap)
- لا توجد كلمة مرور افتراضية ثابتة أو معلنة.
- يتم إنشاء الحساب الإداري الأول (Super Admin) عبر سكربت تشغيلي تفاعلي يطلب بريداً إلكترونياً وكلمة مرور قوية مع مفتاح أمان لمرة واحدة:
  ```bash
  python3 scripts/bootstrap_admin.py --email admin@aldeebmall.sy
  ```

---

## 🔄 5. النسخ الاحتياطي والاستعادة واختبار العزل (Backup & Disaster Recovery)
- يتم تنفيذ نسخ احتياطي دوري لكل قاعدة فرع على حدة باستخدام `pg_dump`:
  ```bash
  # النسخ الاحتياطي اليومي
  ./scripts/backup_databases.sh
  
  # الاستعادة والتحقق
  ./scripts/restore_database.sh --branch branch_damascus_main --backup backup_20261103.sql.gz
  ```
