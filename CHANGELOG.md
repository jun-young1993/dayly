# CHANGELOG

---

## 1.8.7+12 — 2026-03-31

### Fixed

- **아이콘 선택 버그 수정**: 이벤트 생성 시 선택한 아이콘이 리스트에서 항상 순서대로 표시되던 버그 수정.
  - `DaylyWidgetModel`에 `iconIndex` 필드 추가 — 생성 시 선택한 아이콘 인덱스를 저장.
  - `widget_grid_screen.dart` 리스트/그리드/상세 진입 모두 `model.iconIndex`를 우선 사용, 구버전 데이터는 `index % length` fallback 유지.
  - `_iconData` 배열 순서를 `_kIconOptions`와 일치하도록 수정 (`edit_note_outlined`가 index 2→7로 이동, `favorite_outline`이 정상 위치로).

---

## 1.8.6+11 — 2026-03-27

### Fixed

- **cold start 흰 화면 제거**: `main()`에서 `runApp()` 이전에 모든 초기화(`Firebase`, `Hive`, 알림 등)를 `await`하던 구조를 개선. `runApp()`을 즉시 호출하고 초기화를 `Future`로 전달, `FutureBuilder`로 완료 전까지 스플래시 화면을 표시하도록 변경.
- **스플래시 화면 추가** (`app.dart` `_SplashScreen`): "dayly" 로고 + 페이드인 애니메이션 + 미니 로딩 인디케이터. 초기화 완료 시 메인 화면으로 자동 전환.
- **딥링크 cold start 대응** (`widget_grid_screen.dart`): 위젯 로드 전 딥링크 수신 시 `_pendingDeepLink`에 보류, `_load()` 완료 후 처리. 스트림 구독을 항상 등록해 warm start 딥링크 누락 버그도 수정.

---

## 1.8.5+10 — 2026-03-26

### Fixed

- **Android 위젯 배경 이미지 미표시 버그 수정**:
  - `HomeWidgetService._resolveImageForWidget()`: Android에서 상대 경로(`"backgrounds/bg_xxx.jpg"`)를 그대로 전달하던 것을 `resolveWidgetBackgroundImagePath()`를 통해 절대 경로로 변환 후 전달하도록 수정. 기기/OEM에 따라 `context.filesDir`와 Flutter `getApplicationDocumentsDirectory()` 경로가 달라질 수 있는 문제 해소.
  - `DaylyWidgetRemoteViewsService.getViewAt()`: 배경 이미지 alpha를 65%(`setFloat "setAlpha" 0.65f`)로 설정하고 오버레이 투명도를 55%→27%(`Color.argb(70,0,0,0)`)로 축소하여 이미지가 실제로 보이도록 수정.
  - `_resolveImageForWidget` 주석 오탈자 수정 ("원본 경로를 그대로 반환" → "절대 경로로 변환 후 반환").
  - 단위 테스트 추가 (`test/utils/dayly_image_utils_test.dart`): `resolveWidgetBackgroundImagePath` — null 입력, 절대/상대 경로 × 파일 존재/없음 5가지 케이스 커버.

---

## 1.8.4+9 — 2026-03-26

### Fixed

- **Android 위젯 배경 이미지 없을 때 검정 화면 버그 수정**: 배경 이미지 파일이 삭제되거나 존재하지 않을 때 위젯이 검정으로 나오던 문제 해결.
  - `resolveImagePath`: Android `JSONObject.optString`이 JSON null을 `"null"` 문자열로 반환하는 버그 방어 처리 (`path == "null"` 조기 return 추가).
  - 이미지 없을 때(bitmap = null) 이전에 캐싱된 비트맵을 명시적으로 제거(`setImageViewBitmap(null)`) 후 뷰 숨김 처리.
  - 이미지 없는 경우 테마 배경 drawable을 재확인 적용하여 검정 화면 방지.
  - Medium/Large 위젯 레이아웃(`dayly_widget_stack_item_medium.xml`, `dayly_widget_stack_item_large.xml`)에 XML 기본 배경(`@drawable/dayly_widget_bg`) 추가 — Kotlin 동적 적용 실패 시 night 테마가 fallback으로 표시.

---

## 1.8.3+8 — 2026-03-25

### Added (TODO-T1, TODO-T2)

- **반복 이벤트 배지 (T1)**: 공유 카드에 `isRecurring=true`인 위젯 공유 시 "매년 반복" / "매월 반복" 배지 표시. RepaintBoundary 내부에 포함되어 공유 PNG에도 반영.
- **편집 화면 반복 타입 변경 (T2)**: `share_preview_screen_v2.dart` 편집 옵션에 "반복" 타일 추가. 클릭 시 모달로 없음 / 매년 / 매월 선택 가능. ko/ja/en 로켈리제이션.
- `RecurringSection` 위젯 분리 (`lib/widgets/recurring_section.dart`): `add_widget_bottom_sheet.dart`와 공유 화면 모두에서 재사용 가능한 public 위젯으로 추출.
- `DaylyRecurringTypeX.label(languageCode)` extension 추가 (`lib/utils/dayly_time.dart`): 반복 타입→표시 문자열 변환 순수 함수. `_recurringLabel()` 단순화에 활용.
- `DaylyAnalytics.logRecurringTypeChanged(type)` 추가: 반복 타입 변경 이벤트 측정.
- 유닛테스트 9개 추가 (`DaylyRecurringTypeX.label` — null/annual/monthly × ko/en/ja).

---

## 1.8.2+7 — 2026-03-22

### Added (BIZ-4)

