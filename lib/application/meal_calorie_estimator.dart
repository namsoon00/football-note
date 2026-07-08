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

enum MealFoodCategory { main, protein, side, soup, carb, fruit, snack, drink }

class MealFoodOption {
  final String id;
  final MealFoodCategory category;
  final int kcal;
  final double carbs;
  final double protein;
  final double fat;
  final int servingGrams;
  final bool canBeMainDish;
  final bool canBeCompanion;

  const MealFoodOption({
    required this.id,
    required this.category,
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
    this.servingGrams = 0,
    this.canBeMainDish = false,
    this.canBeCompanion = true,
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

typedef MealDishOption = MealFoodOption;

class MealCalorieEstimator {
  const MealCalorieEstimator._();

  static const int kcalPerRiceBowl = 300;
  static const double carbsPerRiceBowl = 65;
  static const double proteinPerRiceBowl = 5;
  static const double fatPerRiceBowl = 1;

  static const List<String> portionIds = <String>['small', 'regular', 'large'];

  static const List<String> _popularMainDishIds = <String>[
    'bibimbap',
    'kimchiStew',
    'doenjangStew',
    'bulgogi',
    'ramen',
    'gimbap',
    'friedRice',
    'kimchiFriedRice',
    'jajangmyeon',
    'jjampong',
    'tteokbokki',
    'porkCutlet',
    'friedChicken',
    'chickenBreast',
    'spaghetti',
    'hamburger',
    'pizza',
    'sushi',
    'pho',
    'padThai',
    'tacos',
    'burrito',
  ];

  static const List<String> _popularCompanionFoodIds = <String>[
    'kimchi',
    'boiledEgg',
    'friedEgg',
    'seasonedSeaweed',
    'sweetPotato',
    'banana',
    'milk',
    'yogurt',
    'greekYogurt',
    'chickenBreast',
    'tofu',
    'saladGreens',
    'tomato',
    'cucumber',
    'mixedNuts',
    'proteinShake',
    'coffeeLatte',
    'americano',
  ];

  static const List<MealFoodOption> foodOptions = <MealFoodOption>[
    MealFoodOption(
      id: 'chickenBreast',
      category: MealFoodCategory.main,
      kcal: 165,
      carbs: 0,
      protein: 31,
      fat: 4,
      servingGrams: 100,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'eggs',
      category: MealFoodCategory.main,
      kcal: 160,
      carbs: 1,
      protein: 13,
      fat: 11,
      servingGrams: 100,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'tofu',
      category: MealFoodCategory.main,
      kcal: 150,
      carbs: 4,
      protein: 15,
      fat: 9,
      servingGrams: 150,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'grilledFish',
      category: MealFoodCategory.main,
      kcal: 250,
      carbs: 0,
      protein: 28,
      fat: 12,
      servingGrams: 150,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'salmon',
      category: MealFoodCategory.main,
      kcal: 300,
      carbs: 0,
      protein: 27,
      fat: 18,
      servingGrams: 150,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'bulgogi',
      category: MealFoodCategory.main,
      kcal: 500,
      carbs: 20,
      protein: 30,
      fat: 25,
      servingGrams: 300,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'kimchiStew',
      category: MealFoodCategory.main,
      kcal: 450,
      carbs: 20,
      protein: 25,
      fat: 22,
      servingGrams: 400,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'doenjangStew',
      category: MealFoodCategory.main,
      kcal: 350,
      carbs: 18,
      protein: 20,
      fat: 14,
      servingGrams: 400,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'friedChicken',
      category: MealFoodCategory.main,
      kcal: 600,
      carbs: 25,
      protein: 35,
      fat: 38,
      servingGrams: 250,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'chickenSalad',
      category: MealFoodCategory.main,
      kcal: 300,
      carbs: 12,
      protein: 28,
      fat: 12,
      servingGrams: 300,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'ramen',
      category: MealFoodCategory.main,
      kcal: 500,
      carbs: 80,
      protein: 12,
      fat: 16,
      servingGrams: 550,
      canBeMainDish: true,
    ),
    MealFoodOption(
      id: 'sandwich',
      category: MealFoodCategory.main,
      kcal: 450,
      carbs: 50,
      protein: 20,
      fat: 15,
      servingGrams: 220,
      canBeMainDish: true,
    ),
    MealFoodOption(
        id: 'bibimbap',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 90,
        protein: 22,
        fat: 18,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'friedRice',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 85,
        protein: 18,
        fat: 20,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'gimbap',
        category: MealFoodCategory.main,
        kcal: 480,
        carbs: 75,
        protein: 14,
        fat: 14,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'curryRice',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 85,
        protein: 18,
        fat: 16,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'porkCutlet',
        category: MealFoodCategory.main,
        kcal: 750,
        carbs: 80,
        protein: 32,
        fat: 32,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'jajangmyeon',
        category: MealFoodCategory.main,
        kcal: 800,
        carbs: 120,
        protein: 25,
        fat: 25,
        servingGrams: 650,
        canBeMainDish: true),
    MealFoodOption(
        id: 'jjampong',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 100,
        protein: 35,
        fat: 18,
        servingGrams: 700,
        canBeMainDish: true),
    MealFoodOption(
        id: 'tteokbokki',
        category: MealFoodCategory.main,
        kcal: 500,
        carbs: 95,
        protein: 10,
        fat: 8,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'pasta',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 90,
        protein: 22,
        fat: 20,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'hamburger',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 45,
        protein: 28,
        fat: 32,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'pizza',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 65,
        protein: 28,
        fat: 28,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'porkBelly',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 0,
        protein: 28,
        fat: 55,
        servingGrams: 180,
        canBeMainDish: true),
    MealFoodOption(
        id: 'jeyukBokkeum',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 25,
        protein: 35,
        fat: 28,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'beefSteak',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 5,
        protein: 45,
        fat: 40,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'dakgalbi',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 55,
        protein: 35,
        fat: 25,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'omurice',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 95,
        protein: 25,
        fat: 24,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'udon',
        category: MealFoodCategory.main,
        kcal: 450,
        carbs: 80,
        protein: 13,
        fat: 6,
        servingGrams: 650,
        canBeMainDish: true),
    MealFoodOption(
        id: 'coldNoodles',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 95,
        protein: 18,
        fat: 8,
        servingGrams: 600,
        canBeMainDish: true),
    MealFoodOption(
        id: 'soybeanNoodles',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 80,
        protein: 25,
        fat: 22,
        servingGrams: 700,
        canBeMainDish: true),
    MealFoodOption(
        id: 'dumplingSoup',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 80,
        protein: 24,
        fat: 20,
        servingGrams: 650,
        canBeMainDish: true),
    MealFoodOption(
        id: 'samgyetang',
        category: MealFoodCategory.main,
        kcal: 800,
        carbs: 20,
        protein: 70,
        fat: 45,
        servingGrams: 900,
        canBeMainDish: true),
    MealFoodOption(
        id: 'kimchiFriedRice',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 90,
        protein: 18,
        fat: 18,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'budaeJjigae',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 45,
        protein: 35,
        fat: 35,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'sundubuJjigae',
        category: MealFoodCategory.main,
        kcal: 400,
        carbs: 18,
        protein: 25,
        fat: 22,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'galbitang',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 20,
        protein: 45,
        fat: 25,
        servingGrams: 600,
        canBeMainDish: true),
    MealFoodOption(
        id: 'seolleongtang',
        category: MealFoodCategory.main,
        kcal: 500,
        carbs: 10,
        protein: 35,
        fat: 28,
        servingGrams: 600,
        canBeMainDish: true),
    MealFoodOption(
        id: 'yukgaejang',
        category: MealFoodCategory.main,
        kcal: 450,
        carbs: 20,
        protein: 30,
        fat: 20,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'gamjatang',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 45,
        protein: 45,
        fat: 35,
        servingGrams: 650,
        canBeMainDish: true),
    MealFoodOption(
        id: 'kalguksu',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 110,
        protein: 22,
        fat: 12,
        servingGrams: 650,
        canBeMainDish: true),
    MealFoodOption(
        id: 'sujebi',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 105,
        protein: 18,
        fat: 10,
        servingGrams: 650,
        canBeMainDish: true),
    MealFoodOption(
        id: 'bibimNoodles',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 100,
        protein: 18,
        fat: 14,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'japchae',
        category: MealFoodCategory.main,
        kcal: 450,
        carbs: 70,
        protein: 12,
        fat: 14,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'bossam',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 15,
        protein: 45,
        fat: 45,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'jokbal',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 20,
        protein: 50,
        fat: 45,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'galbiJjim',
        category: MealFoodCategory.main,
        kcal: 750,
        carbs: 35,
        protein: 45,
        fat: 40,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'dakdoritang',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 45,
        protein: 45,
        fat: 28,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'haejangguk',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 25,
        protein: 35,
        fat: 25,
        servingGrams: 600,
        canBeMainDish: true),
    MealFoodOption(
        id: 'gukbap',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 90,
        protein: 35,
        fat: 25,
        servingGrams: 700,
        canBeMainDish: true),
    MealFoodOption(
        id: 'soondaeGuk',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 45,
        protein: 35,
        fat: 35,
        servingGrams: 650,
        canBeMainDish: true),
    MealFoodOption(
        id: 'tteokguk',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 90,
        protein: 20,
        fat: 12,
        servingGrams: 600,
        canBeMainDish: true),
    MealFoodOption(
        id: 'janchiGuksu',
        category: MealFoodCategory.main,
        kcal: 500,
        carbs: 95,
        protein: 16,
        fat: 6,
        servingGrams: 600,
        canBeMainDish: true),
    MealFoodOption(
        id: 'makguksu',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 95,
        protein: 18,
        fat: 10,
        servingGrams: 550,
        canBeMainDish: true),
    MealFoodOption(
        id: 'kimchiPancake',
        category: MealFoodCategory.main,
        kcal: 400,
        carbs: 55,
        protein: 10,
        fat: 16,
        servingGrams: 200,
        canBeMainDish: true),
    MealFoodOption(
        id: 'seafoodPancake',
        category: MealFoodCategory.main,
        kcal: 500,
        carbs: 60,
        protein: 22,
        fat: 22,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'bindaetteok',
        category: MealFoodCategory.main,
        kcal: 450,
        carbs: 45,
        protein: 18,
        fat: 24,
        servingGrams: 220,
        canBeMainDish: true),
    MealFoodOption(
        id: 'sundae',
        category: MealFoodCategory.main,
        kcal: 350,
        carbs: 55,
        protein: 8,
        fat: 10,
        servingGrams: 200,
        canBeMainDish: true),
    MealFoodOption(
        id: 'odengSoup',
        category: MealFoodCategory.main,
        kcal: 250,
        carbs: 35,
        protein: 15,
        fat: 8,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'spaghetti',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 95,
        protein: 22,
        fat: 18,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'lasagna',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 60,
        protein: 35,
        fat: 32,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'risotto',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 80,
        protein: 18,
        fat: 22,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'paella',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 85,
        protein: 35,
        fat: 20,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'tacos',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 50,
        protein: 28,
        fat: 26,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'burrito',
        category: MealFoodCategory.main,
        kcal: 750,
        carbs: 90,
        protein: 35,
        fat: 30,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'quesadilla',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 55,
        protein: 30,
        fat: 35,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'nachos',
        category: MealFoodCategory.main,
        kcal: 600,
        carbs: 65,
        protein: 18,
        fat: 32,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'sushi',
        category: MealFoodCategory.main,
        kcal: 500,
        carbs: 85,
        protein: 22,
        fat: 8,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'sashimi',
        category: MealFoodCategory.main,
        kcal: 250,
        carbs: 5,
        protein: 40,
        fat: 8,
        servingGrams: 200,
        canBeMainDish: true),
    MealFoodOption(
        id: 'tempuraDon',
        category: MealFoodCategory.main,
        kcal: 750,
        carbs: 95,
        protein: 28,
        fat: 28,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'gyudon',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 95,
        protein: 35,
        fat: 24,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'katsudon',
        category: MealFoodCategory.main,
        kcal: 800,
        carbs: 105,
        protein: 35,
        fat: 32,
        servingGrams: 550,
        canBeMainDish: true),
    MealFoodOption(
        id: 'yakisoba',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 95,
        protein: 25,
        fat: 22,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'okonomiyaki',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 70,
        protein: 28,
        fat: 30,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'takoyaki',
        category: MealFoodCategory.main,
        kcal: 450,
        carbs: 60,
        protein: 15,
        fat: 18,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'pho',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 90,
        protein: 30,
        fat: 8,
        servingGrams: 700,
        canBeMainDish: true),
    MealFoodOption(
        id: 'banhMi',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 65,
        protein: 25,
        fat: 20,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'padThai',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 95,
        protein: 28,
        fat: 26,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'tomYumSoup',
        category: MealFoodCategory.main,
        kcal: 250,
        carbs: 18,
        protein: 25,
        fat: 10,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'greenCurry',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 55,
        protein: 35,
        fat: 35,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'massamanCurry',
        category: MealFoodCategory.main,
        kcal: 750,
        carbs: 60,
        protein: 35,
        fat: 40,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'nasiGoreng',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 95,
        protein: 28,
        fat: 24,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'satay',
        category: MealFoodCategory.main,
        kcal: 450,
        carbs: 20,
        protein: 35,
        fat: 28,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'laksa',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 80,
        protein: 30,
        fat: 35,
        servingGrams: 600,
        canBeMainDish: true),
    MealFoodOption(
        id: 'butterChicken',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 30,
        protein: 40,
        fat: 40,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'chickenTikkaMasala',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 35,
        protein: 42,
        fat: 36,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'biryani',
        category: MealFoodCategory.main,
        kcal: 750,
        carbs: 105,
        protein: 35,
        fat: 25,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'naan',
        category: MealFoodCategory.main,
        kcal: 300,
        carbs: 50,
        protein: 9,
        fat: 8,
        servingGrams: 120,
        canBeMainDish: true),
    MealFoodOption(
        id: 'dal',
        category: MealFoodCategory.main,
        kcal: 350,
        carbs: 50,
        protein: 18,
        fat: 8,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'kebab',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 45,
        protein: 35,
        fat: 35,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'shawarma',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 55,
        protein: 35,
        fat: 32,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'falafel',
        category: MealFoodCategory.main,
        kcal: 450,
        carbs: 45,
        protein: 16,
        fat: 24,
        servingGrams: 250,
        canBeMainDish: true),
    MealFoodOption(
        id: 'hummus',
        category: MealFoodCategory.main,
        kcal: 250,
        carbs: 25,
        protein: 10,
        fat: 15,
        servingGrams: 150,
        canBeMainDish: true),
    MealFoodOption(
        id: 'shakshuka',
        category: MealFoodCategory.main,
        kcal: 350,
        carbs: 20,
        protein: 18,
        fat: 22,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'fishAndChips',
        category: MealFoodCategory.main,
        kcal: 800,
        carbs: 75,
        protein: 35,
        fat: 42,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'roastChicken',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 10,
        protein: 55,
        fat: 32,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'meatballs',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 40,
        protein: 35,
        fat: 30,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'macAndCheese',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 75,
        protein: 25,
        fat: 28,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'hotDog',
        category: MealFoodCategory.main,
        kcal: 500,
        carbs: 45,
        protein: 18,
        fat: 28,
        servingGrams: 220,
        canBeMainDish: true),
    MealFoodOption(
        id: 'burritoBowl',
        category: MealFoodCategory.main,
        kcal: 700,
        carbs: 85,
        protein: 38,
        fat: 22,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'chowMein',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 90,
        protein: 25,
        fat: 22,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'mapoTofu',
        category: MealFoodCategory.main,
        kcal: 550,
        carbs: 25,
        protein: 28,
        fat: 35,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'kungPaoChicken',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 45,
        protein: 40,
        fat: 35,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'dimSum',
        category: MealFoodCategory.main,
        kcal: 500,
        carbs: 60,
        protein: 25,
        fat: 20,
        servingGrams: 300,
        canBeMainDish: true),
    MealFoodOption(
        id: 'springRoll',
        category: MealFoodCategory.main,
        kcal: 250,
        carbs: 35,
        protein: 8,
        fat: 10,
        servingGrams: 150,
        canBeMainDish: true),
    MealFoodOption(
        id: 'friedNoodles',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 90,
        protein: 22,
        fat: 24,
        servingGrams: 450,
        canBeMainDish: true),
    MealFoodOption(
        id: 'congee',
        category: MealFoodCategory.main,
        kcal: 300,
        carbs: 55,
        protein: 12,
        fat: 6,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'wontonSoup',
        category: MealFoodCategory.main,
        kcal: 350,
        carbs: 45,
        protein: 20,
        fat: 10,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'pokeBowl',
        category: MealFoodCategory.main,
        kcal: 650,
        carbs: 80,
        protein: 35,
        fat: 20,
        servingGrams: 500,
        canBeMainDish: true),
    MealFoodOption(
        id: 'caesarSalad',
        category: MealFoodCategory.main,
        kcal: 450,
        carbs: 20,
        protein: 25,
        fat: 30,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'greekSalad',
        category: MealFoodCategory.main,
        kcal: 350,
        carbs: 20,
        protein: 12,
        fat: 25,
        servingGrams: 350,
        canBeMainDish: true),
    MealFoodOption(
        id: 'clamChowder',
        category: MealFoodCategory.main,
        kcal: 350,
        carbs: 30,
        protein: 15,
        fat: 20,
        servingGrams: 400,
        canBeMainDish: true),
    MealFoodOption(
        id: 'kimchi',
        category: MealFoodCategory.side,
        kcal: 30,
        carbs: 5,
        protein: 2,
        fat: 0,
        servingGrams: 50),
    MealFoodOption(
        id: 'pickledRadish',
        category: MealFoodCategory.side,
        kcal: 20,
        carbs: 4,
        protein: 0,
        fat: 0,
        servingGrams: 50),
    MealFoodOption(
        id: 'seasonedBeanSprouts',
        category: MealFoodCategory.side,
        kcal: 45,
        carbs: 6,
        protein: 3,
        fat: 2,
        servingGrams: 80),
    MealFoodOption(
        id: 'spinachNamul',
        category: MealFoodCategory.side,
        kcal: 45,
        carbs: 5,
        protein: 3,
        fat: 2,
        servingGrams: 80),
    MealFoodOption(
        id: 'seaweedSalad',
        category: MealFoodCategory.side,
        kcal: 35,
        carbs: 6,
        protein: 1,
        fat: 1,
        servingGrams: 80),
    MealFoodOption(
        id: 'lettuce',
        category: MealFoodCategory.side,
        kcal: 10,
        carbs: 2,
        protein: 1,
        fat: 0,
        servingGrams: 50),
    MealFoodOption(
        id: 'cucumber',
        category: MealFoodCategory.side,
        kcal: 15,
        carbs: 3,
        protein: 1,
        fat: 0,
        servingGrams: 100),
    MealFoodOption(
        id: 'tomato',
        category: MealFoodCategory.side,
        kcal: 20,
        carbs: 4,
        protein: 1,
        fat: 0,
        servingGrams: 120),
    MealFoodOption(
        id: 'avocado',
        category: MealFoodCategory.side,
        kcal: 160,
        carbs: 9,
        protein: 2,
        fat: 15,
        servingGrams: 100),
    MealFoodOption(
        id: 'broccoli',
        category: MealFoodCategory.side,
        kcal: 35,
        carbs: 7,
        protein: 3,
        fat: 0,
        servingGrams: 100),
    MealFoodOption(
        id: 'sweetPotato',
        category: MealFoodCategory.carb,
        kcal: 130,
        carbs: 31,
        protein: 2,
        fat: 0,
        servingGrams: 130),
    MealFoodOption(
        id: 'potato',
        category: MealFoodCategory.carb,
        kcal: 110,
        carbs: 26,
        protein: 3,
        fat: 0,
        servingGrams: 150),
    MealFoodOption(
        id: 'corn',
        category: MealFoodCategory.carb,
        kcal: 100,
        carbs: 22,
        protein: 3,
        fat: 1,
        servingGrams: 100),
    MealFoodOption(
        id: 'boiledEgg',
        category: MealFoodCategory.protein,
        kcal: 80,
        carbs: 1,
        protein: 6,
        fat: 5,
        servingGrams: 50),
    MealFoodOption(
        id: 'friedEgg',
        category: MealFoodCategory.protein,
        kcal: 100,
        carbs: 1,
        protein: 6,
        fat: 7,
        servingGrams: 60),
    MealFoodOption(
        id: 'omelet',
        category: MealFoodCategory.protein,
        kcal: 180,
        carbs: 2,
        protein: 12,
        fat: 13,
        servingGrams: 120),
    MealFoodOption(
        id: 'cheese',
        category: MealFoodCategory.protein,
        kcal: 70,
        carbs: 1,
        protein: 4,
        fat: 6,
        servingGrams: 20),
    MealFoodOption(
        id: 'tunaCan',
        category: MealFoodCategory.protein,
        kcal: 150,
        carbs: 0,
        protein: 30,
        fat: 5,
        servingGrams: 100),
    MealFoodOption(
        id: 'ham',
        category: MealFoodCategory.protein,
        kcal: 120,
        carbs: 2,
        protein: 10,
        fat: 8,
        servingGrams: 60),
    MealFoodOption(
        id: 'sausage',
        category: MealFoodCategory.protein,
        kcal: 250,
        carbs: 4,
        protein: 12,
        fat: 20,
        servingGrams: 100),
    MealFoodOption(
        id: 'bacon',
        category: MealFoodCategory.protein,
        kcal: 160,
        carbs: 1,
        protein: 12,
        fat: 12,
        servingGrams: 50),
    MealFoodOption(
        id: 'mackerel',
        category: MealFoodCategory.protein,
        kcal: 280,
        carbs: 0,
        protein: 25,
        fat: 20,
        servingGrams: 140),
    MealFoodOption(
        id: 'shrimp',
        category: MealFoodCategory.protein,
        kcal: 100,
        carbs: 1,
        protein: 20,
        fat: 1,
        servingGrams: 100),
    MealFoodOption(
        id: 'squid',
        category: MealFoodCategory.protein,
        kcal: 120,
        carbs: 3,
        protein: 24,
        fat: 2,
        servingGrams: 120),
    MealFoodOption(
        id: 'beans',
        category: MealFoodCategory.protein,
        kcal: 130,
        carbs: 20,
        protein: 8,
        fat: 3,
        servingGrams: 100),
    MealFoodOption(
        id: 'chickpeas',
        category: MealFoodCategory.protein,
        kcal: 170,
        carbs: 27,
        protein: 9,
        fat: 3,
        servingGrams: 100),
    MealFoodOption(
        id: 'lentils',
        category: MealFoodCategory.protein,
        kcal: 160,
        carbs: 28,
        protein: 12,
        fat: 1,
        servingGrams: 100),
    MealFoodOption(
        id: 'seaweedSoup',
        category: MealFoodCategory.soup,
        kcal: 100,
        carbs: 8,
        protein: 10,
        fat: 5,
        servingGrams: 300),
    MealFoodOption(
        id: 'beefSoup',
        category: MealFoodCategory.soup,
        kcal: 250,
        carbs: 5,
        protein: 25,
        fat: 15,
        servingGrams: 400),
    MealFoodOption(
        id: 'eggSoup',
        category: MealFoodCategory.soup,
        kcal: 90,
        carbs: 3,
        protein: 7,
        fat: 5,
        servingGrams: 250),
    MealFoodOption(
        id: 'tofuSoup',
        category: MealFoodCategory.soup,
        kcal: 250,
        carbs: 12,
        protein: 18,
        fat: 14,
        servingGrams: 400),
    MealFoodOption(
        id: 'vegetableSoup',
        category: MealFoodCategory.soup,
        kcal: 120,
        carbs: 20,
        protein: 5,
        fat: 2,
        servingGrams: 300),
    MealFoodOption(
        id: 'misoSoup',
        category: MealFoodCategory.soup,
        kcal: 60,
        carbs: 6,
        protein: 4,
        fat: 2,
        servingGrams: 200),
    MealFoodOption(
        id: 'chickenSoup',
        category: MealFoodCategory.soup,
        kcal: 300,
        carbs: 15,
        protein: 28,
        fat: 12,
        servingGrams: 450),
    MealFoodOption(
        id: 'dumplings',
        category: MealFoodCategory.snack,
        kcal: 350,
        carbs: 45,
        protein: 15,
        fat: 12,
        servingGrams: 200),
    MealFoodOption(
        id: 'friedSnack',
        category: MealFoodCategory.snack,
        kcal: 350,
        carbs: 40,
        protein: 8,
        fat: 20,
        servingGrams: 150),
    MealFoodOption(
        id: 'frenchFries',
        category: MealFoodCategory.snack,
        kcal: 350,
        carbs: 45,
        protein: 4,
        fat: 17,
        servingGrams: 150),
    MealFoodOption(
        id: 'riceCake',
        category: MealFoodCategory.snack,
        kcal: 220,
        carbs: 48,
        protein: 4,
        fat: 1,
        servingGrams: 100),
    MealFoodOption(
        id: 'breadSlice',
        category: MealFoodCategory.snack,
        kcal: 80,
        carbs: 15,
        protein: 3,
        fat: 1,
        servingGrams: 35),
    MealFoodOption(
        id: 'toast',
        category: MealFoodCategory.snack,
        kcal: 300,
        carbs: 40,
        protein: 10,
        fat: 12,
        servingGrams: 180),
    MealFoodOption(
        id: 'oatmeal',
        category: MealFoodCategory.snack,
        kcal: 250,
        carbs: 45,
        protein: 8,
        fat: 5,
        servingGrams: 250),
    MealFoodOption(
        id: 'cereal',
        category: MealFoodCategory.snack,
        kcal: 250,
        carbs: 50,
        protein: 6,
        fat: 3,
        servingGrams: 60),
    MealFoodOption(
        id: 'granola',
        category: MealFoodCategory.snack,
        kcal: 220,
        carbs: 35,
        protein: 6,
        fat: 7,
        servingGrams: 50),
    MealFoodOption(
        id: 'mixedNuts',
        category: MealFoodCategory.snack,
        kcal: 180,
        carbs: 6,
        protein: 6,
        fat: 16,
        servingGrams: 30),
    MealFoodOption(
        id: 'almonds',
        category: MealFoodCategory.snack,
        kcal: 170,
        carbs: 6,
        protein: 6,
        fat: 15,
        servingGrams: 30),
    MealFoodOption(
        id: 'iceCream',
        category: MealFoodCategory.snack,
        kcal: 250,
        carbs: 30,
        protein: 5,
        fat: 14,
        servingGrams: 120),
    MealFoodOption(
        id: 'chocolate',
        category: MealFoodCategory.snack,
        kcal: 220,
        carbs: 25,
        protein: 3,
        fat: 13,
        servingGrams: 40),
    MealFoodOption(
        id: 'cookie',
        category: MealFoodCategory.snack,
        kcal: 160,
        carbs: 24,
        protein: 2,
        fat: 7,
        servingGrams: 40),
    MealFoodOption(
        id: 'cake',
        category: MealFoodCategory.snack,
        kcal: 350,
        carbs: 50,
        protein: 5,
        fat: 15,
        servingGrams: 120),
    MealFoodOption(
        id: 'yogurt',
        category: MealFoodCategory.snack,
        kcal: 120,
        carbs: 18,
        protein: 6,
        fat: 3,
        servingGrams: 150),
    MealFoodOption(
        id: 'greekYogurt',
        category: MealFoodCategory.snack,
        kcal: 100,
        carbs: 6,
        protein: 15,
        fat: 0,
        servingGrams: 150),
    MealFoodOption(
        id: 'proteinShake',
        category: MealFoodCategory.drink,
        kcal: 180,
        carbs: 8,
        protein: 25,
        fat: 3,
        servingGrams: 300),
    MealFoodOption(
        id: 'wheyProtein',
        category: MealFoodCategory.drink,
        kcal: 120,
        carbs: 3,
        protein: 24,
        fat: 2,
        servingGrams: 35),
    MealFoodOption(
        id: 'milk',
        category: MealFoodCategory.drink,
        kcal: 130,
        carbs: 12,
        protein: 7,
        fat: 5,
        servingGrams: 200),
    MealFoodOption(
        id: 'soyMilk',
        category: MealFoodCategory.drink,
        kcal: 110,
        carbs: 9,
        protein: 7,
        fat: 4,
        servingGrams: 200),
    MealFoodOption(
        id: 'juice',
        category: MealFoodCategory.drink,
        kcal: 120,
        carbs: 28,
        protein: 1,
        fat: 0,
        servingGrams: 200),
    MealFoodOption(
        id: 'sportsDrink',
        category: MealFoodCategory.drink,
        kcal: 80,
        carbs: 20,
        protein: 0,
        fat: 0,
        servingGrams: 250),
    MealFoodOption(
        id: 'coffeeLatte',
        category: MealFoodCategory.drink,
        kcal: 150,
        carbs: 12,
        protein: 8,
        fat: 7,
        servingGrams: 300),
    MealFoodOption(
        id: 'americano',
        category: MealFoodCategory.drink,
        kcal: 5,
        carbs: 1,
        protein: 0,
        fat: 0,
        servingGrams: 300),
    MealFoodOption(
        id: 'cola',
        category: MealFoodCategory.drink,
        kcal: 140,
        carbs: 35,
        protein: 0,
        fat: 0,
        servingGrams: 355),
    MealFoodOption(
        id: 'water',
        category: MealFoodCategory.drink,
        kcal: 0,
        carbs: 0,
        protein: 0,
        fat: 0,
        servingGrams: 300),
    MealFoodOption(
        id: 'banana',
        category: MealFoodCategory.fruit,
        kcal: 105,
        carbs: 27,
        protein: 1,
        fat: 0,
        servingGrams: 120),
    MealFoodOption(
        id: 'apple',
        category: MealFoodCategory.fruit,
        kcal: 95,
        carbs: 25,
        protein: 0,
        fat: 0,
        servingGrams: 180),
    MealFoodOption(
        id: 'orange',
        category: MealFoodCategory.fruit,
        kcal: 60,
        carbs: 15,
        protein: 1,
        fat: 0,
        servingGrams: 130),
    MealFoodOption(
        id: 'grapes',
        category: MealFoodCategory.fruit,
        kcal: 70,
        carbs: 18,
        protein: 1,
        fat: 0,
        servingGrams: 100),
    MealFoodOption(
        id: 'strawberries',
        category: MealFoodCategory.fruit,
        kcal: 50,
        carbs: 12,
        protein: 1,
        fat: 0,
        servingGrams: 150),
    MealFoodOption(
        id: 'blueberries',
        category: MealFoodCategory.fruit,
        kcal: 85,
        carbs: 21,
        protein: 1,
        fat: 0,
        servingGrams: 150),
    MealFoodOption(
        id: 'saladGreens',
        category: MealFoodCategory.side,
        kcal: 30,
        carbs: 5,
        protein: 2,
        fat: 0,
        servingGrams: 100),
    MealFoodOption(
        id: 'seasonedSeaweed',
        category: MealFoodCategory.side,
        kcal: 25,
        carbs: 3,
        protein: 1,
        fat: 1,
        servingGrams: 10),
    MealFoodOption(
        id: 'laver',
        category: MealFoodCategory.side,
        kcal: 20,
        carbs: 2,
        protein: 2,
        fat: 1,
        servingGrams: 8),
    MealFoodOption(
        id: 'gyeranJjim',
        category: MealFoodCategory.protein,
        kcal: 120,
        carbs: 3,
        protein: 10,
        fat: 8,
        servingGrams: 150),
    MealFoodOption(
        id: 'jangjorim',
        category: MealFoodCategory.protein,
        kcal: 180,
        carbs: 8,
        protein: 20,
        fat: 8,
        servingGrams: 100),
    MealFoodOption(
        id: 'anchovyBokkeum',
        category: MealFoodCategory.side,
        kcal: 120,
        carbs: 10,
        protein: 10,
        fat: 5,
        servingGrams: 50),
    MealFoodOption(
        id: 'fishCakeBokkeum',
        category: MealFoodCategory.side,
        kcal: 180,
        carbs: 20,
        protein: 10,
        fat: 8,
        servingGrams: 100),
    MealFoodOption(
        id: 'kongjaban',
        category: MealFoodCategory.side,
        kcal: 150,
        carbs: 20,
        protein: 9,
        fat: 4,
        servingGrams: 80),
    MealFoodOption(
        id: 'cucumberKimchi',
        category: MealFoodCategory.side,
        kcal: 25,
        carbs: 5,
        protein: 1,
        fat: 0,
        servingGrams: 80),
    MealFoodOption(
        id: 'radishKimchi',
        category: MealFoodCategory.side,
        kcal: 25,
        carbs: 5,
        protein: 1,
        fat: 0,
        servingGrams: 80),
    MealFoodOption(
        id: 'kkakdugi',
        category: MealFoodCategory.side,
        kcal: 30,
        carbs: 6,
        protein: 1,
        fat: 0,
        servingGrams: 80),
    MealFoodOption(
        id: 'perillaLeaves',
        category: MealFoodCategory.side,
        kcal: 20,
        carbs: 4,
        protein: 1,
        fat: 0,
        servingGrams: 30),
    MealFoodOption(
        id: 'garlic',
        category: MealFoodCategory.side,
        kcal: 20,
        carbs: 4,
        protein: 1,
        fat: 0,
        servingGrams: 15),
    MealFoodOption(
        id: 'ssamjang',
        category: MealFoodCategory.side,
        kcal: 50,
        carbs: 7,
        protein: 2,
        fat: 2,
        servingGrams: 30),
    MealFoodOption(
        id: 'gochujang',
        category: MealFoodCategory.side,
        kcal: 35,
        carbs: 7,
        protein: 1,
        fat: 1,
        servingGrams: 20),
    MealFoodOption(
        id: 'doenjang',
        category: MealFoodCategory.side,
        kcal: 35,
        carbs: 4,
        protein: 3,
        fat: 1,
        servingGrams: 20),
    MealFoodOption(
        id: 'salsa',
        category: MealFoodCategory.side,
        kcal: 40,
        carbs: 8,
        protein: 1,
        fat: 0,
        servingGrams: 80),
    MealFoodOption(
        id: 'guacamole',
        category: MealFoodCategory.side,
        kcal: 100,
        carbs: 6,
        protein: 2,
        fat: 9,
        servingGrams: 60),
    MealFoodOption(
        id: 'tortillaChips',
        category: MealFoodCategory.snack,
        kcal: 150,
        carbs: 18,
        protein: 2,
        fat: 8,
        servingGrams: 30),
    MealFoodOption(
        id: 'pitaBread',
        category: MealFoodCategory.carb,
        kcal: 170,
        carbs: 33,
        protein: 6,
        fat: 1,
        servingGrams: 70),
    MealFoodOption(
        id: 'pickles',
        category: MealFoodCategory.side,
        kcal: 15,
        carbs: 3,
        protein: 0,
        fat: 0,
        servingGrams: 60),
    MealFoodOption(
        id: 'olives',
        category: MealFoodCategory.side,
        kcal: 60,
        carbs: 3,
        protein: 0,
        fat: 6,
        servingGrams: 40),
    MealFoodOption(
        id: 'sauerkraut',
        category: MealFoodCategory.side,
        kcal: 25,
        carbs: 5,
        protein: 1,
        fat: 0,
        servingGrams: 80),
    MealFoodOption(
        id: 'coleslaw',
        category: MealFoodCategory.side,
        kcal: 180,
        carbs: 16,
        protein: 2,
        fat: 12,
        servingGrams: 120),
    MealFoodOption(
        id: 'mashedPotatoes',
        category: MealFoodCategory.carb,
        kcal: 220,
        carbs: 35,
        protein: 4,
        fat: 8,
        servingGrams: 180),
    MealFoodOption(
        id: 'bakedBeans',
        category: MealFoodCategory.protein,
        kcal: 180,
        carbs: 32,
        protein: 9,
        fat: 2,
        servingGrams: 160),
    MealFoodOption(
        id: 'garlicBread',
        category: MealFoodCategory.snack,
        kcal: 200,
        carbs: 25,
        protein: 5,
        fat: 9,
        servingGrams: 70),
    MealFoodOption(
        id: 'onionSoup',
        category: MealFoodCategory.soup,
        kcal: 180,
        carbs: 22,
        protein: 6,
        fat: 8,
        servingGrams: 300),
    MealFoodOption(
        id: 'edamame',
        category: MealFoodCategory.protein,
        kcal: 120,
        carbs: 9,
        protein: 11,
        fat: 5,
        servingGrams: 100),
    MealFoodOption(
        id: 'mozzarella',
        category: MealFoodCategory.protein,
        kcal: 85,
        carbs: 1,
        protein: 6,
        fat: 6,
        servingGrams: 30),
    MealFoodOption(
        id: 'honey',
        category: MealFoodCategory.snack,
        kcal: 65,
        carbs: 17,
        protein: 0,
        fat: 0,
        servingGrams: 20),
    MealFoodOption(
        id: 'jam',
        category: MealFoodCategory.snack,
        kcal: 50,
        carbs: 13,
        protein: 0,
        fat: 0,
        servingGrams: 20),
    MealFoodOption(
        id: 'peanutButter',
        category: MealFoodCategory.snack,
        kcal: 190,
        carbs: 7,
        protein: 8,
        fat: 16,
        servingGrams: 32),
    MealFoodOption(
        id: 'crackers',
        category: MealFoodCategory.snack,
        kcal: 120,
        carbs: 20,
        protein: 3,
        fat: 4,
        servingGrams: 30),
    MealFoodOption(
        id: 'croissant',
        category: MealFoodCategory.snack,
        kcal: 230,
        carbs: 26,
        protein: 5,
        fat: 12,
        servingGrams: 60),
    MealFoodOption(
        id: 'bagel',
        category: MealFoodCategory.snack,
        kcal: 250,
        carbs: 50,
        protein: 9,
        fat: 2,
        servingGrams: 100),
    MealFoodOption(
        id: 'muffin',
        category: MealFoodCategory.snack,
        kcal: 300,
        carbs: 45,
        protein: 5,
        fat: 12,
        servingGrams: 100),
    MealFoodOption(
        id: 'pancakes',
        category: MealFoodCategory.snack,
        kcal: 350,
        carbs: 55,
        protein: 9,
        fat: 10,
        servingGrams: 180),
    MealFoodOption(
        id: 'waffles',
        category: MealFoodCategory.snack,
        kcal: 350,
        carbs: 50,
        protein: 8,
        fat: 12,
        servingGrams: 160),
  ];

  static List<MealFoodOption> get mainDishOptions {
    return _orderedFoodOptions(
      foodOptions.where((option) => option.canBeMainDish),
      _popularMainDishIds,
    );
  }

  static List<MealFoodOption> get companionFoodOptions {
    return _orderedFoodOptions(
      foodOptions.where((option) => option.canBeCompanion),
      _popularCompanionFoodIds,
    );
  }

  static List<MealFoodOption> _orderedFoodOptions(
    Iterable<MealFoodOption> options,
    List<String> preferredIds,
  ) {
    final preferredRank = <String, int>{
      for (var index = 0; index < preferredIds.length; index++)
        preferredIds[index]: index,
    };
    final naturalRank = <String, int>{
      for (var index = 0; index < foodOptions.length; index++)
        foodOptions[index].id: index,
    };
    final sorted = options.toList(growable: false);
    sorted.sort((a, b) {
      final aRank = preferredRank[a.id] ?? 10000 + (naturalRank[a.id] ?? 0);
      final bRank = preferredRank[b.id] ?? 10000 + (naturalRank[b.id] ?? 0);
      return aRank.compareTo(bRank);
    });
    return sorted;
  }

  static MealCalorieEstimate estimate(MealEntry entry) {
    return MealCalorieEstimate(
      breakfast: _estimateMeal(
        riceBowls: entry.breakfastRiceBowls,
        menu: entry.breakfastMenu,
        dishId: entry.breakfastDishId,
        dishPortion: entry.breakfastDishPortion,
        foodIds: entry.breakfastFoodIds,
      ),
      lunch: _estimateMeal(
        riceBowls: entry.lunchRiceBowls,
        menu: entry.lunchMenu,
        dishId: entry.lunchDishId,
        dishPortion: entry.lunchDishPortion,
        foodIds: entry.lunchFoodIds,
      ),
      dinner: _estimateMeal(
        riceBowls: entry.dinnerRiceBowls,
        menu: entry.dinnerMenu,
        dishId: entry.dinnerDishId,
        dishPortion: entry.dinnerDishPortion,
        foodIds: entry.dinnerFoodIds,
      ),
    );
  }

  static MealFoodOption? foodById(String id) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;
    for (final option in foodOptions) {
      if (option.id == normalizedId) return option;
    }
    return null;
  }

  static MealDishOption? dishById(String id) {
    final option = foodById(id);
    if (option == null || !option.canBeMainDish) return null;
    return option;
  }

  static MealNutritionEstimate nutritionForFoodIds(Iterable<String> foodIds) {
    final seen = <String>{};
    var total = const MealNutritionEstimate(kcal: 0);
    for (final rawId in foodIds) {
      final id = rawId.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      final option = foodById(id);
      if (option == null) continue;
      total = total.plus(option.nutrition);
    }
    return total;
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
    required Iterable<String> foodIds,
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
    final foodNutrition = nutritionForFoodIds(foodIds);
    final menuKcal = _estimateMenu(menu, skipRiceKeywords: riceBowls > 0);
    return riceNutrition
        .plus(dishNutrition)
        .plus(foodNutrition)
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
