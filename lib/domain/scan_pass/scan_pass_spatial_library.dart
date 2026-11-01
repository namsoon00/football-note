import 'dart:convert';
import 'dart:math' as math;

import 'real_match_replay.dart';

enum SpatialLearningTheme {
  lateralSwitch,
  forwardConnection,
  pressureSupport,
  carryThenConnect,
  wideToInside,
  combination,
  turnover,
  recovery,
}

enum SpatialEvidenceRole { departure, arrival }

class SpatialLibraryDiscovery {
  const SpatialLibraryDiscovery._();

  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      final folded = _spatialSearchCharacterFolds[character] ?? character;
      if (!RegExp(r"[\s\-_.·/\\'’]").hasMatch(folded)) {
        buffer.write(folded);
      }
    }
    return buffer.toString();
  }

  static bool matchesScene(
    SpatialLibraryScene scene,
    String query, {
    Iterable<String> themeTerms = const <String>[],
  }) {
    final tokens = query
        .trim()
        .split(RegExp(r'\s+'))
        .map(normalize)
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return true;

    final values = <String>{
      scene.home,
      scene.away,
      ..._aliasesFor(scene.home, _spatialTeamSearchAliases),
      ..._aliasesFor(scene.away, _spatialTeamSearchAliases),
      scene.focusPlayerName,
      ...scene.evidenceAnchors.map((anchor) => anchor.playerName),
      for (final player in scene.participantNames)
        ..._aliasesFor(player, _spatialPlayerSearchAliases),
      scene.theme.name,
      ...themeTerms,
    }.map(normalize).where((value) => value.isNotEmpty).toSet();
    return tokens.every(
      (token) => values.any((value) => value.contains(token)),
    );
  }

  static Iterable<String> _aliasesFor(
    String value,
    Map<String, List<String>> aliases,
  ) =>
      aliases[value] ?? const <String>[];
}

class SpatialEvidenceAnchor {
  final double time;
  final SpatialEvidenceRole role;
  final int playerId;
  final String playerName;

  const SpatialEvidenceAnchor({
    required this.time,
    required this.role,
    required this.playerId,
    required this.playerName,
  });
}

class SpatialEvidenceMetrics {
  final double forwardMeters;
  final double lateralMeters;
  final double startWidthMeters;
  final double insideGainMeters;
  final double? pressureMeters;
  final double carryMeters;
  final double sequenceSeconds;

  const SpatialEvidenceMetrics({
    required this.forwardMeters,
    required this.lateralMeters,
    required this.startWidthMeters,
    required this.insideGainMeters,
    required this.pressureMeters,
    required this.carryMeters,
    required this.sequenceSeconds,
  });
}

class SpatialObservedDefenderGap {
  final int actorId;
  final String actorName;
  final RealMatchReplayPoint actor;
  final int defenderId;
  final String defenderName;
  final RealMatchReplayPoint defender;
  final double meters;

  const SpatialObservedDefenderGap({
    required this.actorId,
    required this.actorName,
    required this.actor,
    required this.defenderId,
    required this.defenderName,
    required this.defender,
    required this.meters,
  });
}

class SpatialLibraryScene {
  final String id;
  final String asset;
  final String assetSha256;
  final SpatialLearningTheme theme;
  final int matchId;
  final String date;
  final String home;
  final String away;
  final int period;
  final int startFrame;
  final int endFrame;
  final double startClock;
  final double duration;
  final int focusPlayerId;
  final String focusPlayerName;
  final List<SpatialEvidenceAnchor> evidenceAnchors;
  final List<int> highlightPlayerIds;
  final bool attackingHome;
  final int attackDirection;
  final double evidenceStart;
  final double evidenceEnd;
  final double coreStart;
  final double coreEnd;
  final List<int> corePlayerIds;
  final List<int> supportPlayerIds;
  final List<int> opponentContextPlayerIds;
  final SpatialEvidenceMetrics metrics;
  final String sourceCommit;
  final String sourceUrl;

