String trainingProgramEmojiFor(String label) {
  final normalized = label.trim().toLowerCase();
  if (normalized.isEmpty) return '⚽';

  const keywordMap = <String, String>{
    'shoot': '🥅',
    '슈팅': '🥅',
    'finishing': '🥅',
    'dribble': '🦶',
    '드리블': '🦶',
    'touch': '🦶',
    '트래핑': '🦶',
    'trap': '🦶',
    'pass': '🎯',
    '패스': '🎯',
    'cross': '🎯',
    '크로스': '🎯',
    'def': '🛡️',
    '수비': '🛡️',
    'press': '🛡️',
    'tactic': '🧠',
    '전술': '🧠',
    'analysis': '🧠',
    '피지컬': '💪',
    'fitness': '💪',
    'strength': '💪',
    '체력': '💪',
    'conditioning': '💪',
    'speed': '💨',
    'agility': '💨',
    '민첩': '💨',
    'sprint': '💨',
    'recovery': '🧘',
    '회복': '🧘',
    'stretch': '🧘',
    'yoga': '🧘',
    'keeper': '🧤',
    'gk': '🧤',
    '골키퍼': '🧤',
    'match': '🏟️',
    'game': '🏟️',
    '시합': '🏟️',
  };

  for (final entry in keywordMap.entries) {
    if (normalized.contains(entry.key)) {
      return entry.value;
    }
  }
  return '⚽';
}
