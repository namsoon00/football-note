import '../domain/entities/meal_entry.dart';

class MealCalorieEstimate {
  final MealNutritionEstimate breakfast;
  final MealNutritionEstimate lunch;
  final MealNutritionEstimate dinner;

  const MealCalorieEstimate({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  int get breakfastKcal => breakfast.kcal;
  int get lunchKcal => lunch.kcal;
  int get dinnerKcal => dinner.kcal;

  int get totalKcal => breakfastKcal + lunchKcal + dinnerKcal;
  double get totalCarbs => breakfast.carbs + lunch.carbs + dinner.carbs;
  double get totalProtein => breakfast.protein + lunch.protein + dinner.protein;
  double get totalFat => breakfast.fat + lunch.fat + dinner.fat;

  bool get hasEstimate => totalKcal > 0;
  bool get hasNutrition => totalCarbs > 0 || totalProtein > 0 || totalFat > 0;
}

class MealNutritionEstimate {
  final int kcal;
  final double carbs;
  final double protein;
  final double fat;

  const MealNutritionEstimate({
    required this.kcal,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
  });

  MealNutritionEstimate scaled(double factor) {
    return MealNutritionEstimate(
      kcal: (kcal * factor).round(),
      carbs: carbs * factor,
      protein: protein * factor,
      fat: fat * factor,
    );
  }

  MealNutritionEstimate plus(MealNutritionEstimate other) {
    return MealNutritionEstimate(
      kcal: kcal + other.kcal,
      carbs: carbs + other.carbs,
      protein: protein + other.protein,
      fat: fat + other.fat,
    );
  }
}

class MealDishOption {
  final String id;
  final int kcal;
  final double carbs;
  final double protein;
  final double fat;

  const MealDishOption({
    required this.id,
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  MealNutritionEstimate get nutrition {
    return MealNutritionEstimate(
      kcal: kcal,
      carbs: carbs,
      protein: protein,
      fat: fat,
    );
  }
}

class MealCalorieEstimator {
  const MealCalorieEstimator._();

  static const int kcalPerRiceBowl = 300;
  static const double carbsPerRiceBowl = 65;
  static const double proteinPerRiceBowl = 5;
  static const double fatPerRiceBowl = 1;

  static const List<String> portionIds = <String>['small', 'regular', 'large'];

  static const List<MealDishOption> mainDishOptions = <MealDishOption>[
    MealDishOption(
      id: 'chickenBreast',
      kcal: 165,
      carbs: 0,
      protein: 31,
      fat: 4,
    ),
    MealDishOption(id: 'eggs', kcal: 160, carbs: 1, protein: 13, fat: 11),
    MealDishOption(id: 'tofu', kcal: 150, carbs: 4, protein: 15, fat: 9),
    MealDishOption(
      id: 'grilledFish',
      kcal: 250,
      carbs: 0,
      protein: 28,
      fat: 12,
    ),
    MealDishOption(id: 'salmon', kcal: 300, carbs: 0, protein: 27, fat: 18),
    MealDishOption(id: 'bulgogi', kcal: 500, carbs: 20, protein: 30, fat: 25),
    MealDishOption(
        id: 'kimchiStew', kcal: 450, carbs: 20, protein: 25, fat: 22),
    MealDishOption(
      id: 'doenjangStew',
      kcal: 350,
      carbs: 18,
      protein: 20,
      fat: 14,
    ),
    MealDishOption(
      id: 'friedChicken',
      kcal: 600,
      carbs: 25,
      protein: 35,
      fat: 38,
    ),
    MealDishOption(
      id: 'chickenSalad',
      kcal: 300,
      carbs: 12,
      protein: 28,
      fat: 12,
    ),
    MealDishOption(id: 'ramen', kcal: 500, carbs: 80, protein: 12, fat: 16),
    MealDishOption(id: 'sandwich', kcal: 450, carbs: 50, protein: 20, fat: 15),
  ];

  static MealCalorieEstimate estimate(MealEntry entry) {
    return MealCalorieEstimate(
      breakfast: _estimateMeal(
        riceBowls: entry.breakfastRiceBowls,
        menu: entry.breakfastMenu,
        dishId: entry.breakfastDishId,
        dishPortion: entry.breakfastDishPortion,
      ),
      lunch: _estimateMeal(
        riceBowls: entry.lunchRiceBowls,
        menu: entry.lunchMenu,
        dishId: entry.lunchDishId,
        dishPortion: entry.lunchDishPortion,
      ),
      dinner: _estimateMeal(
        riceBowls: entry.dinnerRiceBowls,
        menu: entry.dinnerMenu,
        dishId: entry.dinnerDishId,
        dishPortion: entry.dinnerDishPortion,
      ),
    );
  }

  static MealDishOption? dishById(String id) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;
    for (final option in mainDishOptions) {
      if (option.id == normalizedId) return option;
    }
    return null;
  }

  static double portionFactor(String portionId) {
    return switch (portionId) {
      'small' => 0.7,
      'large' => 1.3,
      _ => 1.0,
    };
  }

  static MealNutritionEstimate _estimateMeal({
    required double riceBowls,
    required String menu,
    required String dishId,
    required String dishPortion,
  }) {
    final riceNutrition = MealNutritionEstimate(
      kcal: (riceBowls * kcalPerRiceBowl).round(),
      carbs: riceBowls * carbsPerRiceBowl,
      protein: riceBowls * proteinPerRiceBowl,
      fat: riceBowls * fatPerRiceBowl,
    );
    final dishNutrition =
        dishById(dishId)?.nutrition.scaled(portionFactor(dishPortion)) ??
            const MealNutritionEstimate(kcal: 0);
    final menuKcal = _estimateMenu(menu, skipRiceKeywords: riceBowls > 0);
    return riceNutrition
        .plus(dishNutrition)
        .plus(MealNutritionEstimate(kcal: menuKcal));
  }

  static int _estimateMenu(String menu, {required bool skipRiceKeywords}) {
    final normalized = menu.toLowerCase();
    if (normalized.trim().isEmpty) return 0;

    final matchedRanges = <_TextRange>[];
    var total = 0;
    for (final food in _foodKeywords) {
      if (skipRiceKeywords && food.isRicePortion) continue;
      for (final match in food.pattern.allMatches(normalized)) {
        final range = _TextRange(match.start, match.end);
        if (matchedRanges.any(range.overlaps)) continue;
        matchedRanges.add(range);
        total += food.kcal * _quantityNear(normalized, range);
      }
    }
    return total;
  }

  static int _quantityNear(String text, _TextRange range) {
    final segment = _segmentNear(text, range);
    return (_numberFromText(segment) ?? 1).clamp(1, 5).toInt();
  }

  static String _segmentNear(String text, _TextRange range) {
    const separators = <String>{',', '，', '/', '+', '\n', '·', ';'};
    var start = range.start;
    while (start > 0 && !separators.contains(text[start - 1])) {
      start -= 1;
    }
    var end = range.end;
    while (end < text.length && !separators.contains(text[end])) {
      end += 1;
    }
    return text.substring(start, end);
  }

  static int? _numberFromText(String text) {
    final digitMatch = RegExp(r'(\d+)').firstMatch(text);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(1)!);
    }
    const numbers = <String, int>{
      '한': 1,
      '하나': 1,
      '두': 2,
      '둘': 2,
      '세': 3,
      '셋': 3,
      '네': 4,
      '넷': 4,
      '다섯': 5,
    };
    for (final entry in numbers.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static final List<_FoodKeyword> _foodKeywords = <_FoodKeyword>[
    _FoodKeyword(const ['닭가슴살', 'chicken breast'], 165),
    _FoodKeyword(const ['김치찌개'], 450),
    _FoodKeyword(const ['된장찌개'], 350),
    _FoodKeyword(const ['비빔밥'], 600),
    _FoodKeyword(const ['볶음밥'], 600),
    _FoodKeyword(const ['불고기'], 500),
    _FoodKeyword(const ['떡볶이'], 500),
    _FoodKeyword(const ['샌드위치', 'sandwich'], 450),
    _FoodKeyword(const ['햄버거', 'burger'], 600),
    _FoodKeyword(const ['파스타', 'pasta'], 650),
    _FoodKeyword(const ['라면', 'ramen'], 500),
    _FoodKeyword(const ['국수', '우동'], 450),
    _FoodKeyword(const ['김밥'], 480),
    _FoodKeyword(const ['카레', 'curry'], 550),
    _FoodKeyword(const ['치킨'], 600),
    _FoodKeyword(const ['튀김'], 350),
    _FoodKeyword(const ['만두'], 350),
    _FoodKeyword(const ['피자', 'pizza'], 300),
    _FoodKeyword(const ['샐러드', 'salad'], 180),
    _FoodKeyword(const ['시리얼', 'cereal'], 250),
    _FoodKeyword(const ['토스트', 'toast'], 300),
    _FoodKeyword(const ['오트밀', 'oatmeal'], 220),
    _FoodKeyword(const ['고구마'], 180),
    _FoodKeyword(const ['감자'], 140),
    _FoodKeyword(const ['바나나', 'banana'], 105),
    _FoodKeyword(const ['사과', 'apple'], 95),
    _FoodKeyword(const ['계란', '달걀', 'egg'], 80),
    _FoodKeyword(const ['닭고기'], 250),
    _FoodKeyword(const ['소고기', '쇠고기', 'beef'], 300),
    _FoodKeyword(const ['돼지고기', 'pork'], 350),
    _FoodKeyword(const ['연어', 'salmon'], 300),
    _FoodKeyword(const ['생선', 'fish'], 220),
    _FoodKeyword(const ['두부', 'tofu'], 150),
    _FoodKeyword(const ['요거트', '요구르트', 'yogurt'], 120),
    _FoodKeyword(const ['우유', 'milk'], 130),
    _FoodKeyword(const ['치즈', 'cheese'], 110),
    _FoodKeyword(const ['빵', 'bread'], 250),
    _FoodKeyword(const ['현미밥', '잡곡밥', '공기밥', '밥', 'rice'], 300,
        isRicePortion: true),
    _FoodKeyword(const ['죽'], 250, isRicePortion: true),
  ]..sort((a, b) => b.longestKeywordLength.compareTo(a.longestKeywordLength));
}

class _FoodKeyword {
  final List<String> keywords;
  final int kcal;
  final bool isRicePortion;
  late final RegExp pattern = RegExp(
    keywords.map(RegExp.escape).join('|'),
    caseSensitive: false,
  );

  _FoodKeyword(this.keywords, this.kcal, {this.isRicePortion = false});

  int get longestKeywordLength {
    return keywords.map((keyword) => keyword.length).reduce(
          (current, next) => current > next ? current : next,
        );
  }
}

class _TextRange {
  final int start;
  final int end;

  const _TextRange(this.start, this.end);

  bool overlaps(_TextRange other) => start < other.end && other.start < end;
}