  const SpatialLibraryScene({
    required this.id,
    required this.asset,
    required this.assetSha256,
    required this.theme,
    required this.matchId,
    required this.date,
    required this.home,
    required this.away,
    required this.period,
    required this.startFrame,
    required this.endFrame,
    required this.startClock,
    required this.duration,
    required this.focusPlayerId,
    required this.focusPlayerName,
    required this.evidenceAnchors,
    required this.highlightPlayerIds,
    required this.attackingHome,
    required this.attackDirection,
    required this.evidenceStart,
    required this.evidenceEnd,
    required this.coreStart,
    required this.coreEnd,
    required this.corePlayerIds,
    required this.supportPlayerIds,
    required this.opponentContextPlayerIds,
    required this.metrics,
    required this.sourceCommit,
    required this.sourceUrl,
  });

  String get attackingTeam => attackingHome ? home : away;

  Set<String> get participantNames => <String>{
        focusPlayerName,
        ...evidenceAnchors.map((anchor) => anchor.playerName),
      };

  bool involvesPlayer(String playerName) =>
      participantNames.contains(playerName);

  bool matchesSearch(String query) =>
      SpatialLibraryDiscovery.matchesScene(this, query);

  SpatialObservedDefenderGap? observedNearbyDefender(
    RealMatchReplayData data,
    double time,
  ) {
    if (theme != SpatialLearningTheme.pressureSupport) return null;
    final actorId = evidenceAnchors.first.playerId;
    final actorIndex = data.playerIndex(actorId);
    final actorMetadata = data.players[actorIndex];
    final sample = data.sample(time);
    final actor = sample.players[actorIndex];
    if (actor == null || _distance(actor, sample.ball) > 3.5) return null;

    SpatialObservedDefenderGap? nearest;
    for (var index = 0; index < data.players.length; index++) {
      final opponent = data.players[index];
      final point = sample.players[index];
      if (opponent.home == actorMetadata.home || point == null) continue;
      final meters = _distance(actor, point);
      if (nearest == null || meters < nearest.meters) {
        nearest = SpatialObservedDefenderGap(
          actorId: actorId,
          actorName: actorMetadata.name!,
          actor: actor,
          defenderId: opponent.id,
          defenderName: opponent.name!,
          defender: point,
          meters: meters,
        );
      }
    }
    return nearest != null && nearest.meters <= 8 ? nearest : null;
  }

  void validateReplay(RealMatchReplayData data) {
    if (data.scene.id != id ||
        data.match.id != matchId ||
        data.match.home != home ||
        data.match.away != away ||
        data.match.date != date ||
        data.sourceCommit != sourceCommit ||
        data.sourceUrl != sourceUrl ||
        data.scene.focusPlayerId != focusPlayerId ||
        data.scene.attackDirection != attackDirection ||
        (data.startClock - startClock).abs() > 1 / data.fps ||
        (data.duration - duration).abs() > 1 / data.fps ||
        data.annotationSource != RealMatchReplayAnnotationSource.derived ||
        data.coverage != RealMatchReplayCoverage.broadcastVisible ||
        data.ballHeightAvailable ||
        highlightPlayerIds
            .any((id) => !data.players.any((player) => player.id == id))) {
      throw const FormatException(
        'Spatial replay scene does not match its catalog evidence.',
      );
    }
    if (data.hasDisplayReconstruction ||
        data.missingPlayerCoordinate == null ||
        data.sourcePossessionOwners.length != data.frames.length) {
      throw const FormatException(
        'Spatial replay must preserve source visibility without reconstruction.',
      );
    }
    final guardFrames = (data.fps * .5).round();
    for (final anchor in evidenceAnchors) {
      final index = data.playerIndex(anchor.playerId);
      final frame = (anchor.time * data.fps).round();
      final guardStart = frame - guardFrames;
      final guardEnd = frame + guardFrames;
      if (guardStart < 0 ||
          guardEnd >= data.frames.length ||
          data.sourcePossessionOwners[frame] != anchor.playerId ||
          !List<int>.generate(
            guardEnd - guardStart + 1,
            (offset) => guardStart + offset,
          ).every((value) => data.isVisibleAtFrame(value, index))) {
        throw const FormatException('Spatial evidence anchor is not observed.');
      }
      final sample = data.sample(anchor.time);
      final player = sample.players[index];
      if (player == null ||
          _distance(player, sample.ball) > 3.5 + 1 / data.fps) {
        throw const FormatException(
          'Spatial evidence owner is too far from the recorded ball.',
        );
      }
    }
    final coreStartFrame = (coreStart * data.fps).round();
    final coreEndFrame = (coreEnd * data.fps).round();
    for (final id in <int>{
      ...corePlayerIds,
      ...supportPlayerIds,
      ...opponentContextPlayerIds,
    }) {
      final index = data.playerIndex(id);
      for (var frame = coreStartFrame; frame <= coreEndFrame; frame++) {
        if (!data.isVisibleAtFrame(frame, index)) {
          throw const FormatException(
            'Spatial core or context actor has a visibility gap.',
          );
        }
      }
    }
    var checkedOwnedFrames = 0;
    var cursor = 0;
    while (cursor < data.sourcePossessionOwners.length) {
      final owner = data.sourcePossessionOwners[cursor];
      var end = cursor;
      while (end + 1 < data.sourcePossessionOwners.length &&
          data.sourcePossessionOwners[end + 1] == owner) {
        end++;
      }
      if (owner != null && end - cursor + 1 >= 3) {
        int ownerIndex;
        try {
          ownerIndex = data.playerIndex(owner);
        } on ArgumentError {
          throw const FormatException(
            'Spatial owned-ball actor is outside the active roster.',
          );
        }
        for (var frame = cursor; frame <= end; frame++) {
          checkedOwnedFrames++;
          if (!data.isVisibleAtFrame(frame, ownerIndex)) {
            throw const FormatException(
              'Spatial owned-ball actor has a visibility gap.',
            );
          }
        }
      }
      cursor = end + 1;
    }
    if (checkedOwnedFrames == 0) {
      throw const FormatException(
          'Spatial replay has no visible ownership run.');
    }
  }
}