- **반복 이벤트 (매년/매월)**: D-Day 위젯 생성 시 반복 주기 선택 가능. 날짜가 지나면 앱 열릴 때 자동으로 다음 주기로 갱신.
  - `DaylyRecurringType { annual, monthly }` enum 추가 (`lib/utils/dayly_time.dart`)
  - `DaylyWidgetModel`에 `isRecurring: bool`, `recurringType: DaylyRecurringType?` 필드 추가. 기존 위젯 JSON 하위 호환 (`isRecurring` 없으면 `false`로 폴백).
  - `advanceRecurringOnce()` — 윤년(Feb 29 → Feb 28), 단월(Jan 31 → Feb 28) 처리 포함.
  - `advanceIfPast()` — 수년치 gap도 커버 (최대 1200회 guard).
  - `advanceRecurringAll()` — 앱 시작 및 resume 시 일괄 진행. `anyChanged` 추적으로 불필요한 저장 방지.
  - `add_widget_bottom_sheet.dart` — SegmentedButton "없음 / 매년 / 매월" UI 추가. l10n.custom() ko/ja/en 로켈리제이션.
  - `widget_grid_screen._load()` 및 `app.didChangeAppLifecycleState(resumed)` 훅 연결.
- **Dart 유닛테스트 11개 추가** (`test/utils/dayly_time_test.dart`): annual/monthly 기본 케이스, 윤년 처리, 단월 클램프, 멀티 사이클 advance, 구버전 JSON 호환성.

---

## 1.8.1+6 — 2026-03-22

### Fixed

- **iOS 위젯 페이지 인디케이터 가시성 수정 (Medium / Large)**: 배경 이미지가 있을 때 `< 1 / 2 >` 페이지 인디케이터가 배경에 묻히는 문제 수정.
  - Medium 뷰: `theme.sub.opacity(0.5)` 중복 적용 버그 제거, `subColor.opacity(hasImage ? 0.9 : 0.5)` + shadow로 일원화.
  - Large 뷰: shadow 완전 누락이었던 문제 수정 — `shadow(color: .black.opacity(hasImage ? 0.6 : 0), radius: 2)` 추가.

### Added (BIZ-3)

- **공유 텍스트 플랫폼 분기**: `share_preview_screen_v2.dart` 공유 시 iOS는 App Store, Android는 Play Store 링크로 자동 분기.

### Added (BIZ-2 — flutter_ui_kit_google_mobile_ads 0.1.17)

- **App Open 광고 쿨다운 영속화**: `AppOpenAdManager._lastShownTime`을 `SharedPreferences`로 영속화.
  앱 재시작 후에도 24h 쿨다운이 유지된다 (`main.dart`에서 `cooldown = const Duration(hours: 24)` 설정).
- stale TODO 주석 2개 제거.

### Added (BIZ-1)

- **Firebase Analytics 이벤트 4종 추가** (`lib/utils/dayly_analytics.dart`):
  - `first_widget_created`: 첫 위젯 생성 시
  - `share_tapped`: 공유 버튼 탭 시
  - `home_widget_installed`: 홈 화면 위젯 탭으로 앱 실행 시
  - `premium_tapped`: 프리미엄 UI 탭 시 (BIZ-6 연동 예정)
- `Firebase.initializeApp()` try/catch 추가 — 네트워크 오류 시 앱 크래시 방지.

### Changed

- **TODOS.md 업데이트 (CEO+Eng Review 반영)**:
  - BIZ-2: 쿨다운 구현 명세를 `1줄 설정`에서 `flutter_ui_kit_google_mobile_ads` 패키지 SharedPreferences 영속화로 수정. Effort XS→S.
  - BIZ-4: `DaylyRecurringType`에 `monthly` 추가, 월말 처리 명세 + 테스트 케이스 3개 추가.
  - BIZ-5 신규: IAP 프리미엄 구매 플로우 (P1, M) — BIZ-1 4주 데이터 확보 후 진행.
  - BIZ-6 신규: 프리미엄 공유 카드 프레임 (P1, M) — BIZ-5 이후 진행.

---

## docs — 2026-03-20

### Added

- **BUSINESS.md CEO Review 2차 반영 (SCOPE EXPANSION)**:
  - 시장 우선순위 재편: 한국·일본 → **한국(1) → 미국(2) → 일본(3)**. 미국 2.8억 시장 독립 섹션 신설, 감성 카운트다운 공백 기회 명시.
  - 포지셔닝 재정의: "D-Day 앱"에서 **"날짜에 이름을 붙이는 앱"** 으로 카테고리 재정의. ASO 롱테일 전략 추가.
  - 프리미엄 가치 제안 정의: **역바이럴(Reverse Viral) 모델** — 프리미엄 공유 카드 프레임 + Premium 배지. 워터마크 제거 명시적 금지.
  - North Star Metric 추가: **위젯 설치수 (`home_widget_installed`)** 단일 핵심 지표 선정.
  - 플라이휠 파손 지점 명시: iOS 공유 → Play Store 링크 (TODO-BIZ-3 미구현) 경고 추가.
  - 버전 표기 정정: "앱 버전: 1.8.x" → CHANGELOG.md 단일 소스오브트루스 명시.
  - 일본 시장 상세 추가: iOS 70%·LINE 85%·Apple ¥ 티어·계절 이벤트 명시.
  - 액션 아이템 재정렬: 프리미엄 역바이럴 구현·시즌 테마 팩·미국 ASO P2 추가.
