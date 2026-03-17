import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 위젯 배경 이미지 경로를 절대 경로로 해석한다.
///
/// - 이미 절대 경로이면 파일 존재 여부만 확인.
/// - 상대 경로이면 앱 Documents 디렉터리 기준으로 조합.
/// - 파일이 없거나 예외 발생 시 null 반환.
Future<String?> resolveWidgetBackgroundImagePath(String? path) async {
  if (path == null) return null;
  try {
    if (p.isAbsolute(path)) {
      return await File(path).exists() ? path : null;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final absPath = '${appDir.path}/$path';
    return await File(absPath).exists() ? absPath : null;
  } catch (_) {
    return null;
  }
}
