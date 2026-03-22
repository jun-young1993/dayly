# TODOS

---

## ✅ TODO-BIZ-3 — iOS 공유 텍스트 App Store 링크 추가 (P0, XS) — DONE 2026-03-22

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

## ✅ TODO-BIZ-1 — Firebase Analytics 추가 (P0, S) — DONE 2026-03-22

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

## ✅ TODO-BIZ-2 — App Open 광고 쿨다운 구현 (P0, S) — DONE 2026-03-22

**What:** `AppOpenAdManager`에 SharedPreferences 기반 쿨다운 영속화 추가 → 광고 재활성화

**Why:** App Open 광고가 쿨다운 없이 모든 `AppLifecycleState.resumed`에서 노출되어 UX 훼손. 또한 `_lastShownTime`이 메모리 필드라 앱 재시작 시 쿨다운이 리셋됨 — 진짜 24시간 쿨다운을 위해 패키지 수정 필요.

**Context:**
**Step 1 — 패키지 수정** (`flutter_ui_kit/packages/flutter_ui_kit_google_mobile_ads/`):
```yaml
# pubspec.yaml에 추가
dependencies:
  shared_preferences: ^2.x
```
```dart
// app_open_ad_manager.dart
static const _kLastShownKey = 'flutter_ui_kit_app_open_last_shown';

void configure({required String androidId, required String iosId}) {
  // ... 기존 코드 ...
  unawaited(_loadLastShownTime()); // 추가
}

// onAdShowedFullScreenContent 콜백에서:
_lastShownTime = DateTime.now();
unawaited(_saveLastShownTime()); // 추가

Future<void> _loadLastShownTime() async {
  final prefs = await SharedPreferences.getInstance();
  final millis = prefs.getInt(_kLastShownKey);
  if (millis != null) _lastShownTime = DateTime.fromMillisecondsSinceEpoch(millis);
}

Future<void> _saveLastShownTime() async {
  final prefs = await SharedPreferences.getInstance();
  if (_lastShownTime != null) {
    await prefs.setInt(_kLastShownKey, _lastShownTime!.millisecondsSinceEpoch);
  }
}
```

**Step 2 — dayly main.dart** (`configure()` 호출 전 1줄 추가):
```dart
AppOpenAdManager.instance.cooldown = const Duration(hours: 24);
AppOpenAdManager.instance.configure(
  androidId: 'ca-app-pub-4656262305566191/4017810905',
  iosId: 'ca-app-pub-4656262305566191/9437357221',
);
AppOpenAdManager.instance.loadAd();
```
아울러 stale 주석 2개 제거:
```dart
// 제거: "TODO: flutter_ui_kit_google_mobile_ads에 쿨다운(1h) 추가 후 재활성화."
```

**Effort:** S | **Priority:** P0
**Depends on:** TODO-BIZ-1 (Firebase Analytics — 광고 노출 이벤트 추적)

---

## ✅ TODO-BIZ-4 — 기념일/일정 자동 반복 이벤트 (P1, M) — DONE 2026-03-22

**What:** D-Day 생성 시 "매년 반복" / "매월 반복" 옵션 추가. D-Day 지나면 자동으로 다음 주기로 갱신.

**Why:** D-Day 지나면 앱 사용 이유가 없어지는 구조적 리텐션 문제 해소. 커플 기념일·생일·입사일(annual), 월세·스터디·월간 미팅(monthly) 등 반복 이벤트에 필수 기능.

**Context:**
1. `DaylyWidgetModel`에 필드 추가:
   - `isRecurring: bool` (기본 `false`)
   - `recurringType: DaylyRecurringType?` — **String 아닌 enum** (오타 방지, explicit 선호)
   ```dart
   enum DaylyRecurringType { annual, monthly }
   // fromJson: DaylyRecurringType.values.byName(json['recurringType'])
   ```