- **BUSINESS.md CEO Review 1차 반영**: 수익 전략 광고 우선으로 업데이트, 성장 플라이휠 다이어그램 추가, 액션 아이템 테이블 재정렬 (iOS 링크·Analytics·광고 쿨다운 P0 추가)
- **TODOS.md 비즈니스 TODO 4개 추가**: TODO-BIZ-1 (Firebase Analytics), TODO-BIZ-2 (App Open 쿨다운), TODO-BIZ-3 (iOS 공유 링크), TODO-BIZ-4 (기념일 반복 이벤트)
- **TODOS.md Eng Review 반영**: BIZ-2 명세 수정(패키지 cooldown API, Effort S→XS), BIZ-1에서 app_open 제거(Firebase 자동수집) + Firebase init 위치 명시, BIZ-4에 DaylyRecurringType enum + Leap day 처리 + 즉시 저장 + Kotlin/Swift 테스트 범위 추가

---

## 1.7.8 — 2026-03-19

### Fixed

- **[P0] Small 위젯 배경 이미지 수정**: `DaylySmallView`에서 절대 경로를 처리 못하는 `loadBgImage()`를 `loadWidgetBackgroundImage(path:)`로 교체. Small 위젯에서 배경 이미지가 전혀 표시되지 않던 버그 수정.
- **[Dead Code] Medium 위젯 Layer 1 제거**: `DaylyMediumView`의 ZStack에서 항상 nil을 반환하던 `loadBgImage()` 기반 Layer 1 블록 제거. Layer 2(`loadWidgetBackgroundImage()`)가 정상 동작하므로 기능 변화 없음.

### Removed

- **`loadBgImage()` 함수 제거**: 절대 경로 미지원으로 항상 nil을 반환하던 불완전한 헬퍼 함수 삭제. `loadWidgetBackgroundImage(path:)`가 절대/상대 경로 모두 처리하므로 대체 불필요.
- **중복 App Group 복사 인프라 제거**: `EventDetailScreen._selectImageFromGallery()`의 iOS MethodChannel 복사 블록 및 `AppDelegate.swift`의 `juny.dayly/app_group` 채널 핸들러 삭제. `HomeWidgetService._resolveImageForWidget()`이 `updateAll()` 호출 시마다 App Group 복사를 단독 처리하므로 중복 불필요.

---

## 1.7.7 — 2026-03-19

### Fixed

- **iOS App Group 채널 등록 타이밍 수정**: `AppDelegate`의 MethodChannel(`juny.dayly/app_group`) 등록 위치를 `didFinishLaunchingWithOptions`에서 `didInitializeImplicitFlutterEngine`으로 이동. Flutter 엔진 초기화 전에 `rootViewController`가 nil일 경우 채널이 무음 실패하던 문제 해결.
- **App Group 복사 실패 로그 추가**: `_selectImageFromGallery()`의 `catch (_) {}` → `catch (e) { debugPrint('[AppGroup] image copy failed: $e'); }`. 채널 미등록, 디스크 풀 등 실패 시 원인을 확인할 수 없던 문제 개선.
- **배경 이미지 크기 제한 추가**: `pickImage`에 `maxWidth: 1024, maxHeight: 1024` 추가. 4K 이미지가 App Group에 그대로 저장되어 위젯 렌더 지연 및 스토리지 낭비를 유발하던 문제 예방.

---

## 1.7.6 — 2026-03-19

### Added

- **iOS 홈화면 위젯 배경 이미지 지원**:
  - `AppDelegate.swift`: MethodChannel `"juny.dayly/app_group"` 추가. Flutter 앱에서 App Group 컨테이너 경로(`group.juny.dayly`) 조회 가능.
  - `EventDetailScreen._selectImageFromGallery()`: iOS에서 이미지 선택 시 Documents 복사 외에 App Group 컨테이너(`group.juny.dayly/backgrounds/`)에도 동일 파일 복사. 실패 시 무시(위젯은 배경 없이 표시).
  - `DaylyWidget.swift`: `DaylyWidgetEntry`에 `backgroundImagePath: String?` 필드 추가. `entryFromItem`에서 JSON의 `backgroundImagePath` 키를 읽어 전달.
  - `DaylySmallView` / `DaylyMediumView`: ZStack 최하위에 배경 이미지(opacity 0.30) + 텍스트 대비 오버레이(black 0.15) 레이어 추가. `.clipped()` 추가.

### Fixed

- **iOS 위젯 `< 1/N >` 인디케이터 가시성**: 배경 이미지가 있을 때 페이지 인디케이터에 `.shadow(radius: 2)` 적용하여 이미지 위에서도 선명하게 표시.

---

## 1.7.5 — 2026-03-19

### Fixed

- **홈화면 위젯 즉시 갱신 버그 수정**: `EventDetailScreen`에서 마일스톤 토글, 노트 편집, 테마/문구 변경, 배경 이미지 변경·제거 후 뒤로가기 대신 홈 버튼을 눌러도 Android 홈화면 위젯이 즉시 갱신되지 않던 문제 수정.
  - `EventDetailScreen`에 `onWidgetChanged` 콜백 파라미터 추가. 각 변경 액션 후 즉시 호출.
  - `WidgetsBindingObserver` 믹스인 추가. 앱이 백그라운드로 전환(`paused`)될 때도 콜백 자동 호출.
  - `WidgetGridScreen._openDetail()`에서 콜백 주입: `setState` + `_persist()` 즉시 실행 → Android 위젯 갱신.
## 1.8.1 — 2026-03-18

### Fixed

- **iOS 위젯 빌드 에러 수정**: `FileManager.containerURL` argument label 오타 수정.
  `forSecurityApplicationGroup:` → `forSecurityApplicationGroupIdentifier:`

---

## 1.8.0 — 2026-03-17

### Added

