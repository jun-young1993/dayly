# PROGRESS — 처리 완료 항목 요약

> 최종 업데이트: 2026-03-25
> 현재 버전: **1.8.2+7**

---

## ✅ 완료된 작업 (최신 순)

### [v1.8.2+7] BIZ-4 — 기념일/일정 자동 반복 이벤트 (2026-03-22)

- `DaylyRecurringType { annual, monthly }` enum 추가 (`lib/utils/dayly_time.dart`)
- `DaylyWidgetModel`에 `isRecurring: bool`, `recurringType: DaylyRecurringType?` 필드 추가 (기존 JSON 하위 호환)
- `advanceRecurringOnce()` — 윤년(Feb 29 → Feb 28), 단월(Jan 31 → Feb 28) 처리 포함
- `advanceIfPast()` — 수년치 gap 커버 (최대 1200회 guard)
- `advanceRecurringAll()` — 앱 시작 및 resume 시 일괄 진행
- `add_widget_bottom_sheet.dart` — SegmentedButton "없음 / 매년 / 매월" UI 추가 (ko/ja/en 로컬라이징)
- `widget_grid_screen._load()` 및 `app.didChangeAppLifecycleState(resumed)` 훅 연결
- **Dart 유닛테스트 11개** (`test/utils/dayly_time_test.dart`): annual/monthly, 윤년, 단월 클램프, 멀티 사이클, 구버전 JSON 호환

---

### [v1.8.1+6] BIZ-3 — iOS 공유 링크 App Store 분기 (2026-03-22)

- `share_preview_screen_v2.dart`: iOS → App Store 링크, Android → Play Store 링크로 자동 분기
- `Platform.isIOS` (`dart:io`) 사용

---

### [v1.8.1+6] BIZ-2 — App Open 광고 쿨다운 영속화 (2026-03-22)

- `flutter_ui_kit_google_mobile_ads`에 `SharedPreferences` 기반 `_lastShownTime` 영속화
- `main.dart`: `cooldown = const Duration(hours: 24)` 설정
- 앱 재시작 후에도 24h 쿨다운 유지
- stale TODO 주석 2개 제거

---

### [v1.8.1+6] BIZ-1 — Firebase Analytics 이벤트 4종 (2026-03-22)

- `lib/utils/dayly_analytics.dart` 신규 생성
  - `first_widget_created` — 첫 위젯 생성 시
  - `share_tapped` — 공유 버튼 탭 시
  - `home_widget_installed` — 홈 화면 위젯 탭으로 앱 실행 시
  - `premium_tapped` — 프리미엄 UI 탭 시 (BIZ-6 연동 예정)
- `main.dart`: `Firebase.initializeApp()` try/catch 추가 (네트워크 오류 시 앱 크래시 방지)

---

### [v1.8.0] iOS Large(4×4) 위젯 + 배경 이미지 지원 (2026-03-17~18)

- `DaylyLargeView` 신규 생성 (카운트다운 44pt, 문구 16pt, 3줄)
- iOS 위젯 시간 기반 진행 바 (Medium/Large): `createdAt → targetDate` 경과 비율 시각화
- iOS 위젯 배경 이미지 지원 (Medium/Large): App Group 컨테이너에서 ImageIO 기반 400×400 다운샘플링
- 배경 이미지 시 자동 흰색 텍스트 전환 (paper/fog 등 밝은 테마 대응)
- `HomeWidgetData.createdAt` 필드 추가 + 직렬화 반영
- Flutter iOS 이미지 공유 파이프라인: App Group 공유 컨테이너로 복사

---

### [v1.7.8] Small 위젯 배경 이미지 + Dead Code 제거 (2026-03-19)

- `DaylySmallView`에서 `loadBgImage()` → `loadWidgetBackgroundImage(path:)`로 교체 (절대 경로 지원)
- Medium 뷰: `theme.sub.opacity(0.5)` 중복 버그 제거
- `loadBgImage()` 함수 완전 제거
- 중복 App Group 복사 인프라 제거 (`AppDelegate.swift` MethodChannel 핸들러 삭제)

---

### [v1.7.7] iOS App Group 채널 등록 타이밍 수정 (2026-03-19)

- `AppDelegate` MethodChannel 등록 위치를 `didFinishLaunchingWithOptions` → `didInitializeImplicitFlutterEngine`으로 이동
- App Group 복사 실패 로그 추가
- 배경 이미지 크기 제한 추가 (`maxWidth: 1024, maxHeight: 1024`)

