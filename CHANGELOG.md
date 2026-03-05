# CHANGELOG

---

## 1.2.0 — 2026-03-05

### Added — 위젯 스와이프 탐색 (다중 D-Day 네비게이션)

- **Android**: StackView 기반 컬렉션 위젯으로 전환 — fling(스와이프)으로 여러 D-Day 이벤트 탐색
  - `DaylyWidgetRemoteViewsService` + `RemoteViewsFactory` 추가
  - StackView 아이템 레이아웃: Small(`dayly_widget_stack_item_small`) / Medium(`dayly_widget_stack_item_medium`)
  - 컨테이너 레이아웃을 StackView 기반으로 전환
  - 아이템 클릭 시 해당 이벤트 딥링크(`dayly://detail/{id}`) 정상 동작
  - 위젯 추가 시 Config Activity 자동 실행 제거 (전체 이벤트 즉시 표시)
  - 위젯 리사이즈 시 자동 레이아웃 전환 (`onAppWidgetOptionsChanged`)
- **iOS**: Button + AppIntent 기반 이전/다음 네비게이션
  - `NextEventIntent` / `PrevEventIntent` AppIntent 추가
  - Small 위젯: 하단 `< 1/3 >` 네비게이션 바
  - Medium 위젯: 좌우 chevron 버튼 + 하단 페이지 인디케이터
  - 페이지 인덱스 UserDefaults 저장 (순환 탐색 지원)
  - 콘텐츠 영역 탭 시 기존 딥링크 동작 유지

### Notes
- Android: `StackView`는 세로 fling 제스처를 지원 (카드 스택 UI)
- iOS: 인터랙티브 위젯 버튼은 iOS 17+ 필수
- Flutter 측 변경 없음 (기존 JSON 배열 전달 구조 활용)

---

## 1.1.2 — 2026-03-05

### Fixed
- Android AppWidget SharedPreferences 이름 불일치 수정: `FlutterSharedPreferences` → `HomeWidgetPreferences` (home_widget 패키지 실제 저장소)
- Android AppWidget 키 불일치 수정: `flutter.dayly_widgets_json` → `dayly_widgets_json`
- `setOnClickPendingIntent` 대상 ID 수정: `android.R.id.background` → `R.id.widget_container` (레이아웃에 없는 ID 참조로 위젯 크래시 발생)

### Improved
- 앱이 포그라운드로 전환될 때(`AppLifecycleState.resumed`) 홈화면 위젯 D-Day 자동 재계산 및 갱신

---

## 1.1.1 — 2026-03-05

### Fixed
- 공유 캡처 시 `Future.delayed(16ms)` → `addPostFrameCallback` 교체 (프레임 완료 보장)
- 알림 권한 요청 타이밍 개선: 첫 위젯에만 요청하던 방식 → 매 위젯 추가 시 확인 + 앱 시작 시 자동 확인
- Hive 박스 비정상 종료 후 재시작 시 앱 크래시 방지 (init 실패 시 box 삭제 후 재시도)
- `print()` → `debugPrint()` 교체 (`auth_gate.dart`, `share_preview_screen_v2.dart`) — 릴리즈 빌드 로그 노출 방지

### Improved
- 공유 텍스트에 D-Day 카운트다운 정보 + 앱 스토어 링크 포함
- 위젯 16개 초과 시 알림 예약 불가 경고 다이얼로그 추가
- `SharedPreferences` 인스턴스 캐싱으로 반복 `getInstance()` 호출 제거
- Deep Link 파싱 코드에 `Uri.parse` authority-based 동작 설명 주석 추가

---

## 1.1.0 — 2026-03-05

### Added — 홈화면 위젯 (iOS WidgetKit + Android AppWidget)

- **Android AppWidget**: Small(2×2) / Medium(4×2) 위젯, RemoteViews 렌더링, 딥링크 클릭 처리
- **Android ConfigActivity**: 위젯 추가 시 D-Day 선택 구성 화면
- **iOS WidgetKit**: `DaylyWidget` Extension (AppIntentConfiguration + SwiftUI View)
- **딥링크**: `dayly://detail/{widgetId}` → 해당 D-Day 상세 화면
- 홈화면 위젯 추가 안내 배너 (앱 내 홈 화면)
- `home_widget: ^0.7.0` 패키지 추가

### Notes
- iOS는 Xcode에서 `DaylyWidget` Extension Target + App Group `group.juny.dayly` Capability 수동 설정 필요

---

## 1.0.1 — 2026-03-05

### Added — 사용자 정의 알림 옵션

- 알림 방식 선택 UI: 특정 시점(D-7/D-3/D-1/D-Day 체크박스) 또는 반복(N일 간격) 중 선택
- `NotificationSettingsPanel` 위젯: 마스터 토글 → Radio Group → 조건부 확장 (Progressive Disclosure)
- 위젯 생성/수정 화면에서 알림 설정 저장 및 복원

### Changed
- 알림 ID 비트 구조: 하위 4비트 → 하위 6비트 확장 (트리거 슬롯 최대 63개)
- `scheduleAll()` → `scheduleForSettings(model, settings)` — 설정 기반 동적 예약
- 반복 알림: 오늘 다음날부터 D-Day까지 최대 30회 예약 (AlarmManager 64개 제한 대응)

---

## 1.0.0 — 2026-03-04

### Added — 로컬 알림 시스템

- D-7 / D-3 / D-1 / D-Day 알림 자동 예약 (`zonedSchedule`, `exactAllowWhileIdle`)
- 재부팅 후 AlarmManager 자동 복원 (`RECEIVE_BOOT_COMPLETED`)
- 알림 ID 결정론적 생성: 재설치 후에도 동일 widgetId → 동일 알림 ID
- Android 13+ 런타임 권한 요청 (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`)
- `DaylyWidgetModel`에 영속 `id` 필드 추가 (구버전 자동 마이그레이션)

### Packages
- `flutter_local_notifications`, `hive_flutter`, `timezone`, `flutter_timezone`