- **iOS Large(4×4) 홈화면 위젯 추가**: `DaylyLargeView` 신규 생성. 카운트다운 44pt, 문구 16pt (3줄), 넉넉한 여백. `supportedFamilies`에 `.systemLarge` 추가.
- **iOS 위젯 시간 기반 진행 바 (Medium/Large)**: `createdAt → targetDate` 기간 대비 경과 비율을 시각적 진행 바로 표시. Android의 페이지 위치 방식 대신 D-Day 앱에 더 의미있는 시간 기반 방식 채택. `DaylyProgressBar` 공통 컴포넌트로 추출.
- **iOS 위젯 배경 이미지 지원 (Medium/Large)**: `loadWidgetBackgroundImage()` 헬퍼 — App Group 컨테이너에서 이미지 로드, ImageIO 기반 400×400 다운샘플링 (WidgetKit 메모리 제한 대응). `Color.black.opacity(0.55)` 오버레이로 텍스트 가독성 보호.
- **배경 이미지 시 자동 흰색 텍스트**: 배경 이미지가 있을 때 테마 무관하게 `text=white`, `sub=white(70%)` 자동 전환. paper/fog 등 밝은 테마에서도 가독성 보장.
- **iOS 위젯 테마 진행 바 색상**: `Color.progressColors(for:)` — Android `DaylyWidgetTheme.kt`와 동일한 5개 테마별 fill/track 색상.
- **`HomeWidgetData.createdAt` 필드 추가**: iOS 네이티브에서 시간 기반 진행률 실시간 계산용. `toJson()`/`fromJson()` 직렬화 반영.
- **Flutter iOS 이미지 공유 파이프라인**: `_resolveImageForWidget()` — iOS에서 배경 이미지를 App Group 공유 컨테이너(`group.juny.dayly`)로 복사. `path_provider_foundation` 패키지의 `getContainerPath()` 사용.
- **공통 뷰 컴포넌트 추출**: `DaylyProgressBar`, `DaylyDots`, `DaylyTapZones`를 재사용 가능한 SwiftUI 컴포넌트로 분리. Small/Medium/Large 뷰에서 공유.
- **os.Logger 도입**: 위젯 Extension에 구조화된 로깅 추가 (`juny.dayly.widget` subsystem). 이미지 로드 실패 시 경고 로그.

---

## 1.7.4 — 2026-03-17

### Fixed

- **Android 홈 위젯 이미지 로딩 로그 추가**: `resolveImagePath()` / `loadScaledBitmap()` catch 블록에 `Log.w` / `Log.e` 추가. 파일 미존재, I/O 오류, OOM 등 이미지 로딩 실패 시 Logcat에 흔적 없이 무음 처리되던 문제 개선.
- **TODOS.md**: `P2 — Android 홈 위젯에 배경 이미지 표시` 완료 항목 삭제.

---

## 1.7.3 — 2026-03-17

### Added

- **Android 홈화면 위젯 배경 이미지 지원 (Medium/Large)**:
  - `HomeWidgetData`에 `backgroundImagePath` 필드 추가 및 `toJson()`/`fromJson()` 직렬화 반영.
  - `HomeWidgetService._toHomeWidgetData()`에서 `model.backgroundImagePath` 전달.
  - Kotlin `WidgetDisplayData`에 `backgroundImagePath` 필드 추가 및 `fromJson()` 파싱.
  - `DaylyWidgetRemoteViewsService`에 `resolveImagePath()` / `loadScaledBitmap()` 헬퍼 추가. 400px 이내로 다운샘플링하여 메모리 절약.
  - `getViewAt()`에서 Medium/Large 위젯에 한해 Bitmap을 `widget_bg_image`에 적용하고 `widget_bg_overlay`(ARGB 140 어두운 오버레이)로 텍스트 가독성 보호.
  - `dayly_widget_stack_item_medium.xml` / `dayly_widget_stack_item_large.xml`: 루트를 `FrameLayout`으로 변경, `widget_bg_image` · `widget_bg_overlay` ImageView 추가 (기본 `GONE`).
  - Small 위젯은 공간 협소로 이미지 미지원(변경 없음).

---

## 1.7.2 — 2026-03-17

### Added

- **DaylyWidgetCard 배경 이미지 지원**: `resolvedImagePath` 파라미터 추가. 이미지를 opacity 0.30으로 카드 위에 오버레이, 중앙 RadialGradient 오버레이로 D-Day 숫자 가독성 보호.
- **_DysmorphicCard 배경 이미지 지원**: 그리드 화면 카드에 opacity 0.20 이미지 표시. BackdropFilter blur 밖에 배치해 자연스럽게 스며드는 효과.
- **`lib/utils/dayly_image_utils.dart` 신규**: 경로 해석 공통 유틸 `resolveWidgetBackgroundImagePath()`. 절대/상대 경로 처리 + 파일 존재 확인 + 예외 시 null 반환.
- **WidgetGridScreen 이미지 일괄 resolve**: 로드/편집 후 `_resolveAllImagePaths()` 호출, `Map<widgetId, absPath>`로 카드에 전달.
- **isMicro 모드**: 40px 이하 타일에서 이미지 레이어 미표시.
- **TODOS.md**: Android 홈 위젯 배경 이미지 표시 P2 태스크 추가.

---

## 1.7.1 — 2026-03-17

### Fixed

