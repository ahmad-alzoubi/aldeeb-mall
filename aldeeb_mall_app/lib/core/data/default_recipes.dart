import '../models/recipe_model.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';

class DefaultRecipes {
  static ProductModel _find(String id, String fallbackName, double fallbackPrice) {
    final canonicalId = SupabaseService.mapProductIdToCanonical(id);
    return SupabaseService.defaultProducts.firstWhere(
      (p) => p.id == id || p.id == canonicalId,
      orElse: () => ProductModel(
        id: canonicalId,
        nameAr: fallbackName,
        nameEn: fallbackName,
        price: fallbackPrice,
        images: const ['https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80'],
      ),
    );
  }

  static List<RecipeModel> getRecipes() {
    // Products
    final pBanana = _find('p1', 'موز كافنديش طازج', 4.95);
    final pApple = _find('p2', 'تفاح رويال جالا', 7.50);
    final pTomato = _find('p3', 'طماطم مزارع محلية', 3.75);
    final pMilk = _find('p4', 'حليب المراعي 2 لتر', 11.00);
    final pCheese = _find('p5', 'جبنة بوك كريمية', 14.50);
    final pChicken = _find('p6', 'دجاج التنمية طازج مبرد', 16.75);
    final pCroissant = _find('p7', 'كرواسان فرنسي بالزبدة', 8.50);
    final pWater = _find('p8', 'مياه العين الطبيعية', 12.95);
    final pVeal = _find('p10', 'لحم عجل بلدي مفروم', 38.00);
    final pSalmon = _find('p11', 'فيليه سلمون نرويجي', 44.50);
    final pSteak = _find('p12', 'ستيك ريب آي أنجوس', 52.00);
    final pEggs = _find('p13', 'بيض مزارع عضوي', 22.50);
    final pLabneh = _find('p14', 'لبنة تركية فاخرة', 12.00);
    final pSourdough = _find('p15', 'خبز ساوردو ريفيّ', 9.50);
    final pBaklava = _find('p16', 'بقلاوة مشكلة بالفستق', 29.00);
    final pJuice = _find('p17', 'عصير برتقال طبيعي', 14.00);
    final pCoffee = _find('p18', 'قهوة عربية بالزعفران', 19.50);
    final pOliveOil = _find('p21', 'زيت زيتون بكر ممتاز', 26.00);
    final pBasmatiRice = _find('p22', 'أرز بسمتي هندي عنبر', 22.00);
    final pAlmondMilk = _find('p23', 'حليب لوز نباتي عضوي', 15.50);
    final pChickenBreast = _find('p24', 'صدور دجاج فيليه', 18.50);
    final pHoney = _find('p25', 'عسل سدر جبلي نقي', 35.00);
    final pAvocado = _find('p26', 'أفوكادو هاس مكسيكي', 9.50);
    final pOats = _find('p27', 'شوفان عضوي حبوب كاملة', 8.50);

    return [
      // 1. كبسة الدجاج الخليجية (طبخ رئيسي)
      RecipeModel(
        id: 'rcp-kabsa',
        titleAr: 'كبسة الدجاج الخليجية الفاخرة بالبهارات المعتقة',
        titleEn: 'Gulf Spiced Royal Chicken Kabsa with Basmati',
        category: 'أطباق رئيسية',
        prepTime: '40 دقيقة',
        cookTimeMinutes: 40,
        servings: '4-5 أشخاص',
        difficulty: 'سهل',
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=800&q=80',
        discountPercent: 18,
        calories: 540,
        rating: 4.9,
        reviewsCount: 384,
        allergens: const [],
        dietaryTags: const ['خالٍ من الجلوتين', 'خالٍ من اللاكتوز', 'بروتين عالي'],
        steps: const [
          'يُغسل الدجاج جيداً ويفرك بالليمون وتتبيلة الكبسة الخليجية.',
          'في قدر عميق، يُسخن زيت الزيتون ويشوح البصل المفروم والطماطم حتى تتسبك.',
          'يُضاف الدجاج ويقلب حتى يكتسب لوناً ذهبياً ثم يضاف الماء المغلي ويترك حتى ينضج الدجاج.',
          'يُرفع الدجاج ليتحمر بالفرن، ويُطبخ أرز البسمتي المعتق في مرق الدجاج المركز حتى يتشرب النكهة تماماً.',
          'يُسكب الأرز في طبق التقديم ويوضع الدجاج المحمر فوقه ويزين بالمكسرات المحمصة.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-k1',
            nameAr: 'دجاج التنمية طازج مبرد 1000 غرام',
            quantityNeeded: '1 حبة كاملة',
            product: pChicken,
            substitutes: [pChickenBreast, pVeal],
          ),
          RecipeIngredient(
            id: 'ing-k2',
            nameAr: 'أرز بسمتي هندي عنبر طويل الحبة فاخر',
            quantityNeeded: '1 كجم (نصف العبوة)',
            product: pBasmatiRice,
            substitutes: [pOats],
          ),
          RecipeIngredient(
            id: 'ing-k3',
            nameAr: 'طماطم مزارع محلية قطاف الصباح',
            quantityNeeded: '500 غرام',
            product: pTomato,
            substitutes: [pAvocado],
          ),
          RecipeIngredient(
            id: 'ing-k4',
            nameAr: 'زيت زيتون بكر ممتاز فلسطيني',
            quantityNeeded: '3 ملاعق طعام',
            product: pOliveOil,
            substitutes: [pCheese],
            isOptional: true,
          ),
        ],
      ),

      // 2. ستيك أنجوس مشوي (طبخ رئيسي)
      RecipeModel(
        id: 'rcp-steak',
        titleAr: 'ستيك أنجوس ريب آي معتق بالفرن مع صوص الأعشاب',
        titleEn: 'Prime Angus Ribeye Steak with Herb Infusion',
        category: 'أطباق رئيسية',
        prepTime: '25 دقيقة',
        cookTimeMinutes: 25,
        servings: '2 أشخاص',
        difficulty: 'متوسط',
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
        discountPercent: 15,
        calories: 580,
        rating: 5.0,
        reviewsCount: 195,
        allergens: const [],
        dietaryTags: const ['كيتو', 'بروتين عالي', 'خالٍ من الجلوتين', 'خالٍ من اللاكتوز'],
        steps: const [
          'يُترك الستيك في درجة حرارة الغرفة لمدة 20 دقيقة ويجفف بمحارم ورقية.',
          'يتبل الستيك بملح البحر الخشن والفلفل الأسود المجروش وزيت الزيتون.',
          'تسخن مقلاة حديد الزهر (Cast Iron) على حرارة عالية حتى تتصاعد الأبخرة.',
          'يوضع الستيك ويشوح لمدة 3-4 دقائق لكل جانب للحصول على نضج مثالي Medium-Rare.',
          'يُترك الستيك يرتاح 5 دقائق قبل التقطيع لتحتبس العصارة بداخله.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-s1',
            nameAr: 'ستيك ريب آي أنجوس معتق فاخر 400 غ',
            quantityNeeded: '1 قطعة فاخرة',
            product: pSteak,
            substitutes: [pVeal, pSalmon, pChickenBreast],
          ),
          RecipeIngredient(
            id: 'ing-s2',
            nameAr: 'زيت زيتون بكر ممتاز فلسطيني',
            quantityNeeded: 'ملعقتين كبيرتين',
            product: pOliveOil,
            substitutes: [pCheese],
          ),
          RecipeIngredient(
            id: 'ing-s3',
            nameAr: 'طماطم مزارع محلية كرزية للشواء الجانبي',
            quantityNeeded: '300 غرام',
            product: pTomato,
            substitutes: [pAvocado],
            isOptional: true,
          ),
        ],
      ),