class SpatialLibraryCatalog {
  static const expectedSourceCommit =
      '1ed50b775f93075c2a6d00d0d795f13b7b89709e';

  final int version;
  final String provider;
  final String license;
  final String sourceCommit;
  final String sourceUrl;
  final int matchCount;
  final List<SpatialLibraryScene> scenes;

  const SpatialLibraryCatalog({
    required this.version,
    required this.provider,
    required this.license,
    required this.sourceCommit,
    required this.sourceUrl,
    required this.matchCount,
    required this.scenes,
  });

  factory SpatialLibraryCatalog.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Spatial catalog must be a JSON object.');
    }
    return SpatialLibraryCatalog.fromJson(decoded);
  }

  factory SpatialLibraryCatalog.fromJson(Map<String, dynamic> json) {
    final values = _list(json, 'scenes');
    final scenes = values.map((value) {
      final item = _mapValue(value, 'spatial scene');
      final metrics = _map(item, 'metrics');
      final evidenceAnchors = _list(item, 'evidenceAnchors').map((value) {
        final anchor = _mapValue(value, 'evidence anchor');
        return SpatialEvidenceAnchor(
          time: _number(anchor, 'time'),
          role: _enumValue(
            SpatialEvidenceRole.values,
            _string(anchor, 'role'),
            'spatial evidence role',
          ),
          playerId: _integer(anchor, 'playerId'),
          playerName: _string(anchor, 'playerName'),
        );
      }).toList(growable: false);
      final highlightPlayerIds = _list(item, 'highlightPlayerIds')
          .map((value) => _integerValue(value, 'highlight player id'))
          .toList(growable: false);
      return SpatialLibraryScene(
        id: _string(item, 'id'),
        asset: _string(item, 'asset'),
        assetSha256: _string(item, 'assetSha256'),
        theme: _enumValue(
          SpatialLearningTheme.values,
          _string(item, 'theme'),
          'spatial theme',
        ),
        matchId: _integer(item, 'matchId'),
        date: _string(item, 'date'),
        home: _string(item, 'home'),
        away: _string(item, 'away'),
        period: _integer(item, 'period'),
        startFrame: _integer(item, 'startFrame'),
        endFrame: _integer(item, 'endFrame'),
        startClock: _number(item, 'startClock'),
        duration: _number(item, 'duration'),
        focusPlayerId: _integer(item, 'focusPlayerId'),
        focusPlayerName: _string(item, 'focusPlayerName'),
        evidenceAnchors: evidenceAnchors,
        highlightPlayerIds: highlightPlayerIds,
        attackingHome: _string(item, 'attackingTeam') == 'home',
        attackDirection: _integer(item, 'attackDirection'),
        evidenceStart: _number(item, 'evidenceStart'),
        evidenceEnd: _number(item, 'evidenceEnd'),
        coreStart: _number(item, 'coreStart'),
        coreEnd: _number(item, 'coreEnd'),
        corePlayerIds: _integerList(item, 'corePlayerIds'),
        supportPlayerIds: _integerList(item, 'supportPlayerIds'),
        opponentContextPlayerIds: _integerList(
          item,
          'opponentContextPlayerIds',
        ),
        metrics: SpatialEvidenceMetrics(
          forwardMeters: _number(metrics, 'forwardMeters'),
          lateralMeters: _number(metrics, 'lateralMeters'),
          startWidthMeters: _number(metrics, 'startWidthMeters'),
          insideGainMeters: _number(metrics, 'insideGainMeters'),
          pressureMeters: metrics['pressureMeters'] == null
              ? null
              : _number(metrics, 'pressureMeters'),
          carryMeters: _number(metrics, 'carryMeters'),
          sequenceSeconds: _number(metrics, 'sequenceSeconds'),
        ),
        sourceCommit: _string(item, 'sourceCommit'),
        sourceUrl: _string(item, 'sourceUrl'),
      );
    }).toList(growable: false);
    final catalog = SpatialLibraryCatalog(
      version: _integer(json, 'version'),
      provider: _string(json, 'provider'),
      license: _string(json, 'license'),
      sourceCommit: _string(json, 'sourceCommit'),
      sourceUrl: _string(json, 'sourceUrl'),
      matchCount: _integer(json, 'matchCount'),
      scenes: scenes,
    );
    catalog._validate();
    return catalog;
  }

  Set<int> get matchIds => scenes.map((scene) => scene.matchId).toSet();
  Set<String> get focalPlayers =>
      scenes.map((scene) => scene.focusPlayerName).toSet();
  Set<SpatialLearningTheme> get themes =>
      scenes.map((scene) => scene.theme).toSet();
  Set<String> get attackingTeams =>
      scenes.map((scene) => scene.attackingTeam).toSet();
  Set<String> participants({String? attackingTeam}) => scenes
      .where(
        (scene) =>
            attackingTeam == null || scene.attackingTeam == attackingTeam,
      )
      .expand((scene) => scene.participantNames)
      .toSet();

  List<SpatialLibraryScene> filtered({
    SpatialLearningTheme? theme,
    String query = '',
    String? attackingTeam,
    String? player,
  }) =>
      scenes
          .where((scene) => theme == null || scene.theme == theme)
          .where(
            (scene) =>
                attackingTeam == null || scene.attackingTeam == attackingTeam,
          )
          .where((scene) => player == null || scene.involvesPlayer(player))
          .where((scene) => scene.matchesSearch(query))
          .toList(growable: false);

  void _validate() {
    final ids = <String>{};
    if (version != 1 ||
        provider != 'SkillCorner Open Data' ||
        license != 'MIT' ||
        sourceCommit != expectedSourceCommit ||
        matchCount != 9 ||
        scenes.isEmpty ||
        !sourceUrl
            .startsWith('https://github.com/SkillCorner/opendata/tree/')) {
      throw const FormatException('Invalid spatial catalog metadata.');
    }
    for (final scene in scenes) {
      if (!ids.add(scene.id) ||
          !scene.asset.startsWith('assets/scan_pass_spatial/scenes/') ||
          scene.assetSha256.length != 64 ||
          scene.matchId <= 0 ||
          scene.date.isEmpty ||
          scene.home.isEmpty ||
          scene.away.isEmpty ||
          (scene.period != 1 && scene.period != 2) ||
          scene.startFrame < 0 ||
          scene.endFrame <= scene.startFrame ||
          scene.startClock < 0 ||
          scene.duration < 20 ||
          scene.duration > 40 ||
          scene.focusPlayerName.isEmpty ||
          scene.evidenceAnchors.length < 2 ||
          scene.evidenceAnchors.length > 3 ||
          scene.highlightPlayerIds.length < 4 ||
          scene.highlightPlayerIds.length > 6 ||
          scene.highlightPlayerIds.toSet().length !=
              scene.highlightPlayerIds.length ||
          !scene.highlightPlayerIds.contains(scene.focusPlayerId) ||
          scene.corePlayerIds.length < 2 ||
          scene.supportPlayerIds.isEmpty ||
          scene.opponentContextPlayerIds.isEmpty ||
          <int>{
            ...scene.corePlayerIds,
            ...scene.supportPlayerIds,
            ...scene.opponentContextPlayerIds,
          }.any((id) => !scene.highlightPlayerIds.contains(id)) ||
          scene.evidenceAnchors.any(
            (anchor) =>
                anchor.playerName.isEmpty ||
                !scene.highlightPlayerIds.contains(anchor.playerId),
          ) ||
          scene.attackDirection.abs() != 1 ||
          scene.evidenceStart < 4 ||
          scene.evidenceEnd <= scene.evidenceStart ||
          scene.duration - scene.evidenceEnd < 4 ||
          (scene.coreStart - (scene.evidenceStart - .5)).abs() > .001 ||
          (scene.coreEnd - (scene.evidenceEnd + .5)).abs() > .001 ||
          scene.sourceCommit != sourceCommit ||
          !scene.sourceUrl.startsWith('$sourceUrl/data/matches/')) {
        throw const FormatException('Invalid spatial catalog scene.');
      }
      for (var index = 0; index < scene.evidenceAnchors.length; index++) {
        final anchor = scene.evidenceAnchors[index];
        if (anchor.time <= 0 ||
            anchor.time >= scene.duration ||
            (index > 0 &&
                anchor.time <= scene.evidenceAnchors[index - 1].time)) {
          throw const FormatException('Invalid ordered spatial evidence.');
        }
      }
      if ((scene.evidenceAnchors.first.time - scene.evidenceStart).abs() >
              0.001 ||
          (scene.evidenceAnchors.last.time - scene.evidenceEnd).abs() > 0.001) {
        throw const FormatException('Spatial evidence bounds do not match.');
      }
    }
  }
}

