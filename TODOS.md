# TODOS

---

## TODO-BIZ-3 — iOS 공유 텍스트 App Store 링크 추가 (P0, XS)

**What:** `share_preview_screen_v2.dart:73`의 `shareText`에 OS별 링크 분기 추가

**Why:** iOS 유저가 공유받으면 Play Store로 이동해 설치 불가. 바이럴 공유의 iOS 전환이 완전히 막혀 있는 상태.

**Context:**
```dart
// 현재
'dayly - https://play.google.com/store/apps/details?id=juny.dayly'

// 변경
Platform.isIOS
  ? 'dayly - https://apps.apple.com/app/id6760478559'
  : 'dayly - https://play.google.com/store/apps/details?id=juny.dayly'
```
`dart:io`의 `Platform.isIOS` 사용. `import 'dart:io';` 추가 필요.

**Effort:** XS (~30분) | **Priority:** P0
**Depends on:** 없음

---

## TODO-BIZ-1 — Firebase Analytics 추가 (P0, S)

**What:** `firebase_analytics` 패키지 추가 + 핵심 이벤트 4개 심기
- `first_widget_created`, `share_tapped`, `home_widget_installed`, `premium_tapped`
- ~~`app_open`~~ 제외 — Firebase가 자동 수집하므로 직접 로그하면 이중 카운팅 발생

**Why:** 현재 유저 행동 데이터 전무. 광고 수익 검증·IAP 가격 설정·리텐션 개선 포인트 파악 모두 불가능한 상태.

**Context:**
`pubspec.yaml`에 `firebase_analytics` 추가 (`firebase_core`는 이미 있음, `firebase_auth` 제외).
v1.2.4에서 auth 크래시로 Firebase 전체 제거했으나 analytics는 별도이므로 안전.

