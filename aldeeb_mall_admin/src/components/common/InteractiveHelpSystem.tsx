import React, { createContext, useContext, useState, useRef, ReactNode } from 'react';
import { HelpCircle, X, Sparkles, BookOpen, CheckCircle, Info, Lightbulb, Zap, ArrowRight } from 'lucide-react';

export interface FeatureHelpContent {
  id: string;
  title: string;
  category: string;
  whatIsIt: string;
  whyWeUseIt: string;
  howItWorks: string;
  businessBenefit: string;
  practicalExample: string;
}

export const FEATURE_HELP_REGISTRY: Record<string, FeatureHelpContent> = {
  dashboard: {
    id: 'dashboard',
    title: 'لوحة التحكم والعمليات المركزية',
    category: 'القيادة والرقابة',
    whatIsIt: 'شاشة القيادة الرئيسية التي تعرض النبض اللحظي للهايبرماركت، وتشمل الطلبات الحية، مؤشرات المبيعات، ومعدل إنجاز الفروع.',
    whyWeUseIt: 'لتمكين الإدارة من اتخاذ قرارات سريعة وفورية دون الحاجة للتنقل بين عشرات الجداول، ومراقبة الالتزام بمعيار التوصيل السريع (15 دقيقة).',
    howItWorks: 'تتصل مباشرة بقاعدة البيانات السحابية Supabase لتحديث طابور الطلبات فور إنشائها من التطبيق أو الكاشير وحساب المبيعات الحقيقية لحظياً.',
    businessBenefit: 'تقليل زمن معالجة الطلبات بنسبة 40%، واكتشاف أي اختناق في التجهيز قبل أن يشعر به العميل.',
    practicalExample: 'عند تسجيل طلب جديد بقيمة 15,000 ل.س من فرع درعا، يظهر فوراً في طابور التجهيز مع تشغيل رنين صوتي لتنبيه فريق التحضير.'
  },
  active_branch_isolation: {
    id: 'active_branch_isolation',
    title: 'نظام تبديل الفرع النشط والعزل الصارم',
    category: 'الحوكمة وإدارة الفروع',
    whatIsIt: 'آلية تصفية وعزل شاملة تضمن أن تكون جميع البيانات المعروضة (المبيعات، المخزون، الطلبات، الموظفين، المناديب) خاصة بالفرع المحدد حالياً.',
    whyWeUseIt: 'لمنع تداخل عمليات الفروع وحماية خصوصية بيانات كل فرع، وتجنب الخطأ في صرف بضاعة أو إسناد طلب لفرع آخر.',
    howItWorks: 'عند اختيار فرع جديد، يتم حجب البيانات السابقة وعرض شاشة تحميل ريثما يتم تصفية الاستعلامات بـ branch_id المحدد، مع وسم الأرقام المؤسسية بوضوح.',
    businessBenefit: 'دقة محاسبية 100% لكل فرع بشكل مستقل مع منع الأخطاء التشغيلية الناتجة عن التداخل الجغرافي.',
    practicalExample: 'التبديل من "هايبرماركت الرياض" إلى "فرع درعا المحطة" يعرض فقط فواتير درعا ومخزون مستودع درعا وطاقم موظفي درعا.'
  },
  staff_management: {
    id: 'staff_management',
    title: 'إدارة الموظفين والصلاحيات (RBAC)',
    category: 'الموارد البشرية والأمان',
    whatIsIt: 'وحدة التحكم في حسابات طاقم العمل (مدير عام، كاشير، أمين مستودع، مندوب توصيل) وتعيين كلمات المرور والورديات.',
    whyWeUseIt: 'لضمان عدم وصول أي موظف إلا للوظائف المخصصة لدوره، وتأمين النظام ضد التعديلات غير المصرح بها.',
    howItWorks: 'تحدد صلاحيات صارمة لكل دور (Permissions Matrix)؛ وعند تعطيل حساب موظف يتم إنهاء جلسته النشطة فوراً ومنعه من إجراء أي حركة.',
    businessBenefit: 'حماية الأصول النقدية والمخزنية ومتابعة مسؤولية كل عملية عبر سجل تدقيق إلكتروني غير قابل للتعديل.',
    practicalExample: 'إذا حاول كاشير الدخول إلى صفحة الموردين أو تعديل أسعار المنتجات، يمنعه النظام فوراً لعدم امتلاكه صلاحية التسعير.'
  },
  accounting_payroll: {
    id: 'accounting_payroll',
    title: 'المحاسبة والرواتب وحماية الأجور (WPS)',
    category: 'المالية والمحاسبة',
    whatIsIt: 'نظام مالي متكامل لإدارة مستحقات الموظفين، البدلات، الخصومات التأديبية، ومسيرات الرواتب الشهرية.',
    whyWeUseIt: 'لأتمتة العمليات المالية وتوثيق كافة الصرفيات والخصومات وفق معايير الحوكمة المالية.',
    howItWorks: 'يسجل الراتب الأساسي والبدلات لكل موظف ويحسب صافي المستحق تلقائياً مع تسجيل أثر كل عملية محاسبية في سجلات التدقيق.',
    businessBenefit: 'توفير الوقت المحاسبي بنسبة 70% وتفادي الخلافات العمالية عبر تقارير واضحة لكل موظف.',
    practicalExample: 'تسجيل مكافأة أداء بقيمة 2,000 ل.س لموظف الكاشير الأكثر دقة، فينعكس المبلغ فوراً في مسير راتبه للشهر الحالي.'
  },
  analytics: {
    id: 'analytics',
    title: 'ذكاء الأعمال والتحليلات الحقيقية (BI)',
    category: 'التقارير والتحليلات',
    whatIsIt: 'محرك إحصائي متطور يحسب صافي الإيرادات، المبيعات الإجمالية، أرباح المنتجات، والخصومات والمرتجعات بدون أي أرقام وهمية.',
    whyWeUseIt: 'لمعرفة الأداء التجاري الفعلي للمول، وتحديد الأقسام الأكثر ربحية والمنتجات الراكدة.',
    howItWorks: 'يجري استعلامات تجميعية حقيقية على جداول الفواتير والطلبات والمرتجعات، مع مراعاة الفلاتر الزمنية (يومي، أسبوعي، شهري، ومخصص).',
    businessBenefit: 'اتخاذ قرارات الشراء والتسعير والتسويق بناءً على بيانات مالية مثبتة بدلاً من التخمين.',
    practicalExample: 'إذا بلغت المبيعات 100,000 ل.س وسجلت مرتجعات بـ 10,000 ل.س، يظهر صافي الإيراد الحقيقي 90,000 ل.س بدقة رياضية.'
  },
  forecasting: {
    id: 'forecasting',
    title: 'التنبؤ الذكي بالطلب وإدارة المخزون',
    category: 'سلاسل الإمداد والتخطيط',
    whatIsIt: 'خوارزميات إحصائية لتحليل السلاسل الزمنية والمعدلات المتحركة لتوقع احتياجات الفروع من المنتجات قبل نفادها.',
    whyWeUseIt: 'لتفادي خسارة المبيعات الناتجة عن نفاد البضاعة (Stockouts)، وتجنب تراكم المنتجات بطيئة الحركة وتلفها.',
    howItWorks: 'يقيس معدل السحب اليومي ومستوى المخزون الحالي ويحدد "نقطة إعادة الطلب" مع حساب نسبة الدقة ومستوى الثقة.',
    businessBenefit: 'خفض تكاليف التخزين الراكد بنسبة 25% وضمان توفر السلع الأساسية بنسبة تفوق 98%.',
    practicalExample: 'النظام يرصد أن حليب نادك 2 لتر يُباع منه 30 عبوة يومياً والمتبقي 15 فقط، فيقترح تلقائياً أمر شراء 100 عبوة قبل 24 ساعة من النفاد.'
  },
  orders: {
    id: 'orders',
    title: 'إدارة الطلبات الفورية وتتبع الحالات',
    category: 'العمليات والتنفيذ',
    whatIsIt: 'مركز معالجة طلبات العملاء من لحظة التأكيد حتى التسليم، متضمناً دورة الحالات: معلق ← قيد التجهيز ← جاهز ← مع المندوب ← تم التسليم.',
    whyWeUseIt: 'لتنسيق العمل بين موظف الفرز، والكاشير، ومندوب التوصيل، وإطلاع العميل لحظياً على حالة طلبه.',
    howItWorks: 'تحديثات فورية ثنائية الاتجاه؛ كل تغيير للحالة في لوحة الإدارة أو تطبيق المندوب ينعكس فوراً لدى العميل.',
    businessBenefit: 'القضاء على ضياع الطلبات وتقليص وقت التجهيز إلى أقل من 8 دقائق في المتوسط.',
    practicalExample: 'عند ضغط زر "تم التجهيز"، يتم إرسال إشعار فوري لمندوب التوصيل المتاح لاستلام الطلب والانطلاق.'
  },
  operations_tower: {
    id: 'operations_tower',
    title: 'برج المراقبة المؤتمت (Control Tower)',
    category: 'العمليات والإنذار المبكر',
    whatIsIt: 'نظام مراقبة استباقي يكتشف الأعطال التشغيلية تلقائياً دون إغراق المدير بإنذارات تافهة.',
    whyWeUseIt: 'ليعمل النظام كمساعد ذكي ينبهك فقط عند وجود مشكلة تتطلب التدخل البشري الحقيقي.',
    howItWorks: 'يراقب: الطلبات المتأخرة عن 15 دقيقة، المنتجات القريبة من انتهاء الصلاحية، المناقلات العالقة، والطلبات الفاشلة ويقترح حلولاً فورية.',
    businessBenefit: 'منع الخسائر التشغيلية قبل تفاقمها وحماية سمعة المتجر وجودة الخدمة.',
    practicalExample: 'تنبيه يوضح: "الطلب #1042 متأخر 7 دقائق عن وقت التجهيز في فرع درعا" مع زر بنقرة واحدة لإعادة توجيهه إلى مجهز آخر.'
  },
  fulfillment: {
    id: 'fulfillment',
    title: 'المستودعات الذكية والفرز (WMS)',
    category: 'المستودعات والخدمات اللوجستية',
    whatIsIt: 'إدارة المستودعات المستقلة وأماكن التخزين (Bins & Shelves)، ومسارات الفرز السريع للطلبات.',
    whyWeUseIt: 'لتحقيق التجهيز فائق السرعة خلال 5 إلى 10 دقائق وتفادي البحث العشوائي عن المنتجات في الرفوف.',
    howItWorks: 'توزيع الأصناف حسب مناطق التخزين وتوليد قوائم التقاط ذكية (Picker Batches) ترتب المنتجات بأقصر مسار مشي.',
    businessBenefit: 'مضاعفة إنتاجية عاملي التجهيز 3 مرات وتقليل نسبة أخطاء اختيار المنتجات إلى الصفر تقريباً.',
    practicalExample: 'يقوم الجامع بمسح باركود الرف ثم باركود الصنف للتأكد من جمع الصنف والوزن الصحيح المطلوب بدقة.'
  },
  inventory_transfer: {
    id: 'inventory_transfer',
    title: 'مناقلات الفروع والمستودعات والمطابقة',
    category: 'المخزون وسلاسل الإمداد',
    whatIsIt: 'دورة نقل البضائع الرسمية: إنشاء طلب النقل ← الاعتماد ← الإرسال ← الاستلام ← المطابقة والتسوية.',
    whyWeUseIt: 'لضبط حركة المخزون بين المستودعات المركزية والفروع ومنع التلف أو الضياع أو ازدواجية القيد.',
    howItWorks: 'يتم حجز الكمية المنقولة في المستودع المصدر ولا تضاف للفرع المستلم إلا بعد تأكيد الاستلام الفعلي ومطابقة الباركود.',
    businessBenefit: 'تطابق محاسبي بنسبة 100% بين الأرصدة الدفترية والمخزون الفعلي على الأرفف.',
    practicalExample: 'نقل 50 كيس أرز من المستودع المركزي إلى فرع طفس؛ المستودع يرسل 50، والفرع يستلم ويؤكد وصول الـ 50 كاملة أو يسجل العجز مبرراً.'
  },
  products: {
    id: 'products',
    title: 'كتالوج المنتجات ومسح الباركود والوسائط',
    category: 'الكتالوج والتسعير',
    whatIsIt: 'سجل المنتجات الشامل متضمناً الباركود، الأسعار، التكلفة، الصور المرفوعة من الجهاز، وتكامل البحث بالباركود المفتوح.',
    whyWeUseIt: 'لإدارة كافة السلع المعروضة للبيع، وتوفير معلومات وصور احترافية للعملاء والكاشير.',
    howItWorks: 'يدعم مسح الباركود للبحث التلقائي عبر قاعدة Open Food Facts لاقتراح الاسم والصورة، مع رفع مباشر للصور وترتيبها.',
    businessBenefit: 'تسريع إدخال المنتجات الجديدة من 5 دقائق إلى 30 ثانية لكل منتج، ومنع الأخطاء في الأسعار.',
    practicalExample: 'مسح باركود عبوة شاي يملأ تلقائياً اسمها وعلامتها التجارية وتصنيفها، ويحفظها كمسودة للمراجعة قبل عرضها للبيع.'
  },
  categories: {
    id: 'categories',
    title: 'أقسام وتصنيفات المول وتوزيع الواجهة',
    category: 'الكتالوج والتنظيم',
    whatIsIt: 'شجرة الأقسام الرئيسية والفرعية (خضار وفواكه، لحوم وأسماك، ألبان، تموينات...) مع إمكانية الترتيب بالسحب والإفلات.',
    whyWeUseIt: 'لتسهيل تصفح المتجر على العميل في التطبيق وتنظيم توزيع المنتجات فيزيائياً ورقمياً.',
    howItWorks: 'يرتبط كل منتج بقسم محدد، مع دعم رفع أيقونة وصورة القسم مباشرة من الجهاز ومتابعة إحصائيات المبيعات لكل قسم.',
    businessBenefit: 'تحسين تجربة التسوق وزيادة متوسط حجم السلة عبر تسهيل الوصول للأقسام الأكثر طلباً.',
    practicalExample: 'وضع قسم "العروض والتوفير" في قمة الأقسام يزيد زيارات المنتجات المخفضة بنسبة 35%.'
  },
  suppliers: {
    id: 'suppliers',
    title: 'الموردون وأوامر وفواتير الشراء',
    category: 'المشتريات وسلاسل الإمداد',
    whatIsIt: 'إدارة ملفات الموردين، وإصدار أوامر الشراء، وفواتير الاستلام مع إمكانية إدخال منتجات جديدة مباشرة كمسودات.',
    whyWeUseIt: 'لإحكام السيطرة على تكلفة البضاعة المباعة ومتابعة استحقاقات الموردين ومواعيد التوريد.',
    howItWorks: 'عند اعتماد فاتورة الشراء يتم تحديث كميات المخزون وتكلفة المنتج، وتسجيل حالة السداد (مدفوع / آجل / جزئي).',
    businessBenefit: 'حساب دقيق لصافي الأرباح بناءً على تكلفة الشراء الحقيقية وليس التقديرية.',
    practicalExample: 'شراء 200 صندوق زيت من "شركة الخير"، الفاتورة تسجل التكلفة وتضيف الكمية لمستودع الاستلام المعتمد فوراً.'
  },
  fleet: {
    id: 'fleet',
    title: 'أسطول التوصيل الموحد وتتبع المندوبين',
    category: 'التوصيل والخدمات اللوجستية',
    whatIsIt: 'منظومة إدارة مناديب التوصيل: تتبع الحالات (متاح، مشغول، غير متصل)، إسناد الطلبات، ومتابعة أداء كل كابتن.',
    whyWeUseIt: 'لتشغيل أسطول التوصيل بكفاءة وتوزيع الطلبات بعدالة وسرعة لضمان التوصيل في الوقت المحدد.',
    howItWorks: 'يرتبط مباشرة بطلبات الفروع؛ يسجل المندوب بدء ونهاية ورديته، ويستلم مهام التوصيل مع إثبات التسليم عبر كود العميل.',
    businessBenefit: 'خفض متوسط زمن التوصيل ومراقبة معدل نجاح التسليم من المحاولة الأولى بنسبة تتجاوز 95%.',
    practicalExample: 'إسناد طلب لفرع درعا المحطة للكابتن "أحمد" القريب من الموقع، فيصل إشعار له بالخريطة ورقم هاتف العميل.'
  },
  flash_deals: {
    id: 'flash_deals',
    title: 'عروض الفلاش والتخفيضات محددة الوقت',
    category: 'التسويق والمبيعات',
    whatIsIt: 'أداة إنشاء حملات تخفيض قوية محدودة بزمن وكمية محددة مع قياس أداء الحملة الحقيقي (مشاهدات، نقرات، ومبيعات).',
    whyWeUseIt: 'لخلق شعور بالإلحاح (FOMO) لدى المتسوقين وتصريف كميات كبيرة من السلع خلال وقت قياسي.',
    howItWorks: 'تحديد وقت البداية والنهاية وسعر العرض والحد الأقصى لكل عميل، مع عزل أرباح ومبيعات العرض عن المبيعات الاعتيادية.',
    businessBenefit: 'زيادة المبيعات اللحظية بنسبة تصل إلى 200% وجذب عملاء جدد للتطبيق.',
    practicalExample: 'عرض فلاش على زيت القلي بخصم 30% لمدة 4 ساعات فقط، أو حتى نفاد 100 عبوة مخصصة للعرض.'
  },
  coupons: {
    id: 'coupons',
    title: 'الكوبونات وقواعد الخصم المانعة للتضارب',
    category: 'التسويق والعروض',
    whatIsIt: 'محرك خصومات ذكي يدعم الكوبونات بالنسبة المئوية أو القيمة الثابتة، مع شروط دقيقة (الحد الأدنى، الاستخدام لكل عميل، الفروع).',
    whyWeUseIt: 'لمكافأة العملاء المخلصين وتشجيع إعادة الشراء بطريقة آمنة محاسبياً.',
    howItWorks: 'التحقق البرمجي على مستوى السلة والكاشير من مطابقة شروط الكود ومنع تكرار الاستخدام غير المصرح به أو تضارب الخصومات.',
    businessBenefit: 'زيادة معدل ولاء العملاء (Customer Retention) مع ضمان عدم هدر الهوامش الربحية للمتجر.',
    practicalExample: 'كوبون "DARAA10" يمنح خصم 10% للطلبات التي تزيد عن 50,000 ل.س داخل نطاق محافظة درعا فقط وبحد أقصى مرتين لكل عميل.'
  },
  banners: {
    id: 'banners',
    title: 'البنرات التفاعلية والواجهة الرئيسية',
    category: 'التسويق وتجربة المستخدم',
    whatIsIt: 'إدارة البنرات الإعلانية التفاعلية في تطبيق العملاء، مع تحديد الروابط والوجهات وتتبع النقرات الفعلي.',
    whyWeUseIt: 'لتوجيه انتباه المتسوقين لأهم الحملات والمنتجات والأقسام ذات الأولوية التجارية.',
    howItWorks: 'رفع صور محسنة، وتحديد القسم أو المنتج المستهدف وتاريخ سريان البنر وحالته (نشط / مجدول / معطل).',
    businessBenefit: 'زيادة معدل النقر للتحويل (CTR) بنسبة تفوق 25% وتنشيط الحركة على السلع المستهدفة.',
    practicalExample: 'بنر ترويجي لموسم المدارس يوجه العميل مباشرة عند النقر إلى قسم القرطاسية والمستلزمات.'
  },
  zones: {
    id: 'zones',
    title: 'نطاقات التغطية الجغرافية (سوريا ومحافظة درعا)',
    category: 'الخدمات اللوجستية والتوسع',
    whatIsIt: 'تحديد المناطق الجغرافية المشمولة بالخدمة (درعا المحطة، درعا البلد، طفس، إزرع، الصنمين...) مع رسوم التوصيل والحد الأدنى للطلب.',
    whyWeUseIt: 'لضمان قبول الطلبات فقط من العناوين التي يغطيها أسطول التوصيل بكفاءة دون تأخير أو خسائر.',
    howItWorks: 'التحقق التلقائي عند إدخال العميل لعنوانه من كونه ضمن النطاقات المعتمدة وتطبيق رسوم التوصيل المخصصة للمنطقة.',
    businessBenefit: 'ضبط التكاليف اللوجستية وتقديم وعود توصيل واقعية تلتزم بها الفروع بدقة.',
    practicalExample: 'طلب في "درعا المحطة" رسوم توصيله 2,000 ل.س بحد أدنى 10,000 ل.س، بينما التوصيل لـ "إزرع" يخضع لرسوم ومدة مخصصة.'
  },
  subscriptions: {
    id: 'subscriptions',
    title: 'باقات الاشتراكات VIP والدفع عبر شام كاش',
    category: 'الإيرادات المتكررة والولاء',
    whatIsIt: 'نظام العضويات المميزة (توصيل مجاني، خصومات حصرية) مع دعم الدفع الآمن والمراجعة اليدوية عبر شام كاش (Sham Cash).',
    whyWeUseIt: 'لبناء تدفق إيرادات شهري متكرر (MRR) وتمكين العملاء في سوريا من الدفع بأسهل الطرق المتاحة محلياً.',
    howItWorks: 'العميل يرفع إشعار تحويل شام كاش؛ تظهر العملية في الإدارة كـ "بانتظار مراجعة الدفع"، وبعد مطابقة الإشعار المالي يتم التفعيل فوراً مع منع تكرار الإيصال.',
    businessBenefit: 'رفع القيمة الدائمة للعميل (LTV) وتأمين عمليات التحويل المالي ضد التزييف أو الاحتيال.',
    practicalExample: 'عميل يشترك في باقة "VIP الذهبية" ويحول 25,000 ل.س عبر شام كاش، يراجع المحاسب الإيصال ويوافق عليه فتفعل المزايا تلقائياً في حسابه.'
  },
  loyalty: {
    id: 'loyalty',
    title: 'برنامج الولاء ومكافآت النقاط',
    category: 'الولاء وتجربة العملاء',
    whatIsIt: 'نظام حساب نقاط الشراء واستبدالها بكوبونات أو منتجات مجانية وفق قواعد عادلة ومثبتة.',
    whyWeUseIt: 'لتحفيز العميل على تفضيل الديب مول في كل مشترياته العائلية لجمع النقاط والحصول على مكافآت.',
    howItWorks: 'تُمنح النقاط تلقائياً بعد اكتمال الطلب ودفع قيمته، وتُخصم عند استبدالها بخصم أو مكافأة، مع إلغائها تلقائياً في حال استرجاع الطلب.',
    businessBenefit: 'زيادة تكرار زيارات العميل ومشترياته بنسبة 45% وتحويل الزبائن العاديين إلى سفراء للمول.',
    practicalExample: 'يحصل العميل على 100 نقطة عند الشراء بقيمة 10,000 ل.س، ويمكنه استبدال 500 نقطة بقسيمة خصم بقيمة 2,500 ل.س.'
  },
  returns: {
    id: 'returns',
    title: 'المرتجعات والنزاعات والتسويات المالية',
    category: 'خدمة العملاء والمالية',
    whatIsIt: 'دورة استرجاع البضائع المباعة: تقديم الطلب، فحص الحالة، الموافقة، وإرجاع الرصيد للمخزون واسترداد المبلغ للعميل.',
    whyWeUseIt: 'لضمان حقوق المستهلك وامتثال المتجر للقوانين التجارية مع حماية المتجر من الاسترجاع المزدوج أو الاحتيالي.',
    howItWorks: 'يسجل طلب الإرجاع برقم الفاتورة الأصلية وسبب الإرجاع مع إرفاق الصور، وعند القبول تضاف الكمية للمخزون التالف أو الصالح محاسبياً.',
    businessBenefit: 'كسب ثقة العملاء العالية وضبط حركة النقدية والمخزون بدقة تامة دون تضارب.',
    practicalExample: 'استرجاع عبوة جبنة معطوبة بقيمة 4,000 ل.س: يسجل النظام سبب التلف، يعيد المبلغ لمحفظة العميل، ويسجل تلف الصنف في المستودع.'
  },
  support: {
    id: 'support',
    title: 'خدمة العملاء والشكاوى وتذاكر المتابعة',
    category: 'خدمة العملاء ورضا المستهلك',
    whatIsIt: 'منصة مركزية لاستقبال شكاوى واستفسارات المتسوقين وربطها برقم الطلب وتكليف موظف الدعم بمتابعتها.',
    whyWeUseIt: 'لحل المشاكل التشغيلية فوراً قبل أن تتحول إلى استياء أو تقييمات سلبية للمتجر.',
    howItWorks: 'فتح تذكرة ذات أولوية (منخفضة، متوسطة، عاجلة)، تسجيل الردود المتبادلة، وإغلاق التذكرة بعد تأكيد رضا العميل.',
    businessBenefit: 'رفع نسبة رضا العملاء والاحتفاظ بهم وتحديد نقاط الضعف المتكررة لمعالجتها جذرياً.',
    practicalExample: 'عميل يبلغ عن نقص سلعة في طلبه، يفتح موظف الدعم تذكرة عاجلة، ويتم إرسال السلعة الناقصة فوراً مع هدية ترضية.'
  },
  pos_terminal: {
    id: 'pos_terminal',
    title: 'بوابة الكاشير ونقاط البيع المستقلة (POS)',
    category: 'المبيعات ونقاط البيع',
    whatIsIt: 'نظام الكاشير الميداني فائق السرعة المزود بمسح الباركود، حساب الضرائب والخصومات، وطباعة الفاتورة الإلكترونية.',
    whyWeUseIt: 'لخدمة عملاء الصالة وسرعة المحاسبة على خطوط الدفع بدون تأخير حتى عند انقطاع الإنترنت اللحظي.',
    howItWorks: 'تمتلك رابطاً مستقلاً (/#pos) مع عزل كامل عن لوحة الإدارة العامة، وترتبط آنياً بالمخزون والمبيعات وسجلات الكاشير.',
    businessBenefit: 'تقليص وقت خدمة العميل الواحد أمام الكاشير إلى أقل من 25 ثانية مع دقة جرد كاملة.',
    practicalExample: 'يقوم الكاشير بمسح 5 سلع بالباركود، يطبق كوبون خصم للعميل، يطبع الفاتورة المتوافقة، ويخصم الكميات من رصيد الفرع فوراً.'
  },
  invoice_designer: {
    id: 'invoice_designer',
    title: 'تصميم الفواتير والباركود ورمز QR المعتمد',
    category: 'الهوية المؤسسية والامتثال',
    whatIsIt: 'محرر تصميم الفاتورة الحرارية وفاتورة التوصيل، بما يشمل شعار المول، بيانات الفرع، الشروط، ورمز الاستجابة السريعة QR.',
    whyWeUseIt: 'لضمان مظهر احترافي وموحد لكافة فواتير المول والامتثال لمتطلبات الفوترة الرسمية.',
    howItWorks: 'معاينة حية للتصميم أثناء التعديل مع دعم طباعة الباركود لكل طلب وتخصيص التذييل والرسائل الترويجية.',
    businessBenefit: 'تعزيز العلامة التجارية وطمأنة العميل بمصداقية الفاتورة ومطابقتها للمواصفات.',
    practicalExample: 'تضمين رمز QR على الفاتورة يتيح للعميل مسح الكود بهاتفه لتتبع طلبه أو مراجعة التفاصيل إلكترونياً.'
  }
};