---

### [v1.7.6] iOS 홈화면 위젯 배경 이미지 지원 (2026-03-19)

- `AppDelegate.swift`: MethodChannel `"juny.dayly/app_group"` 추가
- `EventDetailScreen._selectImageFromGallery()`: App Group 컨테이너에도 이미지 복사
- `DaylySmallView` / `DaylyMediumView`: 배경 이미지(opacity 0.30) + 오버레이 레이어 추가

---

### [v1.7.5] 홈화면 위젯 즉시 갱신 버그 수정 (2026-03-19)

- `EventDetailScreen`에 `onWidgetChanged` 콜백 추가
- `WidgetsBindingObserver` 믹스인 추가 (백그라운드 전환 시 자동 콜백)
- `WidgetGridScreen._openDetail()`에서 콜백 주입 → Android 위젯 즉시 갱신

---

### [v1.7.4] Android 홈 위젯 이미지 로딩 로그 (2026-03-17)

- `resolveImagePath()` / `loadScaledBitmap()` catch 블록에 `Log.w` / `Log.e` 추가

---

### [v1.7.3] Android 홈화면 위젯 배경 이미지 지원 Medium/Large (2026-03-17)

- `HomeWidgetData`에 `backgroundImagePath` 필드 추가 + 직렬화
- Kotlin `WidgetDisplayData`에 `backgroundImagePath` 파싱
- `resolveImagePath()` / `loadScaledBitmap()` 헬퍼 — 400px 다운샘플링
- XML: `dayly_widget_stack_item_medium/large.xml` → FrameLayout + 배경 이미지 레이어 추가

---

### [v1.7.2] DaylyWidgetCard 배경 이미지 지원 (Flutter) (2026-03-17)

- `resolvedImagePath` 파라미터 추가 (opacity 0.30 오버레이 + RadialGradient 가독성 보호)
- `lib/utils/dayly_image_utils.dart` 신규: `resolveWidgetBackgroundImagePath()` 공통 유틸
- `WidgetGridScreen._resolveAllImagePaths()` 일괄 resolve

---

### [v1.7.1] Android Medium/Large 위젯 "Can't load widget" 수정 (2026-03-17)

- 위젯 피커 프리뷰 전용 레이아웃 신규 생성 (`dayly_widget_preview_medium/large.xml`)
- stack item의 진행 바 `<View>` → `<ImageView>` 교체 (RemoteViews 제약 해결)

---

### [theme mode] 앱 테마 모드 변경 (2026-03-23)

- `lib/app.dart`: 테마 모드 로직 수정
- `pubspec.yaml`: 버전 업데이트

---

### [위젯 보안] iOS 위젯 보안 강화 (2026-03-22)

- `ios/DaylyWidget/DaylyWidget.swift`: 보안 관련 코드 개선 (94줄 변경)
- `TODOS.md`: 관련 항목 추가

---

## 📋 남은 작업 (우선순위 순)

| ID | 내용 | 우선순위 | 규모 | 의존성 |
|----|------|----------|------|--------|
| BIZ-5 | IAP 프리미엄 구매 플로우 | P1 | M | BIZ-1 (4주 데이터 후) |
| BIZ-6 | 프리미엄 공유 카드 프레임 (역바이럴) | P1 | M | BIZ-5 |
| TODO-T1 | 공유 화면 반복 이벤트 배지 표시 | P2 | S | BIZ-4 ✅ |
| TODO-T2 | 편집 화면에서 반복 타입 변경 지원 | P2 | S | BIZ-4 ✅ |
| P1 | Android Kotlin 유닛테스트 (Robolectric) | P1 | M | — |
| P2 | 위젯 진행 바 + isPast 로직 유닛테스트 | P2 | S | P1 셋업 ✅ |
| P2 | EventDetailScreen 실시간 변경 시 알림 재예약 | P2 | S | v1.7.5 ✅ |
| P3 | 테마 색상 중앙화 (Android DRY 위반 해소) | P3 | S | — |
| P3 | iOS App Group 오래된 배경 이미지 정리 | P3 | S | v1.8.0 ✅ |
| P3 | iOS Swift 위젯 유닛테스트 (XCTest) | P3 | S | — |
| TODO-T3 | DESIGN.md 생성 | P3 | S | — |
