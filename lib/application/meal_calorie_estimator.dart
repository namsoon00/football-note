import '../domain/entities/meal_entry.dart';

class MealCalorieEstimate {
  final int breakfastKcal;
  final int lunchKcal;
  final int dinnerKcal;

  const MealCalorieEstimate({
    required this.breakfastKcal,
    required this.lunchKcal,
    required this.dinnerKcal,
  });

  int get totalKcal => breakfastKcal + lunchKcal + dinnerKcal;

  bool get hasEstimate => totalKcal > 0;
}

class MealCalorieEstimator {
  const MealCalorieEstimator._();

  static const int kcalPerRiceBowl = 300;

  static MealCalorieEstimate estimate(MealEntry entry) {
    return MealCalorieEstimate(
      breakfastKcal: _estimateMeal(
        riceBowls: entry.breakfastRiceBowls,
        menu: entry.breakfastMenu,
      ),
      lunchKcal: _estimateMeal(
        riceBowls: entry.lunchRiceBowls,
        menu: entry.lunchMenu,
      ),
      dinnerKcal: _estimateMeal(
        riceBowls: entry.dinnerRiceBowls,
        menu: entry.dinnerMenu,
      ),
    );
  }

  static int _estimateMeal({required double riceBowls, required String menu}) {
    final riceKcal = (riceBowls * kcalPerRiceBowl).round();
    final menuKcal = _estimateMenu(menu, skipRiceKeywords: riceBowls > 0);
    return riceKcal + menuKcal;
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