const _spatialSearchCharacterFolds = <String, String>{
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ā': 'a',
  'ă': 'a',
  'ą': 'a',
  'æ': 'ae',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'ď': 'd',
  'đ': 'd',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ė': 'e',
  'ę': 'e',
  'ě': 'e',
  'ğ': 'g',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ī': 'i',
  'ı': 'i',
  'ľ': 'l',
  'ł': 'l',
  'ñ': 'n',
  'ń': 'n',
  'ň': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ō': 'o',
  'œ': 'oe',
  'ř': 'r',
  'ś': 's',
  'š': 's',
  'ş': 's',
  'ß': 'ss',
  'ť': 't',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ū': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ž': 'z',
  'ź': 'z',
  'ż': 'z',
};

const _spatialTeamSearchAliases = <String, List<String>>{
  'Manchester City': <String>[
    'Man City',
    'Man City FC',
    'MCFC',
    '맨시티',
    '맨체스터 시티',
    'マンチェスターシティ',
  ],
  'Liverpool': <String>['Liverpool FC', 'LFC', '리버풀', 'リヴァプール'],
  'Dortmund': <String>[
    'Borussia Dortmund',
    'BVB',
    '도르트문트',
    'ドルトムント',
  ],
  'Bayern Munchen': <String>[
    'Bayern München',
    'Bayern Munich',
    'FC Bayern',
    'Bayern',
    '바이에른',
    '바이에른 뮌헨',
    'バイエルン',
  ],
  'Juventus': <String>['Juve', '유벤투스', 'ユヴェントス'],
  'Inter': <String>[
    'Inter Milan',
    'Internazionale',
    '인테르',
    '인터 밀란',
    'インテル',
  ],
  'Real Madrid': <String>[
    'Real',
    'RMA',
    '레알',
    '레알 마드리드',
    'レアル',
    'レアルマドリード',
  ],
  'FC Barcelona': <String>[
    'Barcelona',
    'Barca',
    'Barça',
    'FCB',
    '바르셀로나',
    '바르사',
    'バルセロナ',
  ],
  'Paris': <String>[
    'Paris Saint-Germain',
    'Paris Saint Germain',
    'PSG',
    '파리',
    '파리 생제르맹',
    'パリ',
    'パリサンジェルマン',
  ],
  'Marseille': <String>[
    'Olympique Marseille',
    'Olympique de Marseille',
    'OM',
    '마르세유',
    'マルセイユ',
  ],
};