- **Medium/Large 위젯 "Can't load widget" / "Couldn't add widget" 수정**:
  - 위젯 피커 프리뷰 전용 레이아웃 `dayly_widget_preview_medium.xml` / `dayly_widget_preview_large.xml` 신규 생성 (RelativeLayout 루트, `layout_weight` 없음, 정적 샘플 콘텐츠). 일부 런처 피커가 `layout_weight` 기반 레이아웃을 inflate하지 못하는 문제 해결.
  - `dayly_widget_info_medium.xml` / `dayly_widget_info_large.xml`의 `previewLayout`을 새 레이아웃으로 교체.
  - `dayly_widget_stack_item_medium.xml` / `dayly_widget_stack_item_large.xml`의 진행 바 `<View>` → `<ImageView>`로 교체. RemoteViews 공식 지원 뷰 목록에 순수 `<View>`가 없어 일부 Android 버전에서 inflate 실패하던 문제 해결.
  - Large 프리뷰 `preview_date_label`의 `layout_centerVertical` → `layout_alignParentTop`으로 수정 (콘텐츠 하단 집중 방지).
  - Medium/Large stack item ImageView에 `contentDescription=""` 추가 (Android Lint 접근성 경고 억제).

---

## 1.7.0 — 2026-03-17

### Refactored
- **테마 색상 중앙화**: `DaylyWidgetTheme.kt` 신설 — `WidgetThemeColors` + `themeColors()` 단일 진실 공급원. `DaylyWidgetConfigActivity.themeBarColor()` DRY 위반 제거.

### Added
- **fillFraction() 추출**: `DaylyWidgetRemoteViewsService.kt` 내 인라인 계산 → `internal fun fillFraction()` 추출. ASCII 다이어그램 주석 포함.
- **BuildCountdownTextTest.kt**: `buildCountdownText()` 14개 케이스 JVM 단위 테스트 추가.
- **WidgetProgressTest.kt**: `fillFraction()` 6개 케이스 (경계값 포함) JVM 단위 테스트 추가.

### Removed
- TODOS.md P0 항목 삭제 (AndroidManifest에서 ConfigActivity 제거로 이미 수정됨)

---

## 1.6.0 — 2026-03-16

### Fixed — Android 위젯 디자인 완성도 (SCOPE EXPANSION)

- **[CRITICAL] ProgressBar 테마 색상 고정 버그 수정**: Medium/Large 위젯의 ProgressBar가 밝은 테마(paper/fog/lavender/blush)에서도 항상 night 테마 파란색(`#4060A0`)으로 표시되던 문제 수정. RemoteViews의 tint 제약으로 인해 ProgressBar를 `FrameLayout + View` 2-레이어 방식으로 교체. 진행 너비는 `setFloat("setPivotX", 0f)` + `setFloat("setScaleX", fillFraction)` 으로 구현 (`setViewPadding`은 View 배경에 무효 — draw 단계 canvas 변환이 필요).
- **Small 위젯 날짜 라벨 색상 미적용 수정**: Small 크기에서 `widget_date_label` 색상이 항상 XML 기본값(`#7090B0`, night 색상)으로 고정되던 문제 수정. 모든 크기에서 테마 색상(`theme.subColor`) 적용.

### Added

- **지난 이벤트 반투명 처리**: `isPast=true`인 D-Day 카드 전체에 alpha 0.5 적용. 종료된 이벤트를 진행 중인 이벤트와 시각적으로 구분.
- **EmptyView CTA 개선**: D-Day가 없을 때 표시되는 빈 상태 뷰 개선. "dayly" 텍스트만 있던 것을 크기별 안내 문구 추가(Medium: "D-Day를 추가해보세요 →", Large: "앱에서 첫 D-Day를 추가해보세요 →"). EmptyView 탭 시 앱 실행 PendingIntent 추가.
- **ConfigActivity UI 재설계**: 홈화면에서 위젯 추가 시 실행되는 D-Day 선택 화면을 기본 Android 버튼 목록에서 감성 카드 스타일로 재설계. Night 테마 배경 + 테마별 색상 바 + 반투명 카드 레이아웃 적용.
- **배경 Drawable Highlight 레이어 추가**: 5개 테마 배경 drawable에 상단 반투명 흰색 → 투명 그라데이션 레이어 추가(night 6%, fog/lavender 11%, paper/blush 10-12%). Flutter 앱 카드의 Highlight 효과와 시각적 일관성 확보.

### Improved

- **`WidgetThemeColors` 확장**: `progressFillColor`, `progressTrackColor` 필드 추가. 5개 테마 각각에 어울리는 진행 바 색상 정의.

---

## 1.5.0 — 2026-03-16

### Fixed — Android 위젯 AlarmManager 아키텍처 강화

- **[CRITICAL] Medium/Large 위젯 자정 업데이트 미작동 수정**: `midnightPendingIntent()`가 `DaylyAppWidget::class.java`를 타겟으로 하는 explicit broadcast여서 Medium/Large는 자정 알람을 수신하지 못하던 문제 해결. `WidgetUpdateManager.onMidnightReceived()`가 Small/Medium/Large 세 Provider를 모두 갱신하도록 변경.
- **[CRITICAL] Small 위젯 제거 시 Medium/Large 자정 업데이트 영구 중단 수정**: `DaylyAppWidget.onDisabled()` → `cancelMidnightUpdate()` 직접 호출로 Small만 제거해도 알람이 취소되던 문제 해결. `WidgetUpdateManager.cancelIfNone()`이 3개 Provider를 모두 확인 후 모두 0개일 때만 알람 취소.
- **AlarmManager 중복 예약 방지**: `WidgetUpdateManager.scheduleIfNeeded()`가 `FLAG_NO_CREATE`로 기존 알람 존재 여부를 확인 후 중복 예약을 방지.

### Added

