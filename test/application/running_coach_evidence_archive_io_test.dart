import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_coach_evidence_archive.dart';
import 'package:football_note/domain/entities/running_coach_session.dart';
import 'package:football_note/domain/entities/running_video_analysis_result.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const poseChannel = MethodChannel('football_note/running_pose_analysis');
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempRoot;
  late Directory documentsDirectory;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('running-evidence-test-');
    documentsDirectory = Directory('${tempRoot.path}/documents')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return documentsDirectory.path;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(poseChannel, null);
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('stores, reads, serializes, and deletes extracted JPEG evidence',
      () async {
    final sourceVideo = File('${tempRoot.path}/source.mov')
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);
    final jpegA = Uint8List.fromList(_imageBytes());
    final jpegB = Uint8List.fromList(_imageBytes());
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(poseChannel, (call) async {
      calls.add(call);
      expect(call.method, 'extractRunningEvidenceFrames');
      final arguments = call.arguments! as Map<Object?, Object?>;
      expect(arguments['timestampsMs'], orderedEquals(<int>[100, 240]));
      return <Map<String, Object?>>[
        <String, Object?>{
          'timestampMs': 100,
          'bytes': jpegA,
          'width': 1,
          'height': 1,
        },
        <String, Object?>{
          'timestampMs': 240,
          'bytes': jpegB,
          'width': 1,
          'height': 1,
        },
      ];
    });

    final requests = <RunningCoachEvidenceFrameRequest>[
      const RunningCoachEvidenceFrameRequest(
        id: 'posture-representativePosture-100',
        timestamp: Duration(milliseconds: 100),
        kind: RunningMetricEvidenceKind.posture,
        role: RunningMetricEvidenceFrameRole.representativePosture,
      ),
      const RunningCoachEvidenceFrameRequest(
        id: 'posture-second-100',
        timestamp: Duration(milliseconds: 100),
        kind: RunningMetricEvidenceKind.posture,
        role: RunningMetricEvidenceFrameRole.representativePosture,
      ),
      const RunningCoachEvidenceFrameRequest(
        id: 'landing-contact-240',
        timestamp: Duration(milliseconds: 240),
        kind: RunningMetricEvidenceKind.landing,
        role: RunningMetricEvidenceFrameRole.initialContact,
      ),
    ];

    final result = await archiveRunningCoachEvidenceImages(
      sourceVideo: XFile(sourceVideo.path),
      sessionId: 'session-1',
      requests: requests,
    );

    expect(calls, hasLength(1));
    expect(result.status, RunningCoachEvidenceArchiveStatus.success);
    expect(result.requestedCount, 3);
    expect(result.savedCount, 3);
    expect(result.images, hasLength(3));
    expect(await readArchivedRunningCoachEvidenceImage(result.images.first),
        jpegA);
    expect(File(result.images.first.storageReference).existsSync(), isTrue);
    expect(
      result.images
          .where(
              (image) => image.timestamp == const Duration(milliseconds: 100))
          .map((image) => image.storageReference)
          .toSet(),
      hasLength(1),
    );

    final session = RunningCoachSessionAnalysis(
      id: 'session-1',
      analyzedAt: DateTime(2026, 8, 9, 12),
      source: RunningCoachSessionSource.uploadVideo,
      overallScore: 80,
      scoreEligibility: RunningCoachScoreEligibility.unavailable,
      duration: const Duration(seconds: 5),
      sampledFrames: 10,
      validFrames: 8,
      primaryMetric: RunningCoachMetric.posture,
      primaryFinding: RunningCoachFinding.postureAligned,
      primaryStatus: RunningCoachStatus.good,
      primaryScore: 80,
      primaryValue: 8,
      primaryConfidence: 0.8,
      evidenceImages: result.images,
      evidenceArchive: RunningCoachEvidenceArchiveSummary(
        requestedCount: result.requestedCount,
        savedCount: result.savedCount,
        status: result.status,
        failureCode: result.failureCode,
      ),
    );
    final restored = RunningCoachSessionAnalysis.fromMap(session.toMap());
    expect(restored.evidenceImages, hasLength(3));
    expect(restored.evidenceArchive.status,
        RunningCoachEvidenceArchiveStatus.success);
    expect(restored.evidenceArchive.requestedCount, 3);
    expect(restored.evidenceArchive.savedCount, 3);

    await deleteArchivedRunningCoachEvidenceImages(result.images);
    expect(File(result.images.first.storageReference).existsSync(), isFalse);
    expect(File(result.images.last.storageReference).existsSync(), isFalse);
  });

  test('keeps platform extraction failure code in the archive result',
      () async {
    final sourceVideo = File('${tempRoot.path}/source.mov')
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(poseChannel, (call) async {
      throw PlatformException(code: 'decoder_unavailable');
    });

    final result = await archiveRunningCoachEvidenceImages(
      sourceVideo: XFile(sourceVideo.path),
      sessionId: 'session-2',
      requests: const <RunningCoachEvidenceFrameRequest>[
        RunningCoachEvidenceFrameRequest(
          id: 'posture-representativePosture-100',
          timestamp: Duration(milliseconds: 100),
          kind: RunningMetricEvidenceKind.posture,
          role: RunningMetricEvidenceFrameRole.representativePosture,
        ),
      ],
    );

    expect(result.images, isEmpty);
    expect(result.status, RunningCoachEvidenceArchiveStatus.failed);
    expect(result.failureCode, 'decoder_unavailable');
  });
}

List<int> _imageBytes() => base64Decode(
      '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAK'
      'CgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0o'
      'MCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgo'
      'KCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAED'
      'ASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL'
      '/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKB'
      'kaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdI'
      'SUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZ'
      'mqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl'
      '5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQF'
      'BgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdh'
      'cRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5'
      'OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImK'
      'kpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX'
      '2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD6pooooA//2Q==',
    );
