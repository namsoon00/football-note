import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/korea_football_snapshot_service.dart';
import 'package:football_note/domain/entities/korea_football_snapshot.dart';

void main() {
  test('parses FIFA ranking snapshot from official country ranking html', () {
    const html = '''
<div class="header_header__4yysQ">Korea Republic</div>
<span class="ranking-update-dates_dateLabel__Zeead">Last official update:</span>
<span class="ranking-update-dates_dateValue__qjgpf">01 April 2026</span>
<div class="highlights_resultItemLabel__PcOy0"><span>Current rank</span></div>
<div class="highlights_resultItemValue__okL7z"><span class="">25th</span></div>
''';

    final snapshot = KoreaFootballSnapshotService.parseFifaRankingHtml(html);

    expect(snapshot, isNotNull);
    expect(snapshot!.teamName, 'Korea Republic');
    expect(snapshot.currentRank, 25);
    expect(snapshot.updatedAt, DateTime.utc(2026, 4, 1));
  });

  test(
    'parses recent KFA match results from official men national team html',
    () {
      const html = '''
<div class="result_info">
  <p class="result_title">
    <span class="title">2026 축구 국가대표팀 친선경기</span>
    <span style="display:block">오스트리아&nbsp;에른스트 하펠 경기장</span>
  </p>
  <ul onclick="layer_popup_national_result('10483');">
    <li class="korea">남자 국가대표팀 <span>0 </span></li>
    <li class="away">오스트리아 <span class="score_win">1 </span></li>
  </ul>
  <em style="top:40px;">04. 01 수요일 03:45</em>
</div>
<div class="result_info">
  <p class="result_title">
    <span class="title">2026 축구 국가대표팀 친선경기</span>
    <span style="display:block">영국&nbsp;스타디움 MK</span>
  </p>
  <ul onclick="layer_popup_national_result('10465');">
    <li class="korea">남자 국가대표팀 <span>0 </span></li>
    <li class="away">코트디부아르 <span class="score_win">4 </span></li>
  </ul>
  <em style="top:40px;">03. 28 토요일 23:00</em>
</div>
''';

      final matches = KoreaFootballSnapshotService.parseRecentMatchesHtml(html);

      expect(matches, hasLength(2));
      expect(matches.first.opponent, '오스트리아');
      expect(matches.first.koreaScore, 0);
      expect(matches.first.opponentScore, 1);
      expect(matches.first.outcome, KoreaMatchOutcome.loss);
      expect(matches.first.playedAt, DateTime(2026, 4, 1, 3, 45));
      expect(matches.last.opponent, '코트디부아르');
      expect(matches.last.playedAt, DateTime(2026, 3, 28, 23, 0));
    },
  );
}