- **`WidgetUpdateManager` 도입**: Android 위젯 AlarmManager 생명주기를 단일 Kotlin `object`로 중앙 관리. Small/Medium/Large Provider는 생명주기 이벤트를 WidgetUpdateManager에 위임.
- **타임존 변경 즉시 반영**: `ACTION_TIMEZONE_CHANGED` BroadcastReceiver 추가. 기기 타임존 변경 시 위젯 D-Day가 즉시 재계산됨.
- **카운트다운 텍스트 다국어 지원 (ko/ja/en)**: `buildCountdownText()`에 `lang` 파라미터 추가. 앱 언어가 한국어일 때 "23일 남음", 일본어일 때 "あと23日" 표시. Flutter 측에서 `languageCode`를 JSON에 포함하여 전달.
- **핵심 경로 로깅 추가**: `WidgetUpdateManager`에 `Log.d/e`로 알람 예약/취소·전체 갱신·예외 상황 기록. 버그 신고 시 logcat으로 원인 추적 가능.
- **TODOS.md 생성**: Kotlin 위젯 유닛테스트 항목 P1으로 등록.

### Improved

- **`forceMedium` 레거시 파라미터 제거**: `updateWidget(forceMedium: Boolean?, forceSize: WidgetSize?)`에서 사용되지 않는 `forceMedium`을 제거하여 API 명확화.
- **Medium/Large Provider 코드 단순화**: `onReceive()`의 dead code(`ACTION_MIDNIGHT_UPDATE` 처리 블록) 제거. AlarmManager 생명주기 override(`onEnabled`/`onDisabled`)도 부모 위임으로 정리.

---

## 1.4.2 — 2026-03-13

### Fixed — 배너 광고 블랙 스크린 수정

- **`app.dart`**: `BannerAdWidget` 비활성화 — 에뮬레이터에서 AdMob PlatformView(SurfaceProducer backend)가 GPU 렌더링 불가 시 해당 영역이 검은 화면으로 표시되는 문제 수정. 실기기 검증 후 재활성화 예정.

---

## 1.4.1 — 2026-03-13

### Fixed — App Open 광고 블랙 스크린 수정

- **`main.dart`**: `AppOpenAdManager.configure()` / `loadAd()` 비활성화 — `AppLifecycleState.resumed` 마다 전면 광고가 표시되어 에뮬레이터(GPU 렌더링 불가 환경)에서 검은 화면이 고착되는 문제 수정. 쿨다운 로직 구현 후 재활성화 예정.

---

## 1.4.0 — 2026-03-13

### Fixed — 언어 혼재 해소 (한국어/영어 l10n.custom 통일)

- **`add_widget_bottom_sheet.dart`**: `flutter_ui_kit_l10n` import 추가 후 모든 하드코딩 영어 문자열 (`CREATE NEW MOMENT`, `Name your moment`, hint 텍스트, `Date Selection`, `Icon & Color`, `SAVE MOMENT`)을 `l10n.custom()`으로 교체 — ko/ja/en 3개 언어 지원
- **`share_preview_screen_v2.dart`**: 하드코딩 영어·한국어 문자열 전체 교체 — `EDIT MOMENT`, `Preview`, `Edit Options`, `Sentence Editing`, `Date`, `Theme`, `Expression Style`, `Divider`, `Premium`, `SHARE MOMENT`, 공유 실패 SnackBar, 문구 편집 hint·설명·`적용` 버튼, `_countdownModeLabel()` 함수 signature 변경 (`BuildContext` 수신)
- **`widget_grid_screen.dart`**: 이벤트 수 라벨 (`N events`) → `l10n.custom()`으로 교체
- **`notification_scheduler.dart`**: `scheduleAll()` 및 `_buildBody()`에 `languageCode` 파라미터 추가 — 알림 본문이 선택된 언어로 발송 (ko/ja/en)
- **`notification_repository.dart`**: `schedule()` 메서드에 `languageCode` 파라미터 추가, `_languageCode` 필드로 마지막 언어 기억 → `syncOnAppStart()` 재예약 시에도 동일 언어 사용

---

## 1.3.9 — 2026-03-13

### Fixed — 기본 위젯 최초 1회 persist 처리

- 앱 최초 실행 시 저장 데이터가 없을 때 `DaylyWidgetModel.defaults()`로 생성된 기본 위젯을 즉시 `saveDaylyWidgets()`로 저장 — 이전에는 메모리에만 존재해 앱 재시작마다 새 기본 위젯이 생성될 수 있었음

---

## 1.3.8 — 2026-03-13

### Fixed — 태블릿 Setting 아이콘 사이즈 대응

- `AppBreakpoints.isTablet()` 호출 문법 수정 및 태블릿(≥768dp) 감지 시 Setting 기어 아이콘 사이즈 24→32로 확대
- 태블릿 그리드 전환 기준을 600dp→768dp(`AppBreakpoints.isTablet`)로 변경 — 600~768dp 기기에서 2열 그리드 적용 시 카드 내 텍스트 Column이 ~23px로 좁아져 RenderFlex 오버플로우 발생하던 문제 수정
- `ListenableBuilder`를 `ScreenUtilInit` 안으로 이동 — 테마 변경 시 `BannerAdWidget`(iOS UiKitView)이 dispose→recreate되면서 `PlatformException(recreating_view)` 크래시 발생하던 문제 수정

---

## 1.3.7 — 2026-03-12

### Added — 이벤트 상세 화면 배경 사진 기능

