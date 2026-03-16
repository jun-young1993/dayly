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

**Effort:** M | **Priority:** P1
**Depends on:** v1.5.0 WidgetUpdateManager 구현 완료
