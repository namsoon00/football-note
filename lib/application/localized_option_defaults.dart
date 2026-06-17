class LocalizedOptionDefaults {
  static const List<List<String>> _locationVariants = [
    ['학교 운동장', '동네 운동장', '실내 체육관'],
    ['School field', 'Community field', 'Indoor gym'],
  ];

  static const List<List<String>> _footballProgramVariants = [
    ['기본기', '피지컬', '전술', '회복', '리프팅', '줄넘기'],
    [
      'Fundamentals',
      'Physical',
      'Tactical',
      'Recovery',
      'Lifting',
      'Jump rope'
    ],
    ['基本', '物理的な', '戦術的', '回復', 'リフティング', '縄跳び'],
  ];

  static const List<List<String>> _baseballProgramVariants = [
    ['송구', '타격', '수비', '주루', '컨디셔닝', '회복'],
    [
      'Throwing',
      'Batting',
      'Fielding',
      'Base Running',
      'Conditioning',
      'Recovery',
    ],
    ['送球', '打撃', '守備', '走塁', 'コンディショニング', '回復'],
  ];

  static const List<List<String>> _basketballProgramVariants = [
    ['볼 핸들링', '슈팅', '패스', '수비', '컨디셔닝', '회복'],
    [
      'Ball Handling',
      'Shooting',
      'Passing',
      'Defense',
      'Conditioning',
      'Recovery',
    ],
    ['ボールハンドリング', 'シュート', 'パス', '守備', 'コンディショニング', '回復'],
  ];

  static const List<List<String>> _tennisProgramVariants = [
    ['스트로크', '서브', '풋워크', '매치 플레이', '컨디셔닝', '회복'],
    ['Stroke', 'Serve', 'Footwork', 'Match Play', 'Conditioning', 'Recovery'],
    ['ストローク', 'サーブ', 'フットワーク', 'マッチプレー', 'コンディショニング', '回復'],
  ];

  static const List<List<String>> _footballDailyGoalVariants = [
    ['드리블', '패스 정확도', '슈팅', '체력', '수비 위치 선정', '퍼스트 터치'],
    [
      'Dribbling',
      'Passing Accuracy',
      'Shooting',
      'Fitness',
      'Defensive Positioning',
      'First Touch',
    ],
    ['ドリブル', 'パス精度', 'シュート', '体力', '守備位置取り', 'ファーストタッチ'],
  ];

  static const List<List<String>> _baseballDailyGoalVariants = [
    ['송구 정확도', '타격 컨택', '수비 글러브', '주루 판단', '반응 속도', '경기 이해'],
    [
      'Throwing Accuracy',
      'Batting Contact',
      'Fielding Glove',
      'Base Running',
      'Reaction Speed',
      'Game Awareness',
    ],
    ['送球精度', '打撃コンタクト', '守備グラブ', '走塁判断', '反応速度', '試合理解'],
  ];

  static const List<List<String>> _basketballDailyGoalVariants = [
    ['볼 핸들링', '슈팅 폼', '패스 선택', '수비 스텝', '리바운드', '체력'],
    [
      'Ball Handling',
      'Shooting Form',
      'Passing Choices',
      'Defensive Footwork',
      'Rebounding',
      'Fitness',
    ],
    ['ボールハンドリング', 'シュートフォーム', 'パス選択', '守備ステップ', 'リバウンド', '体力'],
  ];

  static const List<List<String>> _tennisDailyGoalVariants = [
    ['서브 안정성', '포핸드', '백핸드', '풋워크', '랠리 지속', '경기 전략'],
    [
      'Serve Consistency',
      'Forehand',
      'Backhand',
      'Footwork',
      'Rally Consistency',
      'Match Strategy',
    ],
    ['サーブ安定性', 'フォアハンド', 'バックハンド', 'フットワーク', 'ラリー継続', '試合戦略'],
  ];

  static const List<List<String>> _nextGoalVariants = [
    ['패스 정확도 높이기', '약발 사용 늘리기', '퍼스트 터치 안정화', '수비 위치 선정 연습', '드리블 속도 올리기'],
    [
      'Improve passing accuracy',
      'Use weak foot more',
      'Stabilize first touch',
      'Practice defensive positioning',
      'Increase dribble speed',
    ],
  ];

  static List<String> normalizeOptions({
    required String key,
    required List<String> stored,
    required List<String> localizedDefaults,
  }) {
    final variants = _variantsForKey(key);
    if (variants == null) return List<String>.from(stored);

    final normalized = <String>[];
    for (final item in stored) {
      final value = item.trim();
      if (value.isEmpty) continue;
      final mapped = _translateKnownValue(
            value: value,
            variants: variants,
            localizedDefaults: localizedDefaults,
          ) ??
          value;
      if (!normalized.contains(mapped)) {
        normalized.add(mapped);
      }
    }
    if (_isProgramOptionsKey(key)) {
      for (final item in localizedDefaults) {
        final value = item.trim();
        if (value.isNotEmpty && !normalized.contains(value)) {
          normalized.add(value);
        }
      }
    }
    return normalized.isEmpty
        ? List<String>.from(localizedDefaults)
        : normalized;
  }

  static String normalizeDefaultValue({
    required String key,
    required String? storedValue,
    required List<String> localizedDefaults,
    required List<String> options,
    bool preserveCustomValue = false,
  }) {
    if (options.isEmpty) return '';
    final fallback = options.first;
    final value = storedValue?.trim();
    if (value == null || value.isEmpty) return fallback;

    if (options.contains(value)) return value;

    final variants = _variantsForKey(key);
    if (variants == null) return preserveCustomValue ? value : fallback;
    final mapped = _translateKnownValue(
      value: value,
      variants: variants,
      localizedDefaults: localizedDefaults,
    );
    if (mapped != null && options.contains(mapped)) {
      return mapped;
    }
    return preserveCustomValue ? value : fallback;
  }

  static List<List<String>>? _variantsForKey(String key) {
    switch (key) {
      case 'locations':
      case 'default_location':
        return _locationVariants;
      case 'programs':
      case 'default_program':
        return _footballProgramVariants;
      case 'programs_baseball':
      case 'default_program_baseball':
        return _baseballProgramVariants;
      case 'programs_basketball':
      case 'default_program_basketball':
        return _basketballProgramVariants;
      case 'programs_tennis':
      case 'default_program_tennis':
        return _tennisProgramVariants;
      case 'daily_goals':
        return _footballDailyGoalVariants;
      case 'daily_goals_baseball':
        return _baseballDailyGoalVariants;
      case 'daily_goals_basketball':
        return _basketballDailyGoalVariants;
      case 'daily_goals_tennis':
        return _tennisDailyGoalVariants;
      case 'next_goals':
        return _nextGoalVariants;
      default:
        return null;
    }
  }

  static bool _isProgramOptionsKey(String key) {
    return key == 'programs' ||
        key == 'programs_baseball' ||
        key == 'programs_basketball' ||
        key == 'programs_tennis';
  }

  static String? _translateKnownValue({
    required String value,
    required List<List<String>> variants,
    required List<String> localizedDefaults,
  }) {
    for (final variant in variants) {
      for (var i = 0; i < variant.length; i++) {
        if (variant[i] == value && i < localizedDefaults.length) {
          return localizedDefaults[i];
        }
      }
    }
    return null;
  }
}