- **사용자 배경 사진 지원**: 상세 화면에서 갤러리 사진을 배경으로 설정 가능 (`image_picker` 패키지 추가)
- **가독성 오버레이**: 사진 배경 위에 다크 그라디언트 오버레이(상단 73% → 중단 40% → 하단 80%) 적용 — 글래스카드 텍스트 가독성 확보
- **사진 관리 UI**: 상단 바에 배경 사진 버튼 추가 — 없을 때 갤러리 열기, 있을 때 변경/제거 바텀시트 표시
- **모델 저장**: `DaylyWidgetModel.backgroundImagePath` 필드 추가 및 JSON 직렬화 (null-safe Sentinel 패턴으로 `copyWith` null 설정 지원)
- **배경 전환**: 사진 배경 사용 시 GlowOrb 숨김, 기본 배경 복귀 시 재표시

---

## 1.3.6 — 2026-03-12

### Added — Large(4×4) 홈화면 위젯 추가

- **새 크기 위젯 추가**: `DaylyAppWidgetLarge` Provider 클래스, `dayly_widget_large.xml` 컨테이너, `dayly_widget_stack_item_large.xml` 카드 아이템, `dayly_widget_info_large.xml` 메타정보 추가
- **위젯 크기 enum 도입**: `WidgetSize(SMALL/MEDIUM/LARGE)` enum으로 크기 분기 통일 — `forceMedium: Boolean` 방식에서 `forceSize: WidgetSize` 방식으로 개선
- **Large 카드 디자인**: 카운트다운 56sp, 문구 16sp (최대 3줄), 구분점 5dp — 4×4 공간을 활용한 넉넉한 레이아웃
- **AndroidManifest에 Large Provider 등록**

---

## 1.3.5 — 2026-03-12

### Fixed — Medium 위젯 "Couldn't add widget" 에러 수정

- **RemoteViews 미지원 View 태그 교체**: `dayly_widget_stack_item_medium.xml`의 구분점 dot 3개(`View` 태그)를 `ImageView`로 교체 — `View` 기본 클래스는 RemoteViews에서 크래시 유발, `ImageView`로 변경하여 호환성 확보

---

## 1.3.4 — 2026-03-12

### Fixed — Android 위젯 크기 및 텍스트 수정

- **Medium 위젯 별도 등록**: `DaylyAppWidgetMedium` 클래스 추가 및 manifest에 별도 receiver로 등록 — 위젯 피커에서 Medium(4×2) 위젯을 직접 추가 가능, 크기 조정 시 "Couldn't add widget" 에러 해소
- **Small 위젯 글씨 크기 축소**: 카운트다운 텍스트 28sp→22sp, 감성 문구 11sp→9sp — 작은 사이즈에서 텍스트가 `...`으로 잘리던 문제 개선

---

## 1.3.3 — 2026-03-11

### Changed — Android 위젯 디자인 개선 (iOS 수준으로 맞춤)

- **테마별 배경 적용**: paper/fog/lavender/blush 테마에 맞는 배경 drawable 4종 추가 — 기존 night 고정에서 실제 설정 테마가 위젯에 반영됨
- **페이지 인디케이터 추가**: 복수 위젯 시 Small은 `1/4`, Medium은 `< 1/4 >` 형식으로 현재 위치 표시
- **dayly 워터마크 추가**: 우측 하단에 `dayly` 브랜드 텍스트 표시 (테마별 색상 자동 적용)
- **Medium 레이아웃 좌측 정렬**: 문구·카운트다운을 중앙→좌측 정렬로 변경 (iOS와 동일)
- **하단 레이아웃 구조 개선**: Medium 위젯에 페이지 인디케이터와 워터마크가 항상 하단에 고정되는 구조로 변경
- **테마별 텍스트/구분점 색상 동적 적용**: 밝은 테마(paper/fog/lavender/blush)에서는 어두운 텍스트, 어두운 테마(night)에서는 밝은 텍스트 자동 전환

---

## 1.3.2 — 2026-03-10

### Fixed — Android 위젯 버그 수정

- **"Couldn't add widget" 에러**: `DaylyWidgetConfigActivity`가 `APPWIDGET_CONFIGURE` intent-filter로 manifest에 등록되어 있어 Samsung One UI 등 일부 런처가 위젯 리사이즈 시 해당 Activity를 자동 실행 → `RESULT_CANCELED` 반환 → 위젯 추가 실패하던 문제 수정. manifest에서 레거시 Activity 등록 제거.
- **위젯 콘텐츠가 경계 밖으로 벗어나는 문제**: StackView의 peek 효과로 인접 카드가 위젯 경계 밖으로 노출되던 문제 수정 — 컨테이너 FrameLayout에 `padding="4dp"` 및 `clipChildren/clipToPadding="true"` 추가
- **D-Day 당일 표시 불일치**: `dMinus` 모드에서 Dart는 "D-0", Kotlin 위젯은 "D-Day"를 표시하던 문제 수정 — Dart `buildCountdownPhrase`에서 `dayDiff == 0`일 때 "D-Day" 반환하도록 통일
- **Android 12+ 자정 업데이트 실패**: `SCHEDULE_EXACT_ALARM` 권한이 없을 때 `setExactAndAllowWhileIdle()` 호출이 silently fail되던 문제 수정 — `canScheduleExactAlarms()` 체크 후 권한 없으면 `setWindow()` (±5분) fallback으로 자정 업데이트 보장

---

## 1.3.1 — 2026-03-09

### Fixed — 설정 화면 테마/언어/브랜드 변경이 즉시 반영되지 않는 문제

- `DaylyApp`이 `DsThemeController`를 구독하지 않아 `notifyListeners()` 호출 시 `MaterialApp`이 rebuild되지 않던 버그 수정
- `ListenableBuilder`로 `ScreenUtilInit`을 감싸 컨트롤러 변경 시 즉시 반영되도록 수정

---

## 1.3.0 — 2026-03-08

### Added — 이벤트 상세 화면 개선