const _spatialPlayerSearchAliases = <String, List<String>>{
  'Aaron Ramsey': <String>['애런 램지'],
  'Achraf Hakimi': <String>['아슈라프 하키미'],
  'Alessandro Bastoni': <String>['알레산드로 바스토니'],
  'Alex Sandro': <String>['알렉스 산드루', '알렉스 산드로'],
  'Alisson Ramses Becker': <String>['알리송', '알리송 베케르'],
  'Ander Herrera': <String>['안데르 에레라'],
  'Antoine Griezmann': <String>['앙투안 그리즈만', '그리즈만'],
  'Arthur': <String>['아르투르'],
  'Arturo Vidal': <String>['아르투로 비달', '비달'],
  'Ashley Young': <String>['애슐리 영'],
  'Aymeric Laporte': <String>['아이메릭 라포르트', '라포르트'],
  'Benjamin Mendy': <String>['뱅자맹 멘디'],
  'Benjamin Pavard': <String>['뱅자맹 파바르'],
  'Bernardo Silva': <String>['베르나르두 실바', '베르나르도 실바'],
  'Casemiro': <String>['카세미루'],
  'Christian Eriksen': <String>['크리스티안 에릭센', '에릭센'],
  'Clément Lenglet': <String>['클레망 랑글레', '랑글레'],
  'Cristiano Ronaldo': <String>[
    '크리스티아누 호날두',
    '호날두',
    'クリスティアーノロナウド',
    'ロナウド',
  ],
  'Daniel Carvajal': <String>['다니 카르바할', '카르바할'],
  'David Alaba': <String>['다비드 알라바', '알라바'],
  'Dejan Lovren': <String>['데얀 로브렌', '로브렌'],
  'Douglas Costa': <String>['더글라스 코스타'],
  'Duje Caleta-Car': <String>['두예 찰레타차르', '칼레타카르'],
  'Ederson': <String>['에데르송'],
  'Emre Can': <String>['엠레 잔'],
  'Eric Garcia': <String>['에릭 가르시아'],
  'Fabinho': <String>['파비뉴'],
  'Federico Valverde': <String>['페데리코 발베르데', '발베르데'],
  'Frenkie de Jong': <String>['프렝키 더용', '프렝키 데용', '더용', '데용'],
  'Gareth Bale': <String>['가레스 베일', '베일'],
  'Georginio Wijnaldum': <String>['조르지니오 바이날둠', '바이날둠'],
  'Gerard Pique': <String>['제라르 피케', '피케'],
  'Gonzalo Higuain': <String>['곤살로 이과인', '이과인'],
  'Ilkay Gündogan': <String>['일카이 귄도안', '귄도안', '권도안'],
  'Isco': <String>['이스코'],
  'Ivan Rakitic': <String>['이반 라키티치', '라키티치'],
  'Javier Martinez': <String>['하비 마르티네스'],
  'Joe Gomez': <String>['조 고메즈', '고메즈'],
  'John Stones': <String>['존 스톤스', '스톤스'],
  'Jordan Amavi': <String>['조르당 아마비', '아마비'],
  'Jordan Henderson': <String>['조던 헨더슨', '헨더슨'],
  'Jordi Alba': <String>['조르디 알바', '알바'],
  'Jose Tasende': <String>['호세 타센데', '타센데'],
  'Joshua Kimmich': <String>['요주아 키미히', '키미히'],
  'Juan Cuadrado': <String>['후안 콰드라도', '콰드라도'],
  'Karim Benzema': <String>['카림 벤제마', '벤제마'],
  'Kevin de Bruyne': <String>[
    '케빈 더브라위너',
    '더브라위너',
    '데브라위너',
    'デブライネ',
  ],
  'Kingsley Coman': <String>['킹슬리 코망', '코망'],
  'Kwadwo Asamoah': <String>['콰드워 아사모아', '아사모아'],
  'Kyle Walker': <String>['카일 워커', '워커'],
  'Kylian Mbappe': <String>[
    'Kylian Mbappé',
    'Mbappé',
    '킬리안 음바페',
    '음바페',
    'エムバペ',
    'ムバッペ',
  ],
  'Lautaro Martinez': <String>['라우타로 마르티네스', '라우타로'],
  'Leandro Paredes': <String>['레안드로 파레데스', '파레데스'],
  'Leonardo Bonucci': <String>['레오나르도 보누치', '보누치'],
  'Lionel Messi': <String>['리오넬 메시', '메시', 'メッシ'],
  'Luis Suarez': <String>['루이스 수아레스', '수아레스'],
  'Luiz Fernandinho': <String>['페르난지뉴'],
  'Luka Modric': <String>['루카 모드리치', '모드리치'],
  'Manuel Akanji': <String>['마누엘 아칸지', '아칸지'],
  'Marc-Andre ter Stegen': <String>[
    'Marc-André ter Stegen',
    '마르크안드레 테어슈테겐',
    '테어 슈테겐',
    '테어슈테겐',
  ],
  'Marcelo': <String>['마르셀루'],
  'Marcelo Brozovic': <String>['마르셀로 브로조비치', '브로조비치'],
  'Marquinhos': <String>['마르키뉴스'],
  'Matias Vecino': <String>['마티아스 베시노', '베시노'],
  'Mats Hummels': <String>['마츠 후멜스', '후멜스'],
  'Matthijs de Ligt': <String>['마테이스 더리흐트', '더 리흐트', '더리흐트'],
  'Milan Skriniar': <String>['밀란 슈크리니아르', '슈크리니아르'],
  'Nelson Semedo': <String>['넬송 세메두', '세메두'],
  'Nicolo Barella': <String>['니콜로 바렐라', '바렐라'],
  'Paulo Dybala': <String>['파울로 디발라', '디발라'],
  'Raheem Sterling': <String>['라힘 스털링', '스털링'],
  'Raphael Guerreiro': <String>['하파엘 게헤이루', '게헤이루'],
  'Raphael Varane': <String>['라파엘 바란', '바란'],
  'Rodrigo Hernandez': <String>['로드리', '로드리고'],
  'Romelu Lukaku': <String>['로멜루 루카쿠', '루카쿠'],
  'Samir Handanovic': <String>['사미르 한다노비치', '한다노비치'],
  'Samuel Umtiti': <String>['사뮈엘 움티티', '움티티'],
  'Serge Gnabry': <String>['세르주 그나브리', '그나브리'],
  'Sergi Roberto': <String>['세르지 로베르토', '로베르토'],
  'Sergio Busquets': <String>['세르히오 부스케츠', '부스케츠'],
  'Sergio Ramos': <String>['세르히오 라모스', '라모스'],
  'Stefan de Vrij': <String>['스테판 더프레이', '더프레이'],
  'Thiago Alcantara': <String>['티아고 알칸타라', '알칸타라'],
  'Thiago Silva': <String>['치아구 실바', '티아고 실바'],
  'Toni Kroos': <String>['토니 크로스', '크로스', 'クロース'],
  'Trent Alexander-Arnold': <String>[
    '트렌트 알렉산더아놀드',
    '알렉산더 아놀드',
    '아놀드',
  ],
  'Virgil van Dijk': <String>['버질 반다이크', '반다이크'],
  'Wojciech Szczesny': <String>['보이치에흐 슈쳉스니', '슈쳉스니'],
};