interface HelpContextType {
  isHelpModeActive: boolean;
  toggleHelpMode: () => void;
  openHelpModal: (featureId: string) => void;
  closeHelpModal: () => void;
  activeHelpContent: FeatureHelpContent | null;
}

const HelpContext = createContext<HelpContextType>({
  isHelpModeActive: false,
  toggleHelpMode: () => {},
  openHelpModal: () => {},
  closeHelpModal: () => {},
  activeHelpContent: null,
});

export const useHelp = () => useContext(HelpContext);

export const HelpProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isHelpModeActive, setIsHelpModeActive] = useState<boolean>(false);
  const [activeHelpContent, setActiveHelpContent] = useState<FeatureHelpContent | null>(null);

  const toggleHelpMode = () => {
    setIsHelpModeActive(prev => !prev);
  };

  const openHelpModal = (featureId: string) => {
    const content = FEATURE_HELP_REGISTRY[featureId] || {
      id: featureId,
      title: `دليل الميزة: ${featureId}`,
      category: 'عام',
      whatIsIt: 'إحدى الوظائف التشغيلية في منصة إدارة الديب مول المتكاملة.',
      whyWeUseIt: 'لإنجاز العمليات اليومية بكفاءة ودقة وحوكمة رقمية متطورة.',
      howItWorks: 'تتصل بقاعدة البيانات المركزية لتنفيذ الإجراء والتحقق من الصلاحيات والفرع النشط.',
      businessBenefit: 'توفير الوقت وحماية الأصول وتقديم أفضل تجربة للمتسوقين وفريق العمل.',
      practicalExample: 'الاستخدام المباشر عبر الأزرار والنماذج المخصصة للتحكم بالبيانات.'
    };
    setActiveHelpContent(content);
  };

  const closeHelpModal = () => {
    setActiveHelpContent(null);
  };

  return (
    <HelpContext.Provider value={{ isHelpModeActive, toggleHelpMode, openHelpModal, closeHelpModal, activeHelpContent }}>
      {children}
      {/* Global Interactive Help Modal */}
      {activeHelpContent && (
        <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 animate-fade-in" dir="rtl">
          <div className="bg-white rounded-3xl shadow-2xl border border-slate-200 w-full max-w-2xl overflow-hidden animate-scale-up">
            {/* Modal Header */}
            <div className="bg-gradient-to-r from-blue-700 via-indigo-700 to-blue-800 text-white p-6 relative">
              <button
                onClick={closeHelpModal}
                className="absolute top-5 left-5 w-8 h-8 rounded-full bg-white/20 hover:bg-white/30 text-white flex items-center justify-center text-xs font-bold transition-all"
                title="إغلاق"
              >
                ✕
              </button>

              <div className="flex items-center gap-2 text-blue-200 text-xs font-bold mb-2">
                <span className="px-2.5 py-0.5 rounded-full bg-white/15 border border-white/20">
                  {activeHelpContent.category}
                </span>
                <span>• نظام المساعدة التفاعلي 3-Clicks</span>
              </div>

              <h3 className="text-xl md:text-2xl font-black text-white flex items-center gap-2.5">
                <BookOpen className="w-6 h-6 text-amber-300" />
                {activeHelpContent.title}
              </h3>
            </div>

            {/* Modal Body */}
            <div className="p-6 md:p-8 space-y-5 max-h-[75vh] overflow-y-auto text-slate-800">
              {/* 1. What is it */}
              <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/80 space-y-1.5">
                <div className="flex items-center gap-2 text-blue-700 font-extrabold text-xs">
                  <Info className="w-4 h-4" />
                  <span>1. ما هذه الميزة؟ (What is it?)</span>
                </div>
                <p className="text-xs md:text-sm text-slate-700 leading-relaxed font-medium">
                  {activeHelpContent.whatIsIt}
                </p>
              </div>

              {/* 2. Why we use it */}
              <div className="p-4 rounded-2xl bg-indigo-50/60 border border-indigo-100 space-y-1.5">
                <div className="flex items-center gap-2 text-indigo-700 font-extrabold text-xs">
                  <Lightbulb className="w-4 h-4 text-amber-600" />
                  <span>2. لماذا نستخدمها؟ (Why we use it?)</span>
                </div>
                <p className="text-xs md:text-sm text-slate-700 leading-relaxed font-medium">
                  {activeHelpContent.whyWeUseIt}
                </p>
              </div>

              {/* 3. How it works */}
              <div className="p-4 rounded-2xl bg-emerald-50/60 border border-emerald-100 space-y-1.5">
                <div className="flex items-center gap-2 text-emerald-800 font-extrabold text-xs">
                  <Zap className="w-4 h-4 text-emerald-600" />
                  <span>3. كيف تعمل؟ (How it works?)</span>
                </div>
                <p className="text-xs md:text-sm text-slate-700 leading-relaxed font-medium">
                  {activeHelpContent.howItWorks}
                </p>
              </div>

              {/* 4. Business benefit */}
              <div className="p-4 rounded-2xl bg-amber-50/60 border border-amber-200/80 space-y-1.5">
                <div className="flex items-center gap-2 text-amber-800 font-extrabold text-xs">
                  <Sparkles className="w-4 h-4 text-amber-600" />
                  <span>4. ما فائدتها العملية للمول؟ (Business Benefit)</span>
                </div>
                <p className="text-xs md:text-sm text-slate-700 leading-relaxed font-medium">
                  {activeHelpContent.businessBenefit}
                </p>
              </div>

              {/* 5. Practical example */}
              <div className="p-4 rounded-2xl bg-purple-50/60 border border-purple-100 space-y-1.5">
                <div className="flex items-center gap-2 text-purple-800 font-extrabold text-xs">
                  <ArrowRight className="w-4 h-4 text-purple-600" />
                  <span>5. مثال عملي مبسط (Practical Example)</span>
                </div>
                <p className="text-xs md:text-sm text-slate-700 leading-relaxed font-semibold">
                  {activeHelpContent.practicalExample}
                </p>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-4 bg-slate-50 border-t border-slate-200 flex items-center justify-between">
              <span className="text-[11px] text-slate-500 font-medium">
                💡 تلميح: يمكنك النقر 3 مرات متتالية على أي قسم لفتح شرحه فوراً.
              </span>
              <button
                onClick={closeHelpModal}
                className="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs shadow-md transition-all"
              >
                فهمت ذلك، إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </HelpContext.Provider>
  );
};

/**
 * Interactive Help Trigger Component
 * Safe 3-clicks detector that prevents accidental triggering of the primary action.
 */
interface HelpTriggerProps {
  featureId: string;
  children: ReactNode;
  className?: string;
  onClick?: (e: React.MouseEvent) => void;
  showHelpPill?: boolean;
}

export const InteractiveHelpTrigger: React.FC<HelpTriggerProps> = ({
  featureId,
  children,
  className = '',
  onClick,
  showHelpPill = false,
}) => {
  const { isHelpModeActive, openHelpModal } = useHelp();
  const clickCountRef = useRef(0);
  const clickTimerRef = useRef<NodeJS.Timeout | null>(null);

  const handleClick = (e: React.MouseEvent) => {
    // If Help Mode is toggled ON, immediately show help without firing the action
    if (isHelpModeActive) {
      e.preventDefault();
      e.stopPropagation();
      openHelpModal(featureId);
      return;
    }

    clickCountRef.current += 1;

    if (clickCountRef.current === 3) {
      // 3 clicks reached! Prevent underlying action and show help modal!
      e.preventDefault();
      e.stopPropagation();
      if (clickTimerRef.current) clearTimeout(clickTimerRef.current);
      clickCountRef.current = 0;
      openHelpModal(featureId);
      return;
    }

    // Set timer to reset click count after 700ms
    if (clickTimerRef.current) clearTimeout(clickTimerRef.current);
    clickTimerRef.current = setTimeout(() => {
      clickCountRef.current = 0;
    }, 700);

    // Normal click handler
    if (onClick) {
      onClick(e);
    }
  };

  return (
    <div
      onClick={handleClick}
      className={`relative cursor-pointer transition-all ${
        isHelpModeActive ? 'ring-2 ring-amber-400 ring-offset-2 rounded-xl' : ''
      } ${className}`}
      title={isHelpModeActive ? 'انقر لعرض الشرح التفاعلي لهذا القسم' : 'انقر 3 مرات متتالية لعرض الشرح التفاعلي'}
    >
      {children}
      {showHelpPill && (
        <button
          type="button"
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            openHelpModal(featureId);
          }}
          className="inline-flex items-center gap-1 text-[10px] text-amber-700 bg-amber-100 hover:bg-amber-200 px-2 py-0.5 rounded-full font-bold border border-amber-300 ml-2 transition-colors"
          title="شرح الوظيفة"
        >
          <HelpCircle className="w-3 h-3" />
          <span>شرح الوظيفة</span>
        </button>
      )}
    </div>
  );
};