- **D-Day 진행률(Progress) 표시**: Hero Card에 createdAt ~ targetDate 기간 대비 경과 비율 Progress Bar + 퍼센트 표시
- **`DaylyWidgetModel.createdAt` 필드 추가**: 이벤트 생성 시점을 저장하여 정확한 진행률 계산 (기존 데이터는 `DateTime.now()` fallback으로 마이그레이션)
- **마일스톤 CRUD**: 상세 화면에서 마일스톤 추가(+ Add milestone 버튼 + 다이얼로그) 및 삭제(x 버튼) 가능
- **SHARE 버튼**: EDIT EVENT 옆에 SHARE 버튼 추가 — SharePreviewScreenV2로 이동하여 공유 카드 생성/공유
- 마일스톤이 비어있을 때도 MILESTONES 카드 표시 (추가 유도)

---

## 1.2.4 — 2026-03-07

### Fixed — iOS 위젯 클릭 시 앱 크래시

- `pubspec.yaml`: `firebase_auth`, `firebase_core`, `firebase_ui_auth`, `firebase_ui_oauth_google` 의존성 제거
- `lib/firebase_options.dart` 삭제
- `main.dart`: Firebase 관련 import/코드 전부 제거
- iOS pod install로 Firebase 네이티브 라이브러리 제거 — 미초기화된 `FLTFirebaseAuthPlugin`이 위젯 `dayly://` URL 수신 시 `Auth.auth()`를 호출해 `EXC_BREAKPOINT` 크래시 발생하던 문제 근본 해결

---

## 1.2.3 — 2026-03-07

### Fixed — iOS 홈 위젯 D-Day 날짜 계산 오류

- `DaylyWidget.swift`: `entryFromItem()`이 저장된 `countdownText`를 그대로 사용해 앱을 마지막으로 연 시점 기준으로 고정되던 문제 수정
- `buildCountdownText(targetDateIso:countdownMode:)` 함수를 추가하여 위젯 렌더 시점에 `targetDate`와 `countdownMode`로 D-Day를 실시간 재계산 (Android와 동일한 방식)

---

## 1.2.2 — 2026-03-07

### Fixed — DST 경계 알림 날짜 계산 오류

- `notification_scheduler.dart`: `model.targetDate.add(Duration(days: daysOffset))` 대신 `tz.TZDateTime` 생성자에서 날짜 단위로 직접 더하도록 수정 — DST 전환일에 Duration 기반 연산이 N×24h를 더해 알림 날짜가 하루 밀리는 오류 수정

---

## 1.2.1 — 2026-03-06

### Fixed — iOS 위젯이 위젯 추가 메뉴에 표시되지 않는 문제

- Xcode 프로젝트에 `DaylyWidgetExtension` 타겟 등록 (기존에는 소스 파일만 존재하고 타겟 미등록)
- Runner 및 DaylyWidget에 App Group entitlements 파일 추가 (`group.juny.dayly`)
- Runner 타겟에 `CODE_SIGN_ENTITLEMENTS` 및 `Embed App Extensions` 빌드 페이즈 추가
- DaylyWidget.swift의 `.frame(width:maxHeight:)` 잘못된 SwiftUI modifier 수정
- 위젯 탭으로 앱 실행 시 크래시 수정: `AppDelegate`에서 Flutter 엔진 시작 전 `FirebaseApp.configure()` 호출 (딥링크 수신 시 `Auth.auth()` 미초기화 크래시 방지)

### Improved — iOS 위젯 UX 개선

- 위젯 탭 영역을 **3분할 투명 탭 존**으로 변경 — 좌(이전) / 중앙(앱 열기) / 우(다음), 위젯 전체 높이 활용 (기존 10~12pt 아이콘 → 위젯 면적의 1/3씩)
- 이벤트 2개 이상일 때 중앙 영역 탭으로 앱 딥링크 열기 가능 (`Link` + `dayly://detail/{id}`)
- 카운트다운 텍스트 `minimumScaleFactor` 0.6/0.5 → 0.3 으로 변경 — "22 days left" 등 긴 텍스트가 "..." 없이 전체 표시
- Medium 위젯 하단에 `< 1/3 >` 형태의 시각적 네비게이션 힌트 표시

### iOS 설정 변경 상세

| 파일 | 변경 내용 |
|------|-----------|
| `ios/Runner.xcodeproj/project.pbxproj` | `DaylyWidgetExtension` 네이티브 타겟 추가 (product type: `app-extension`, bundle ID: `juny.dayly.DaylyWidget`, deployment target: iOS 17.0). Runner 타겟에 `Embed App Extensions` 빌드 페이즈 추가 및 위젯 의존성 등록 |
| `ios/Runner/Runner.entitlements` | 신규 생성 — `com.apple.security.application-groups` → `group.juny.dayly` |
| `ios/DaylyWidget/DaylyWidget.entitlements` | 신규 생성 — 동일 App Group 설정 |
| `ios/DaylyWidget/Info.plist` | `CFBundleShortVersionString` → `$(MARKETING_VERSION)`, `CFBundleVersion` → `$(CURRENT_PROJECT_VERSION)` (Flutter 변수 → Xcode 표준 변수로 교체) |
| `ios/DaylyWidget/DaylyWidget.swift` | `.frame(width:24, maxHeight:.infinity)` → `.frame(minWidth:24, maxWidth:24, maxHeight:.infinity)` (유효한 SwiftUI frame overload로 수정) |
| `ios/Runner/AppDelegate.swift` | `import FirebaseCore` 추가, `didFinishLaunchingWithOptions`에서 `FirebaseApp.configure()` 선행 호출 |

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
