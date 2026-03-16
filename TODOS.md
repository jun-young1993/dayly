# TODOS

---

## P0 — "Could not add widget" 에러 원인 파악 및 수정

**What:** ProgressBar → FrameLayout 교체 후 홈화면 위젯 추가 시 "Could not add widget" 에러 발생

**Why:** 위젯이 추가되지 않으면 핵심 기능 자체가 동작하지 않음.

**Pros:** 수정 시 v1.6.0 변경사항이 정상 배포 가능.

**Cons:** 원인 파악 전까지 v1.6.0은 위젯 추가 불가 상태. 롤백 또는 핫픽스 필요.

**Context:** v1.6.0에서 `dayly_widget_stack_item_medium.xml`, `dayly_widget_stack_item_large.xml`의 `<ProgressBar id="widget_progress">`를 `<FrameLayout id="widget_progress_container">` + 2개 View로 교체. 에러 발생 시점이 위젯 추가 직후이므로 `DaylyWidgetRemoteViewsService.getViewAt()` 또는 레이아웃 inflate 단계에서 R.id 미스매치 또는 crash 가능성이 높음. 확인 포인트:
- `R.id.widget_progress_container` / `widget_progress_track` / `widget_progress_fill` ID가 빌드 후 R.java에 생성되었는지
- 기존 `R.id.widget_progress`를 참조하는 코드가 다른 파일에 남아있는지 (`grep -r "widget_progress[^_]"`)
- `setFloat("setPivotX", 0f)` / `setFloat("setScaleX", ...)` 가 해당 API 레벨에서 예외를 던지는지 (logcat 확인)
- `activity_widget_config.xml`의 `@string/widget_config_title` 참조가 올바른지

**Effort:** S | **Priority:** P0
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
**Depends on:** P1 테스트 셋업 완료 (Robolectric 또는 JVM 환경)

---

## P3 — 테마 색상 중앙화

**What:** `themeBarColor()` (ConfigActivity)와 `progressFillColor` (RemoteViewsService) 중복 색상 상수 제거

**Why:** 동일한 테마 색상이 두 곳에 분산. 신규 테마 추가 시 두 파일 모두 수정 필요. v1.6.0 eng review에서 DRY 위반으로 식별.

**Pros:** 테마 추가/변경 시 단일 수정 지점. 색상 일관성 보장.

**Cons:** 공유 모듈/companion object 신설 필요. ConfigActivity(regular Views)와 RemoteViewsService(Int 색상)가 서로 다른 타입을 사용해 인터페이스 설계가 약간 복잡.

**Context:** 현재 `DaylyWidgetConfigActivity.themeBarColor()`와 `DaylyWidgetRemoteViewsService.themeColors()`가 5개 테마 색상을 각각 정의. `android/app/src/main/kotlin/juny/dayly/DaylyThemeColors.kt` 신설 또는 `DaylyAppWidget` companion object에 상수 추가 방식 검토.

**Effort:** S | **Priority:** P3
**Depends on:** 없음