`main.dart`에서 `Firebase.initializeApp()`을 **`runApp()` 전에 `await`로 복원**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[main] Firebase init failed: $e');
    // analytics 없이 앱 계속 실행
  }
  runApp(...);
}
```
`firebase_core`는 로컬 `google-services.json` 파싱이므로 네트워크 없이 즉시 완료 — 앱 시작 지연 없음.

이벤트는 `lib/utils/dayly_analytics.dart`로 중앙화. **`unawaited`는 유틸 내부에서 처리**:
```dart
class DaylyAnalytics {
  static const _kFirstWidgetCreated = 'first_widget_created';
  // ...
  static void logShareTapped() =>
      unawaited(FirebaseAnalytics.instance.logEvent(name: _kShareTapped));
}
// 호출 지점: DaylyAnalytics.logShareTapped(); // await 불필요
```

**Effort:** S | **Priority:** P0
**Depends on:** 없음

---

## TODO-BIZ-2 — App Open 광고 쿨다운 구현 (P0, XS)

**What:** `AppOpenAdManager.cooldown`을 24시간으로 설정 → 광고 재활성화

**Why:** App Open 광고가 쿨다운 없이 모든 `AppLifecycleState.resumed`에서 노출되어 UX 훼손. 쿨다운 설정만으로 즉시 수익 발생 가능.

**Context:**
`flutter_ui_kit_google_mobile_ads ^0.1.16` 패키지에 `cooldown` public 필드가 이미 있음.
패키지 내부에서 `_lastShownTime`으로 쿨다운을 관리하므로 `SharedPreferences` 직접 구현 불필요.

`main.dart`에 1줄 추가 (`configure()` 호출 전):
```dart
AppOpenAdManager.instance.cooldown = const Duration(hours: 24);
AppOpenAdManager.instance.configure(
  androidId: 'ca-app-pub-4656262305566191/4017810905',
  iosId: 'ca-app-pub-4656262305566191/9437357221',
);
AppOpenAdManager.instance.loadAd();
```

아울러 stale 주석 제거:
```dart
// 제거: "TODO: flutter_ui_kit_google_mobile_ads에 쿨다운(1h) 추가 후 재활성화."
// 패키지에 이미 구현됨.
```

**Effort:** XS (~15분) | **Priority:** P0
**Depends on:** TODO-BIZ-1 (Firebase Analytics — 광고 노출 이벤트 추적)

---

## TODO-BIZ-4 — 기념일 자동 반복 이벤트 (P1, M)

**What:** D-Day 생성 시 "매년 반복" 옵션 추가. D-Day 지나면 자동으로 다음 해 같은 날로 갱신.

**Why:** D-Day 지나면 앱 사용 이유가 없어지는 구조적 리텐션 문제 해소. 커플 기념일·생일·입사일 등 반복 이벤트에 필수 기능.

**Context:**
1. `DaylyWidgetModel`에 필드 추가:
   - `isRecurring: bool` (기본 `false`)
   - `recurringType: DaylyRecurringType?` — **String 아닌 enum** (오타 방지, explicit 선호)
   ```dart
   enum DaylyRecurringType { annual }
   // fromJson: DaylyRecurringType.values.byName(json['recurringType'])
   ```
2. `DaylyWidgetStorage` 직렬화/역직렬화 업데이트 (`DaylyWidgetModel.copyWith()` 포함)
3. `WidgetUpdateManager` (Android Kotlin) + iOS Swift 위젯 업데이트 로직:
   - `targetDate < today && isRecurring == true`이면 다음 해로 갱신
   - **Leap day 처리 필수**: `2월 29일` + 비윤년 → `2월 28일` (Dart/Kotlin 오버플로 방지)
   ```kotlin
   fun advanceToNextYear(date: LocalDate): LocalDate {
       val nextYear = date.year + 1
       return if (date.monthValue == 2 && date.dayOfMonth == 29
                  && !Year.isLeap(nextYear.toLong())) {
           LocalDate.of(nextYear, 2, 28)
       } else {
           date.withYear(nextYear)
       }
   }
   ```
   - **갱신 후 즉시 `DaylyWidgetStorage.save()` 호출 필수** (이중 갱신 방지)
4. `add_widget_bottom_sheet.dart`에 "매년 반복" 토글 UI 추가
5. **테스트 (Kotlin)** — `WidgetUpdateManagerTest.kt` 또는 신규 `RecurringEventTest.kt`:
   - `testRecurringNormalDate`: 2025-01-15 → 2026-01-15
   - `testRecurringLeapDay`: 2024-02-29 (비윤년) → 2025-02-28
   - `testRecurringFutureDate`: 미래 날짜 → 변경 없음
   - `testRecurringIdempotency`: 갱신 후 재실행 → no-op
6. **테스트 (iOS Swift)** — `ios/DaylyWidgetTests/RecurringEventTests.swift`:
   - `testAdvanceToNextYearNormal`, `testAdvanceLeapDayToNonLeap`, `testDoNotAdvanceFutureDate`
   - *iOS XCTest 인프라 미구현 시 P3 TODO(iOS Swift 유닛테스트) 먼저 완료*

**Effort:** M | **Priority:** P1
**Depends on:** 없음

---

## P1 — Android 위젯 Kotlin 유닛테스트 추가

**What:** WidgetUpdateManager 로직 검증을 위한 Kotlin 유닛테스트 추가

**Why:** CRITICAL 버그(AlarmManager 생명주기) 수정 후 회귀를 방지할 자동화 검증이 없음.
현재 `cancelIfNone()`의 3-Provider 체크, `buildCountdownText()` 경계값 처리,
`parseAll()` 예외 케이스를 수동으로만 확인 가능한 상태.

**Pros:** 알람 관련 버그가 다시 재발할 경우 즉시 감지 가능

**Cons:** Android 유닛테스트는 Robolectric 또는 Mockito 설정 필요 (초기 셋업 비용 M)

**Context:** WidgetUpdateManager.kt 도입으로 핵심 로직이 순수 Kotlin으로 분리됨.
`buildCountdownText()`는 LocalDate 연산이므로 JVM 단에서 바로 테스트 가능.
시작점: `android/app/src/test/kotlin/juny/dayly/` 디렉터리 생성 후
`WidgetUpdateManagerTest.kt`, `BuildCountdownTextTest.kt` 추가.

**진행 상황:** JVM 단계 완료 (BuildCountdownTextTest.kt). Robolectric 단계 (cancelIfNone, scheduleIfNeeded) 는 별도 추진.
**Depends on 업데이트:** P1-Robolectric은 build.gradle.kts Robolectric 의존성 추가에 depend.

**Effort:** M | **Priority:** P1
**Depends on:** v1.5.0 WidgetUpdateManager 구현 완료

---

## P2 — 위젯 진행 바 + isPast 로직 유닛테스트 추가

**What:** `fillFraction` 계산, `isPast` alpha 처리의 edge case 유닛테스트 추가

**Why:** v1.6.0에서 setViewPadding → setScaleX 수정 시 발견했듯, 이 로직은 RemoteViews 제약으로 실기기 없이 검증하기 어렵다. 순수 계산 부분만이라도 자동화 필요.

**Pros:** totalCount=0, currentIndex=max 같은 경계값 회귀 방지. fillFraction 계산 수식 변경 시 즉시 감지.

**Cons:** RemoteViews의 실제 시각 렌더링은 테스트 불가 — 계산 로직만 커버 가능.

**Context:** `fillFraction = (currentIndex + 1).toFloat() / totalCount`. Edge cases: totalCount=0 (→ 1.0f fallback), currentIndex=0 (→ 1/total), currentIndex=totalCount-1 (→ 1.0f).
P1 테스트와 동일한 디렉터리(`android/app/src/test/kotlin/juny/dayly/`)에 `WidgetProgressTest.kt` 추가 권장.

**Effort:** S | **Priority:** P2
**Depends on:** P1 테스트 셋업 완료 → ✅ build.gradle.kts JUnit 4 추가로 해소됨

---

## P2 — `EventDetailScreen` 실시간 변경 시 알림 재예약

**What:** `onWidgetChanged` 콜백 내에서 `_notifRepo.schedule(updatedModel)` 호출 추가

**Why:** `_openEdit`(SharePreviewScreenV2)에서 targetDate 변경 후 홈 버튼 이탈 시, 위젯은 즉시 갱신되지만 알림 스케줄은 앱 재진입 + 뒤로가기까지 갱신되지 않음.

**How to apply:** `WidgetGridScreen._openDetail()` 내 `onWidgetChanged` 콜백에 `_notifRepo.schedule(updatedModel, languageCode: lang)` 추가. languageCode는 `UiKitLocalizations.of(context)` 로 획득 필요 (mounted 확인 후).

**Depends on:** v1.7.5 홈화면 위젯 즉시 갱신 버그 수정 완료

**Effort:** S | **Priority:** P2

---

## P3 — 테마 색상 중앙화

**What:** `themeBarColor()` (ConfigActivity)와 `progressFillColor` (RemoteViewsService) 중복 색상 상수 제거

**Why:** 동일한 테마 색상이 두 곳에 분산. 신규 테마 추가 시 두 파일 모두 수정 필요. v1.6.0 eng review에서 DRY 위반으로 식별.

**Pros:** 테마 추가/변경 시 단일 수정 지점. 색상 일관성 보장.

**Cons:** 공유 모듈/companion object 신설 필요. ConfigActivity(regular Views)와 RemoteViewsService(Int 색상)가 서로 다른 타입을 사용해 인터페이스 설계가 약간 복잡.

**Context:** 현재 `DaylyWidgetConfigActivity.themeBarColor()`와 `DaylyWidgetRemoteViewsService.themeColors()`가 5개 테마 색상을 각각 정의. `android/app/src/main/kotlin/juny/dayly/DaylyThemeColors.kt` 신설 또는 `DaylyAppWidget` companion object에 상수 추가 방식 검토.

**Effort:** S | **Priority:** P3
**Depends on:** 없음

---

## P3 — iOS App Group 공유 컨테이너 오래된 배경 이미지 정리

**What:** 사용자가 배경 이미지를 변경/제거할 때 App Group 컨테이너(`group.juny.dayly/backgrounds/`)에 남아 있는 이전 이미지 파일 자동 삭제

**Why:** v1.8.0에서 iOS 위젯 배경 이미지 지원 추가 시, Flutter가 이미지를 App Group 공유 컨테이너로 복사하지만, 이전 이미지는 삭제하지 않음. 시간이 지나면 디스크 공간을 불필요하게 차지.

**Pros:** 디스크 공간 절약. 오래된 파일이 쌓이지 않음.

**Cons:** `updateAll()` 실행 시마다 현재 위젯이 참조하는 이미지 목록을 비교해야 함. 약간의 복잡도 증가.

**Context:** `HomeWidgetService.updateAll()` 실행 시, 현재 위젯들의 `backgroundImagePath` 목록을 수집하고, `$containerPath/backgrounds/` 디렉터리의 파일 중 참조되지 않는 것을 삭제하는 cleanup 로직 추가. iOS에서만 실행 (`Platform.isIOS`).

**Effort:** S | **Priority:** P3
**Depends on:** v1.8.0 iOS 위젯 배경 이미지 지원

---

## P3 — iOS Swift 위젯 순수 함수 유닛테스트 추가

**What:** `buildCountdownText()` 와 `calcProgress()` XCTest 유닛테스트 추가

**Why:** Android P1/P2 테스트(buildCountdownText, fillFraction)와 대칭 커버리지가 없음.
두 함수 모두 외부 의존성 없는 순수 함수로 XCTest에서 즉시 테스트 가능.
D-Day 계산 로직 변경 시 회귀를 자동으로 감지할 수단이 없음.

**Pros:** dayDiff 경계값(D-Day 당일, 과거, weeksDays remainder=0),
calcProgress 클램핑(createdAt > targetDate, total=0) 회귀 방지.

**Cons:** Swift Package / XCTest 타겟 설정 필요 (초기 셋업 S 수준).
WidgetKit SwiftUI 렌더링 레이어는 테스트 불가 — 순수 계산 레이어만 커버.

**Context:** 대상 함수: `DaylyWidget.swift`의 `buildCountdownText(targetDateIso:countdownMode:)`
와 `calcProgress(createdAtIso:targetDateIso:)`.
시작점: `ios/DaylyWidgetTests/` 타겟 생성 후 `CountdownTextTests.swift`,
`ProgressTests.swift` 추가. Android `BuildCountdownTextTest.kt` 경계값을 참고.

**Effort:** S | **Priority:** P3
**Depends on:** 없음