      // 3. فيليه سلمون نرويجي مشوي (طبخ رئيسي / بحريات)
      RecipeModel(
        id: 'rcp-salmon',
        titleAr: 'فيليه سلمون نرويجي مشوي بالأعشاب والليمون',
        titleEn: 'Pan-Seared Norwegian Salmon with Herb Glaze',
        category: 'أطباق رئيسية',
        prepTime: '20 دقيقة',
        cookTimeMinutes: 20,
        servings: '2 أشخاص',
        difficulty: 'سهل',
        imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80',
        discountPercent: 16,
        calories: 420,
        rating: 4.9,
        reviewsCount: 228,
        allergens: const ['سمك'],
        dietaryTags: const ['كيتو', 'خالٍ من الجلوتين', 'خالٍ من اللاكتوز', 'أوميغا 3', 'بروتين عالي'],
        steps: const [
          'يُتبل فيليه السلمون بزيت الزيتون البكر وعصير الليمون والملح والأعشاب.',
          'تسخن مقلاة غير لاصقة مع مسحة زيت زيتون.',
          'يوضع السلمون من جهة الجلد لأسفل لمدة 4 دقائق حتى يصبح مقرمشاً، ثم يقلب لمدة 3 دقائق.',
          'يقدم السلمون ساخناً مع شرائح الطماطم المشوية ومكعبات الأفوكادو الطازجة.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-sal1',
            nameAr: 'فيليه سلمون نرويجي طازج فاخر 500 غ',
            quantityNeeded: '1 عبوة طازجة',
            product: pSalmon,
            substitutes: [pChickenBreast, pSteak],
          ),
          RecipeIngredient(
            id: 'ing-sal2',
            nameAr: 'زيت زيتون بكر ممتاز فلسطيني معصور على البارد',
            quantityNeeded: 'ملعقة كبيرة',
            product: pOliveOil,
            substitutes: [pCheese],
          ),
          RecipeIngredient(
            id: 'ing-sal3',
            nameAr: 'أفوكادو هاس مكسيكي طازج',
            quantityNeeded: 'حبة واحدة',
            product: pAvocado,
            substitutes: [pTomato],
            isOptional: true,
          ),
        ],
      ),

      // 4. سموذي الموز واللوز البروتيني (مشروبات وعصائر)
      RecipeModel(
        id: 'rcp-smoothie',
        titleAr: 'سموذي الموز واللوز البروتيني المنعش بالطاقة',
        titleEn: 'Vitality Almond & Banana Energy Protein Smoothie',
        category: 'مشروبات وعصائر',
        prepTime: '5 دقائق',
        cookTimeMinutes: 5,
        servings: '2 كوب',
        difficulty: 'سهل جداً',
        imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=800&q=80',
        discountPercent: 20,
        calories: 250,
        rating: 4.8,
        reviewsCount: 412,
        allergens: const ['مكسرات'],
        dietaryTags: const ['نباتي', 'خالٍ من اللاكتوز', 'طاقة طبيعية', 'خالٍ من الجلوتين'],
        steps: const [
          'يُقشر الموز الطازج ويقطع إلى حلقات ويوضع في وعاء الخلاط.',
          'يُسكب حليب اللوز النباتي البارد والشوفان العضوي.',
          'تُضاف ملعقة من عسل السدر الجبلي الطبيعي لإعطاء حلاوة متوازنة.',
          'يُخلط المزيج على سرعة عالية لمدة دقيقة حتى يصبح ناعماً وكريمياً ثم يقدم مثلجاً.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-sm1',
            nameAr: 'موز فلبيني طازج كافنديش درجة أولى',
            quantityNeeded: '3 حبات',
            product: pBanana,
            substitutes: [pAvocado, pApple],
          ),
          RecipeIngredient(
            id: 'ing-sm2',
            nameAr: 'حليب لوز نباتي عضوي غير محلى 1 لتر',
            quantityNeeded: '500 مل',
            product: pAlmondMilk,
            substitutes: [pMilk], // Can swap back to regular cow milk!
          ),
          RecipeIngredient(
            id: 'ing-sm3',
            nameAr: 'شوفان عضوي حبوب كاملة فاخر',
            quantityNeeded: '3 ملاعق طعام',
            product: pOats,
            substitutes: [pBasmatiRice],
            isOptional: true,
          ),
          RecipeIngredient(
            id: 'ing-sm4',
            nameAr: 'عسل سدر جبلي طبيعي نقي 500 غرام',
            quantityNeeded: 'ملعقة عسل',
            product: pHoney,
            substitutes: [pApple],
            isOptional: true,
          ),
        ],
      ),

      // 5. كوكتيل المناعة بالبرتقال والتفاح والعسل (مشروبات وعصائر)
      RecipeModel(
        id: 'rcp-juice-mix',
        titleAr: 'كوكتيل المناعة بالبرتقال الطازج والتفاح المقرمش',
        titleEn: 'Immunity Orange & Gala Apple Vitality Cooler',
        category: 'مشروبات وعصائر',
        prepTime: '8 دقائق',
        cookTimeMinutes: 8,
        servings: '3 أكواب',
        difficulty: 'سهل جداً',
        imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=800&q=80',
        discountPercent: 15,
        calories: 160,
        rating: 4.9,
        reviewsCount: 168,
        allergens: const [],
        dietaryTags: const ['نباتي', 'خالٍ من اللاكتوز', 'خالٍ من الجلوتين', 'فيتامين سي'],
        steps: const [
          'يُغسل التفاح جيداً ويُقطع إلى شرائح رفيعة.',
          'في إبريق التقديم يوضع عصير البرتقال الطبيعي المعصور طازجاً.',
          'تضاف شرائح التفاح ومكعبات الثلج وملعقة من عسل السدر الطبيعي.',
          'يقلب المزيج ويقدم منعشاً لتعزيز المناعة والنشاط اليومي.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-jm1',
            nameAr: 'عصير برتقال طبيعي معصور طازج 1 لتر',
            quantityNeeded: '1 لتر كامل',
            product: pJuice,
            substitutes: [pWater],
          ),
          RecipeIngredient(
            id: 'ing-jm2',
            nameAr: 'تفاح رويال جالا إيطالي مقرمش فاخر',
            quantityNeeded: '2 حبة',
            product: pApple,
            substitutes: [pBanana],
          ),
          RecipeIngredient(
            id: 'ing-jm3',
            nameAr: 'عسل سدر جبلي طبيعي نقي',
            quantityNeeded: 'ملعقة صغيرة',
            product: pHoney,
            substitutes: [pWater],
            isOptional: true,
          ),
        ],
      ),

      // 6. القهوة العربية الملكية بالزعفران والهيل (مشروبات وعصائر)
      RecipeModel(
        id: 'rcp-coffee',
        titleAr: 'القهوة العربية الملكية بالزعفران والهيل والضيافة',
        titleEn: 'Royal Saffron & Cardamom Arabic Hospitality Dallah',
        category: 'مشروبات وعصائر',
        prepTime: '15 دقيقة',
        cookTimeMinutes: 15,
        servings: '6 فناجين',
        difficulty: 'سهل',
        imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80',
        discountPercent: 18,
        calories: 10,
        rating: 4.9,
        reviewsCount: 310,
        allergens: const [],
        dietaryTags: const ['كيتو', 'خالٍ من السكر', 'خالٍ من الجلوتين', 'خالٍ من اللاكتوز'],
        steps: const [
          'توضع مياه العين النقية في دلة القهوة وتترك حتى تبدأ بالغليان.',
          'تضاف القهوة العربية المطحونة وتترك لتغلي على نار هادئة جداً لمدة 12 دقيقة.',
          'يضاف الهيل المطحون والزعفران الأصلي قبل رفعها من على النار بدقيقة واحدة.',
          'تغطى الدلة وتترك لتركد دقيقتين ثم تسكب في الدلة الذهبية وتقدم مع التمر الفاخر.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-c1',
            nameAr: 'قهوة عربية فاخرة بالهيل والزعفران 250 غ',
            quantityNeeded: '3 ملاعق دلة',
            product: pCoffee,
            substitutes: [pJuice],
          ),
          RecipeIngredient(
            id: 'ing-c2',
            nameAr: 'مياه العين الطبيعية كرتون (24 × 500 مل)',
            quantityNeeded: 'زجاجتين للتحضير',
            product: pWater,
            substitutes: [pMilk],
          ),
        ],
      ),

      // 7. سلطة الفيتا والزيتون المتوسطية (سلطات ومقبلات)
      RecipeModel(
        id: 'rcp-salad',
        titleAr: 'سلطة الفيتا المتوسطية بالطماطم والزيتون البكر',
        titleEn: 'Greek Mediterranean Salad with Cheese & Virgin Oil',
        category: 'سلطات ومقبلات',
        prepTime: '12 دقيقة',
        cookTimeMinutes: 12,
        servings: '2 أشخاص',
        difficulty: 'سريع جداً',
        imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80',
        discountPercent: 14,
        calories: 210,
        rating: 4.8,
        reviewsCount: 154,
        allergens: const ['لاكتوز'],
        dietaryTags: const ['نباتي', 'خالٍ من الجلوتين', 'قليل السعرات'],
        steps: const [
          'تقطع الطماطم الطازجة إلى مكعبات متوسطة وتوضع في طبق تقديم عميق.',
          'تضاف جبنة بوك أو اللبنة التركية كبديل ناعم.',
          'تضاف شرائح التفاح الرفيعة لإضافة قرمشة حلاوة متوسطية منعشة.',
          'يتبل الخليط برشة زيت زيتون بكر ممتاز وقليل من الأوريجانو.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-sld1',
            nameAr: 'طماطم مزارع محلية قطاف الصباح',
            quantityNeeded: '500 غرام',
            product: pTomato,
            substitutes: [pAvocado],
          ),
          RecipeIngredient(
            id: 'ing-sld2',
            nameAr: 'جبنة بوك كريمية بيضاء أصلية 500 غرام',
            quantityNeeded: '1 عبوة',
            product: pCheese,
            substitutes: [pLabneh], // Can swap for labneh!
          ),
          RecipeIngredient(
            id: 'ing-sld3',
            nameAr: 'زيت زيتون بكر ممتاز فلسطيني معصور على البارد',
            quantityNeeded: 'ملعقة طعام',
            product: pOliveOil,
            substitutes: [pHoney],
          ),
          RecipeIngredient(
            id: 'ing-sld4',
            nameAr: 'تفاح رويال جالا إيطالي مقرمش فاخر',
            quantityNeeded: '1 حبة',
            product: pApple,
            substitutes: [pAvocado],
            isOptional: true,
          ),
        ],
      ),

      // 8. سلطة الأفوكادو والسلمون الغنية بالأوميغا 3 (سلطات ومقبلات)
      RecipeModel(
        id: 'rcp-avocado-salmon-bowl',
        titleAr: 'سلطة الأفوكادو والسلمون الغنية بالأوميغا 3 والألياف',
        titleEn: 'Superfood Avocado & Salmon Keto Power Salad',
        category: 'سلطات ومقبلات',
        prepTime: '15 دقيقة',
        cookTimeMinutes: 15,
        servings: '2 أشخاص',
        difficulty: 'سهل',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80',
        discountPercent: 17,
        calories: 380,
        rating: 4.9,
        reviewsCount: 182,
        allergens: const ['سمك'],
        dietaryTags: const ['كيتو', 'خالٍ من الجلوتين', 'خالٍ من اللاكتوز', 'أوميغا 3'],
        steps: const [
          'يُطهى فيليه السلمون خفيفاً على الشواية أو المقلاة ويفتت إلى قطع كبيرة.',
          'يُقشر الأفوكادو ويقطع إلى شرائح متناسقة مع الطماطم النضرة.',
          'يُمزج زيت الزيتون البكر مع قليل من الملح وعصير الليمون كدريسينج نقي.',
          'توضع المكونات في وعاء وتُرش بالدريسينج وتقدم فوراً.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-asb1',
            nameAr: 'أفوكادو هاس مكسيكي طازج جاهز للأكل',
            quantityNeeded: '2 حبة',
            product: pAvocado,
            substitutes: [pTomato, pApple],
          ),
          RecipeIngredient(
            id: 'ing-asb2',
            nameAr: 'فيليه سلمون نرويجي طازج فاخر',
            quantityNeeded: '250 غرام',
            product: pSalmon,
            substitutes: [pChickenBreast, pSteak],
          ),
          RecipeIngredient(
            id: 'ing-asb3',
            nameAr: 'طماطم مزارع محلية قطاف الصباح',
            quantityNeeded: '250 غرام',
            product: pTomato,
            substitutes: [pApple],
          ),
          RecipeIngredient(
            id: 'ing-asb4',
            nameAr: 'زيت زيتون بكر ممتاز فلسطيني',
            quantityNeeded: 'ملعقة كبيرة',
            product: pOliveOil,
            substitutes: [pCheese],
          ),
        ],
      ),

      // 9. شكشوكة المزارع بالبيض العضوي (فطور صحي ومخبوزات)
      RecipeModel(
        id: 'rcp-shakshuka',
        titleAr: 'شكشوكة المزارع بالطماطم الطازجة والبيض العضوي',
        titleEn: 'Farmhouse Organic Shakshuka with Sourdough',
        category: 'فطور ومخبوزات',
        prepTime: '18 دقيقة',
        cookTimeMinutes: 18,
        servings: '3 أشخاص',
        difficulty: 'سهل',
        imageUrl: 'https://images.unsplash.com/photo-1590412200988-a436970781fa?auto=format&fit=crop&w=800&q=80',
        discountPercent: 15,
        calories: 310,
        rating: 4.9,
        reviewsCount: 290,
        allergens: const ['بيض', 'جلوتين'],
        dietaryTags: const ['بروتين عالي', 'نباتي'],
        steps: const [
          'يُسخن زيت الزيتون في مقلاة عميقة ويشوح البصل والثوم والفلفل.',
          'تضاف الطماطم المفرومة والكمون والبابريكا وتترك لتتسبك لمدة 10 دقائق.',
          'تُصنع حفر صغيرة في الصلصة ويكسر البيض العضوي بداخلها واحدة تلو الأخرى.',
          'تغطى المقلاة على نار هادئة حتى ينضج زلال البيض ويبقى الصفار طرياً.',
          'تقدم ساخنة مع خبز الساوردو الريفي المقرمش.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-sh1',
            nameAr: 'بيض مزارع عضوي طازج كرتون 30 حبة',
            quantityNeeded: '4 حبات',
            product: pEggs,
            substitutes: [pCheese],
          ),
          RecipeIngredient(
            id: 'ing-sh2',
            nameAr: 'طماطم مزارع محلية قطاف الصباح',
            quantityNeeded: '500 غرام',
            product: pTomato,
            substitutes: [pAvocado],
          ),
          RecipeIngredient(
            id: 'ing-sh3',
            nameAr: 'زيت زيتون بكر ممتاز فلسطيني',
            quantityNeeded: 'ملعقة كبيرة',
            product: pOliveOil,
            substitutes: [pCheese],
          ),
          RecipeIngredient(
            id: 'ing-sh4',
            nameAr: 'خبز ساوردو ريفيّ عضوي طازج مخبوز بالفرن',
            quantityNeeded: 'نصف رغيف',
            product: pSourdough,
            substitutes: [pCroissant], // Swap sourdough with butter croissant!
          ),
        ],
      ),

      // 10. توست الساوردو بالأفوكادو واللبنة (فطور صحي ومخبوزات)
      RecipeModel(
        id: 'rcp-avocado-toast',
        titleAr: 'توست الساوردو الريفي بالأفوكادو واللبنة التركية',
        titleEn: 'Artisan Sourdough Toast with Avocado & Turkish Labneh',
        category: 'فطور ومخبوزات',
        prepTime: '10 دقائق',
        cookTimeMinutes: 10,
        servings: '2 شخصين',
        difficulty: 'سهل جداً',
        imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=800&q=80',
        discountPercent: 16,
        calories: 330,
        rating: 4.8,
        reviewsCount: 215,
        allergens: const ['جلوتين', 'لاكتوز'],
        dietaryTags: const ['نباتي', 'ألياف عالية', 'فطور سريع'],
        steps: const [
          'يُحمص خبز الساوردو الريفي في المحمصة أو مقلاة جافة حتى يتقرمش.',
          'تدهن طبقة سخية من اللبنة التركية الكريمية على الخبز الساخن.',
          'يرص الأفوكادو المهروس أو المقطع شرائح فوق اللبنة.',
          'يُرش زيت الزيتون البكر ورشة خفيفة من بذور الشيا أو حبة البركة.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-at1',
            nameAr: 'خبز ساوردو ريفيّ عضوي طازج مخبوز بالفرن',
            quantityNeeded: 'شريحتان',
            product: pSourdough,
            substitutes: [pCroissant],
          ),
          RecipeIngredient(
            id: 'ing-at2',
            nameAr: 'لبنة تركية فاخرة طازجة كاملة الدسم',
            quantityNeeded: '4 ملاعق طعام',
            product: pLabneh,
            substitutes: [pCheese],
          ),
          RecipeIngredient(
            id: 'ing-at3',
            nameAr: 'أفوكادو هاس مكسيكي طازج جاهز للأكل',
            quantityNeeded: 'حبة واحدة',
            product: pAvocado,
            substitutes: [pTomato],
          ),
          RecipeIngredient(
            id: 'ing-at4',
            nameAr: 'زيت زيتون بكر ممتاز فلسطيني',
            quantityNeeded: 'ملعقة صغيرة',
            product: pOliveOil,
            substitutes: [pHoney],
            isOptional: true,
          ),
        ],
      ),

      // 11. فطيرة التفاح بالكرواسان والعسل (حلويات ومعجنات)
      RecipeModel(
        id: 'rcp-apple-croissant',
        titleAr: 'تارت التفاح الفرنسي بالكرواسان وعسل السدر الطبيعي',
        titleEn: 'French Butter Croissant Apple Tart with Sidr Honey',
        category: 'حلويات ومعجنات',
        prepTime: '20 دقيقة',
        cookTimeMinutes: 20,
        servings: '4 أشخاص',
        difficulty: 'متوسط',
        imageUrl: 'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?auto=format&fit=crop&w=800&q=80',
        discountPercent: 18,
        calories: 390,
        rating: 4.9,
        reviewsCount: 178,
        allergens: const ['جلوتين', 'لاكتوز'],
        dietaryTags: const ['حلويات غربية', 'نباتي'],
        steps: const [
          'يُقطع الكرواسان الفرنسي بالزبدة إلى أنصاف ويوضع في صينية خبز مبطنة.',
          'يُقطع التفاح الإيطالي إلى شرائح رقيقة جداً ويُرص بشكل مروحي فوق الكرواسان.',
          'يُسكب عسل السدر الطبيعي فوق التفاح مع رشة قرفة ناعمة.',
          'يُخبز في فرن محمى على 180 درجة مئوية لمدة 12-15 دقيقة حتى يكرمل التفاح ويصبح الكرواسان ذهبياً مقرمشاً.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-ac1',
            nameAr: 'كرواسان فرنسي بالزبدة الطبيعية (4 حبات)',
            quantityNeeded: 'عبوة واحدة',
            product: pCroissant,
            substitutes: [pSourdough],
          ),
          RecipeIngredient(
            id: 'ing-ac2',
            nameAr: 'تفاح رويال جالا إيطالي مقرمش فاخر',
            quantityNeeded: '3 حبات',
            product: pApple,
            substitutes: [pBanana],
          ),
          RecipeIngredient(
            id: 'ing-ac3',
            nameAr: 'عسل سدر جبلي طبيعي نقي 500 غرام',
            quantityNeeded: '3 ملاعق طعام',
            product: pHoney,
            substitutes: [pCheese],
          ),
          RecipeIngredient(
            id: 'ing-ac4',
            nameAr: 'حليب المراعي كامل الدسم طازج 2 لتر',
            quantityNeeded: 'نصف كوب للدهن',
            product: pMilk,
            substitutes: [pAlmondMilk],
            isOptional: true,
          ),
        ],
      ),

      // 12. تشكيلة الضيافة الشرقية (حلويات ومعجنات)
      RecipeModel(
        id: 'rcp-baklava-platter',
        titleAr: 'صينية البقلاوة الملكية بالفستق مع القهوة العربية الأصيلة',
        titleEn: 'Royal Pistachio Baklava Platter with Arabic Coffee',
        category: 'حلويات ومعجنات',
        prepTime: '5 دقائق',
        cookTimeMinutes: 5,
        servings: '6-8 ضيوف',
        difficulty: 'سهل جداً',
        imageUrl: 'https://images.unsplash.com/photo-1519869325930-281384150729?auto=format&fit=crop&w=800&q=80',
        discountPercent: 20,
        calories: 440,
        rating: 5.0,
        reviewsCount: 350,
        allergens: const ['مكسرات', 'جلوتين'],
        dietaryTags: const ['ضيافة شرقية', 'مناسبات'],
        steps: const [
          'ترتب قطع البقلاوة المقرمشة بالفستق في طبق ضيافة نحاسي أو زجاجي فاخر.',
          'يُسكب قطرات خفيفة من عسل السدر الطبيعي لمنح لمعان ومذاق استثنائي.',
          'تُسكب القهوة العربية المغلية بالزعفران والهيل في الفناجين.',
          'تقدم الضيافة ساخنة للأهل والضيوف.',
        ],
        ingredients: [
          RecipeIngredient(
            id: 'ing-bp1',
            nameAr: 'بقلاوة مشكلة بالفستق والكاجو الفاخر 500 غ',
            quantityNeeded: 'عبوة كاملة',
            product: pBaklava,
            substitutes: [pCroissant],
          ),
          RecipeIngredient(
            id: 'ing-bp2',
            nameAr: 'قهوة عربية فاخرة بالهيل والزعفران',
            quantityNeeded: 'عبوة 250 غ',
            product: pCoffee,
            substitutes: [pJuice],
          ),
          RecipeIngredient(
            id: 'ing-bp3',
            nameAr: 'عسل سدر جبلي طبيعي نقي',
            quantityNeeded: 'ملعقة تزيين',
            product: pHoney,
            substitutes: [pMilk],
            isOptional: true,
          ),
        ],
      ),
    ];
  }
}
