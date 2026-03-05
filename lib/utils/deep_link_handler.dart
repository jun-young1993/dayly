/// dayly:// 딥링크 파싱 유틸리티.
///
/// 위젯 클릭 시 네이티브 레이어가 아래 형식의 URI를 전달한다:
///   dayly://detail/{widgetId}   → 특정 D-Day 상세 화면
///   dayly://home                → 홈 화면 (기본 동작)
///
/// Android:  AndroidManifest.xml intent-filter (scheme="dayly")
/// iOS:      Info.plist CFBundleURLSchemes + onGenerateRoute
sealed class DaylyDeepLink {
  const DaylyDeepLink();
}

/// 특정 D-Day 상세 화면으로 이동.
final class DaylyDetailLink extends DaylyDeepLink {
  const DaylyDetailLink(this.widgetId);
  final String widgetId;
}

/// 홈 화면으로 이동 (또는 단순 앱 열기).
final class DaylyHomeLink extends DaylyDeepLink {
  const DaylyHomeLink();
}

/// URI 문자열을 [DaylyDeepLink]로 파싱한다.
///
/// 예:
///   parseDaylyLink('dayly://detail/abc123') → DaylyDetailLink('abc123')
///   parseDaylyLink('dayly://home')          → DaylyHomeLink()
///   parseDaylyLink(null)                    → null
DaylyDeepLink? parseDaylyLink(String? uriString) {
  if (uriString == null || uriString.isEmpty) return null;

  final uri = Uri.tryParse(uriString);
  if (uri == null || uri.scheme != 'dayly') return null;

  // NOTE: Dart Uri.parse treats custom-scheme URIs as authority-based.
  // 'dayly://detail/abc123' → host='detail', pathSegments=['abc123']
  // 'dayly://home'          → host='home',   pathSegments=[]
  // This is intentional — we rely on host for the route, not pathSegments[0].
  final host = uri.host;
  final segments = uri.pathSegments;

  if (host == 'detail' && segments.isNotEmpty) {
    return DaylyDetailLink(segments.first);
  }
  if (host == 'home') {
    return const DaylyHomeLink();
  }
  return const DaylyHomeLink();
}
