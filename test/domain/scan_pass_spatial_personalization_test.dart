import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_personalization.dart';

void main() {
  late SpatialLibraryCatalog catalog;

  setUpAll(() {
    catalog = SpatialLibraryCatalog.fromJsonString(
      File('assets/scan_pass_spatial/catalog.json').readAsStringSync(),
    );
  });

  test('coverage counts unique bounded source playback and rejects jumps', () {
    const duration = 20.0;
    var coverage = const SpatialLibraryCoverage();
    coverage = coverage.recordPlaying(duration: duration, from: 0, to: 1);
    coverage = coverage.recordPlaying(duration: duration, from: 1, to: 2);
    coverage = coverage.recordPlaying(duration: duration, from: 1, to: 2);
    coverage = coverage.recordPlaying(duration: duration, from: 2, to: 12);
    coverage = coverage.recordPlaying(duration: duration, from: 2, to: 1);

    expect(coverage.coveredSeconds(duration), 2);
    expect(coverage.watchState(duration), SpatialLibraryWatchState.inProgress);
    expect(coverage.playedFinalInterval, isFalse);
  });

  test('watched requires 90 percent unique coverage and played final footage',
      () {
    const duration = 20.0;
    var coverage = const SpatialLibraryCoverage();
    for (var start = 0.0; start < 18; start += 1) {
      coverage = coverage.recordPlaying(
        duration: duration,
        from: start,
        to: start + 1,
      );
    }
    expect(coverage.fraction(duration), .9);
    expect(coverage.watched(duration), isFalse);

    coverage = coverage.recordPlaying(
      duration: duration,
      from: 19,
      to: 20,
    );
    expect(coverage.playedFinalInterval, isTrue);
    expect(coverage.watched(duration), isTrue);
  });

  test('sanitizing rejects stale source identities and invalid selectors', () {
    final scene = catalog.scenes.first;
    final preferences = SpatialLibraryPreferences(
      lastSceneIdentity: '${scene.id}:replaced-source',
      records: <String, SpatialLibrarySceneRecord>{
        '${scene.id}:replaced-source': const SpatialLibrarySceneRecord(
          resumeTime: 999,
          coverage: SpatialLibraryCoverage(
            intervals: <SpatialLibraryViewedInterval>[
              SpatialLibraryViewedInterval(0, 999),
            ],
            playedFinalInterval: true,
          ),
        ),
      },
      filters: const SpatialLibraryFilters(
        attackingTeam: 'Deleted team',
        player: 'Deleted player',
      ),
    ).sanitized(catalog);

    expect(preferences.lastSceneIdentity, isNull);
    expect(preferences.records, isEmpty);
    expect(preferences.filters.attackingTeam, isNull);
    expect(preferences.filters.player, isNull);
  });

  test('one filter pipeline orders unfinished and drives next navigation', () {
    final first = catalog.scenes[0];
    final second = catalog.scenes[1];
    final third = catalog.scenes[2];
    final smallCatalog = SpatialLibraryCatalog(
      version: catalog.version,
      provider: catalog.provider,
      license: catalog.license,
      sourceCommit: catalog.sourceCommit,
      sourceUrl: catalog.sourceUrl,
      matchCount: catalog.matchCount,
      scenes: <SpatialLibraryScene>[first, second, third],
      proofVersion: catalog.proofVersion,
      actionProofVersion: catalog.actionProofVersion,
      sourcePins: catalog.sourcePins,
    );
    final preferences = SpatialLibraryPreferences(
      records: <String, SpatialLibrarySceneRecord>{
        first.spatialHistoryIdentity: SpatialLibrarySceneRecord(
          coverage: SpatialLibraryCoverage(
            intervals: <SpatialLibraryViewedInterval>[
              SpatialLibraryViewedInterval(0, first.duration),
            ],
            playedFinalInterval: true,
          ),
        ),
        second.spatialHistoryIdentity: const SpatialLibrarySceneRecord(
          resumeTime: 3,
          coverage: SpatialLibraryCoverage(
            intervals: <SpatialLibraryViewedInterval>[
              SpatialLibraryViewedInterval(0, 3),
            ],
          ),
        ),
      },
    );
    final filtered = SpatialLibraryPersonalization.filteredScenes(
      catalog: smallCatalog,
      preferences: preferences,
      matchesQuery: (scene, query) => scene.matchesSearch(query),
    );

    expect(filtered.map((scene) => scene.id), <String>[
      second.id,
      third.id,
      first.id,
    ]);
    expect(
      SpatialLibraryPersonalization.nextUnfinished(
        filteredScenes: filtered,
        preferences: preferences,
        currentSceneId: first.id,
      )?.id,
      second.id,
    );

    final allWatched = SpatialLibraryPreferences(
      records: <String, SpatialLibrarySceneRecord>{
        for (final scene in smallCatalog.scenes)
          scene.spatialHistoryIdentity: SpatialLibrarySceneRecord(
            coverage: SpatialLibraryCoverage(
              intervals: <SpatialLibraryViewedInterval>[
                SpatialLibraryViewedInterval(0, scene.duration),
              ],
              playedFinalInterval: true,
            ),
          ),
      },
    );
    expect(
      SpatialLibraryPersonalization.nextUnfinished(
        filteredScenes: smallCatalog.scenes,
        preferences: allWatched,
        currentSceneId: first.id,
      ),
      isNull,
    );
  });

  test('bookmarked watch filter never equates bookmark with watched', () {
    final scene = catalog.scenes.first;
    final preferences = SpatialLibraryPreferences(
      filters: const SpatialLibraryFilters(
        watchFilter: SpatialLibraryWatchFilter.bookmarked,
      ),
      records: <String, SpatialLibrarySceneRecord>{
        scene.spatialHistoryIdentity:
            const SpatialLibrarySceneRecord(bookmarked: true),
      },
    );
    final filtered = SpatialLibraryPersonalization.filteredScenes(
      catalog: catalog,
      preferences: preferences,
      matchesQuery: (candidate, query) => candidate.matchesSearch(query),
    );

    expect(filtered.map((candidate) => candidate.id), <String>[scene.id]);
    expect(
      preferences.records[scene.spatialHistoryIdentity]!.coverage.watchState(
        scene.duration,
      ),
      SpatialLibraryWatchState.unwatched,
    );
  });
}