2. `DaylyWidgetStorage` 직렬화/역직렬화 업데이트 (`DaylyWidgetModel.copyWith()` 포함)
3. `WidgetUpdateManager` (Android Kotlin) + iOS Swift 위젯 업데이트 로직:
   - `targetDate < today && isRecurring == true`이면 다음 주기로 갱신
   - **annual**: 다음 해 같은 월/일. Leap day 처리 필수: `2월 29일` + 비윤년 → `2월 28일`
   - **monthly**: 다음 달 같은 일. 단월 처리: `1월 31일` + 1개월 → `2월 28/29일` (Kotlin `plusMonths(1)` 자동 처리)
   ```kotlin
   fun advanceDate(date: LocalDate, type: DaylyRecurringType): LocalDate = when (type) {
       DaylyRecurringType.ANNUAL -> {
           val nextYear = date.year + 1
           if (date.monthValue == 2 && date.dayOfMonth == 29 && !Year.isLeap(nextYear.toLong()))
               LocalDate.of(nextYear, 2, 28)
           else date.withYear(nextYear)
       }
       DaylyRecurringType.MONTHLY -> date.plusMonths(1) // 단월 자동 처리
   }
   ```
   - **갱신 후 즉시 `DaylyWidgetStorage.save()` 호출 필수** (이중 갱신 방지)
4. `add_widget_bottom_sheet.dart`에 반복 주기 선택 UI 추가 ("반복 없음" / "매년 반복" / "매월 반복")
5. **테스트 (Kotlin)** — `WidgetUpdateManagerTest.kt` 또는 신규 `RecurringEventTest.kt`:
   - `testRecurringAnnualNormal`: 2025-01-15 → 2026-01-15
   - `testRecurringAnnualLeapDay`: 2024-02-29 (비윤년) → 2025-02-28
   - `testRecurringMonthlyNormal`: 2025-01-15 → 2025-02-15
   - `testRecurringMonthlyLastDay`: 2025-01-31 → 2025-02-28 (단월)
   - `testRecurringFutureDate`: 미래 날짜 → 변경 없음
   - `testRecurringIdempotency`: 갱신 후 재실행 → no-op
6. **테스트 (iOS Swift)** — `ios/DaylyWidgetTests/RecurringEventTests.swift`:
   - `testAdvanceAnnualNormal`, `testAdvanceAnnualLeapDay`, `testAdvanceMonthlyNormal`, `testAdvanceMonthlyLastDay`, `testDoNotAdvanceFutureDate`
   - *iOS XCTest 인프라 미구현 시 P3 TODO(iOS Swift 유닛테스트) 먼저 완료*

**Effort:** M | **Priority:** P1
**Depends on:** 없음

---

## TODO-BIZ-5 — IAP 프리미엄 구매 플로우 (P1, M)

**What:** `in_app_purchase` 패키지로 1회성 프리미엄 잠금 해제 구현

**Why:** BUSINESS.md 수익 전략의 핵심 2단계. 광고 단독 수익($1,500/월 MAU10만)의 한계를 뛰어넘는 수익원. 단, 데이터 없이 가격/트리거 설정하면 전환율 미스매치 — BIZ-1 시프 후 4주 데이터 기반으로 결정.

**Context:**
- `DaylyWidgetModel.isPremium` 필드 이미 있음 → 즉시 활용 가능
- 구매 성공 시: `isPremium=true` 로컬 저장 + 전체 위젯 갱신
- 가격 후보: $2.99 (한국/미국), ¥480 (일본 Apple 고정 티어)
- 트리거 지점 (데이터 기반 결정): 위젯 6개 이상 추가 시 or 공유 3회 후
- 복원 구매(`restorePurchases`) 필수 구현
- BIZ-6(프리미엄 카드)이 이 TODO에 depend함

**Pros:** 광고+IAP 복합 수익. 프리미엄 유저가 역바이럴 플라이휠 활성화.
**Cons:** App Store 심사 (IAP 심사 추가 2~3일). 환불 정책 검토 필요.

**Effort:** M | **Priority:** P1
**Depends on:** TODO-BIZ-1 (Analytics — 4주 전환 트리거 데이터 확보 후)

---

## TODO-BIZ-6 — 프리미엄 공유 카드 프레임 (P1, M)

**What:** 프리미엄 유저 공유 시 전용 카드 프레임 + subtle "dayly Premium" 배지 표시

**Why:** 역바이럴(Reverse Viral) 핵심 레버. 프리미엄 카드가 SNS에 퍼질 때 수령자가 "이게 뭐야?" 반응 → 무료 유저 다운로드 유도. 워터마크(dayly)는 절대 제거 금지 — 이 배지는 추가이지 대체가 아님.

