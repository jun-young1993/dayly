/// 홈화면 위젯 연동 관련 상수 정의.
///
/// - App Group ID: iOS에서 앱과 위젯 Extension이 UserDefaults를 공유하기 위한 식별자.
///   Xcode > Runner target > Signing & Capabilities > App Groups 에 동일 값을 추가해야 함.
/// - androidWidgetName: AppWidgetProvider 클래스 이름 (패키지명 제외 단순 클래스명).
/// - iOSWidgetName: WidgetKit Extension bundle identifier 기준 위젯 kind 이름.
class HomeWidgetConfig {
  const HomeWidgetConfig._();

  static const String appGroupId = 'group.juny.dayly';
  static const String androidWidgetName = 'DaylyAppWidget';
  static const List<String> androidAdditionalWidgetNames = [
    'DaylyAppWidgetMedium',
    'DaylyAppWidgetLarge',
  ];
  static const String iOSWidgetName = 'DaylyWidget';

  // SharedPreferences / UserDefaults 저장 키
  static const String keyWidgetsJson = 'dayly_widgets_json';
  static const String keySelectedWidgetId = 'dayly_selected_widget_id';
}
