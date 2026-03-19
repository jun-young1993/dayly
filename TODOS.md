# TODOS

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