**Context:**
- `share_preview_screen_v2.dart`: `isPremium`이면 프리미엄 프레임 렌더
  - 무료: 현재 카드 그대로 (dayly 워터마크 유지)
  - 프리미엄: 글래스모피즘/계절 한정 프레임 + 우하단 subtle "dayly Premium" 배지
- `dayly_share_export.dart`의 `captureBoundaryPng()` 재사용
- `DaylyWidgetCard` 위에 Stack 레이어로 프리미엄 프레임 오버레이
- Analytics: `DaylyAnalytics.logShareTapped(isPremium: bool)` 파라미터 추가

**Pros:** IAP 전환율 상승. 공유 카드 자체가 광고 역할.
**Cons:** 프레임 디자인 리소스 필요. 계절 한정 프레임은 주기적 업데이트 필요.

**Effort:** M | **Priority:** P1
**Depends on:** TODO-BIZ-5 (IAP — isPremium 실제 구매 연결 후)

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

---

## TODO-T1 — 공유 화면에서 반복 이벤트 배지 표시 (P2, S)

**What:** `share_preview_screen_v2.dart`에서 `isRecurring=true`인 위젯 공유 시 "매년 반복" / "매월 반복" 레이블 표시

**Why:** 공유 카드에 반복 이벤트 컨텍스트 제공 → 수신자가 "매년 기념일"임을 인지 → 감성 강화 및 재공유 유도

**Pros:** 위젯의 반복 속성이 공유 카드에 반영되어 완전한 정보 전달. 추가 코드 최소화.
**Cons:** 카드 레이아웃 조정 필요 (badge 공간 확보). 디자인 검토 필요.

**Context:** `DaylyWidgetCard` 위에 Stack + Positioned 레이어로 subtle badge 추가.
`isRecurring && recurringType != null` 조건부 렌더링.
l10n.custom() 필수 — ko("매년 반복"/"매월 반복"), ja("毎年"/"毎月"), en("Yearly"/"Monthly").

**Effort:** S | **Priority:** P2
**Depends on:** TODO-BIZ-4 (isRecurring 필드 존재 후) ✅ 완료

---

## TODO-T2 — 편집 화면에서 반복 타입 변경 지원 (P2, S)

**What:** `share_preview_screen_v2.dart` 편집 모드에서 반복 타입(없음/매년/매월) 변경 가능

**Why:** 위젯 생성 시에만 반복 설정 가능하면 UX 불완전 — 변경하려면 삭제 후 재생성 필요. 사용자 이탈 원인.

**Pros:** 완전한 편집 경험. `add_widget_bottom_sheet`의 `_RecurringSection` 위젯 재사용 가능.
**Cons:** `share_preview_screen_v2.dart`의 편집 시트에 새 섹션 추가 필요. `onWidgetChanged` 콜백으로 상위 전달.

**Context:** `_RecurringSection` StatelessWidget을 `add_widget_bottom_sheet.dart`에서 분리하여
공유 가능한 위치(별도 파일 또는 동일 파일 상단)로 이동. 편집 시트에서 현재 `recurringType` 초기값 주입.

**Effort:** S | **Priority:** P2
**Depends on:** TODO-BIZ-4 (isRecurring 필드 존재 후) ✅ 완료

---

## TODO-T3 — DESIGN.md 생성 (P3, S)

**What:** 글래스 모피즘 팔레트, Montserrat/Roboto Mono 폰트 스케일, ScreenUtil 스페이싱 스케일,
인터랙션 패턴(glass card, backdrop blur, dark/light 조건)을 DESIGN.md로 문서화

**Why:** 현재 in-code 패턴이 사실상 디자인 시스템 역할을 하지만 문서 없이는
신규 피쳐마다 파일을 읽어야 하므로 일관성 보장 어려움

**Pros:** 신규 기능 추가 시 디자인 일관성 유지. Claude Code와 협업 시 DESIGN.md를 context로 제공.
**Cons:** 현재 in-code 패턴을 역으로 문서화하는 작업 필요 (1회성).

**Context:** `/design-consultation` 스킬 또는 수동으로 생성. 기준 파일:
`lib/theme/dayly_palette.dart`, `lib/theme/dayly_theme_presets.dart`, `lib/widgets/dayly_widget_card.dart`.
Montserrat(UI), Gowun Dodum(sentence), Roboto Mono(number) 폰트 사용 정책 포함.

**Effort:** S | **Priority:** P3
**Depends on:** 없음
