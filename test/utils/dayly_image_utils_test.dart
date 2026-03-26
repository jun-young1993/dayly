import 'dart:io';

import 'package:dayly/utils/dayly_image_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// path_provider를 테스트 환경에서 systemTemp 디렉터리로 대체하는 Fake.
class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProvider();
  });

  group('resolveWidgetBackgroundImagePath', () {
    test('null 입력 → null 반환', () async {
      expect(await resolveWidgetBackgroundImagePath(null), isNull);
    });

    test('절대경로 + 파일 없음 → null 반환', () async {
      expect(
        await resolveWidgetBackgroundImagePath('/nonexistent/file.jpg'),
        isNull,
      );
    });

    test('절대경로 + 파일 존재 → 동일 절대경로 반환', () async {
      final file = File('${Directory.systemTemp.path}/dayly_abs_test.jpg')
        ..createSync();
      addTearDown(file.deleteSync);

      final result = await resolveWidgetBackgroundImagePath(file.path);
      expect(result, equals(file.path));
    });

    test('상대경로 + 파일 존재 → getApplicationDocumentsDirectory 기준 절대경로 반환', () async {
      final file = File('${Directory.systemTemp.path}/dayly_rel_test.jpg')
        ..createSync();
      addTearDown(file.deleteSync);

      // _FakePathProvider가 systemTemp를 반환하므로 상대경로 "파일명"이 systemTemp 기준으로 해석됨
      final result =
          await resolveWidgetBackgroundImagePath('dayly_rel_test.jpg');
      expect(result, equals(file.path));
    });

    test('상대경로 + 파일 없음 → null 반환', () async {
      final result =
          await resolveWidgetBackgroundImagePath('nonexistent_bg.jpg');
      expect(result, isNull);
    });

    test('서브디렉터리 상대경로 + 파일 존재 → 절대경로 반환', () async {
      final dir = Directory('${Directory.systemTemp.path}/backgrounds')
        ..createSync(recursive: true);
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/bg_test.jpg')..createSync();

      final result =
          await resolveWidgetBackgroundImagePath('backgrounds/bg_test.jpg');
      expect(result, equals(file.path));
    });
  });
}