double _distance(RealMatchReplayPoint a, RealMatchReplayPoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

T _enumValue<T extends Enum>(List<T> values, String name, String label) =>
    values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException('Invalid $label.'),
    );

Map<String, dynamic> _map(Map<String, dynamic> map, String key) =>
    _mapValue(map[key], key);

Map<String, dynamic> _mapValue(Object? value, String label) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$label must be a JSON object.');
  }
  return value;
}

List<dynamic> _list(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! List<dynamic>) {
    throw FormatException('$key must be a JSON array.');
  }
  return value;
}

List<int> _integerList(Map<String, dynamic> map, String key) => _list(map, key)
    .map((value) => _integerValue(value, key))
    .toList(growable: false);

String _string(Map<String, dynamic> map, String key) =>
    _stringValue(map[key], key);

String _stringValue(Object? value, String label) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$label must be a non-empty string.');
  }
  return value;
}

int _integer(Map<String, dynamic> map, String key) =>
    _integerValue(map[key], key);

int _integerValue(Object? value, String label) {
  if (value is! int) throw FormatException('$label must be an integer.');
  return value;
}

double _number(Map<String, dynamic> map, String key) =>
    _numberValue(map[key], key);

double _numberValue(Object? value, String label) {
  if (value is! num || !value.isFinite) {
    throw FormatException('$label must be finite.');
  }
  return value.toDouble();
}
