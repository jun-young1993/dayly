package juny.dayly

import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDate

class BuildCountdownTextTest {

    private fun build(date: String, mode: String, lang: String = "en") =
        DaylyAppWidget.buildCountdownText(date, mode, lang)

    // ── 입력 방어 ──────────────────────────────────────────────────

    @Test fun `빈 날짜 - 대시 반환`() = assertEquals("–", build("", "dMinus"))

    @Test fun `잘못된 날짜 형식 - 대시 반환`() = assertEquals("–", build("not-a-date", "days"))

    // ── D-Day (오늘) ───────────────────────────────────────────────

    @Test fun `오늘 날짜 dMinus - D-Day`() {
        val today = LocalDate.now().toString()
        assertEquals("D-Day", build(today, "dMinus"))
    }

    // ── 미래 날짜 방향 검증 (절대 숫자 아닌 패턴) ──────────────────

    @Test fun `미래 날짜 dMinus ko - D-숫자 형식`() {
        val result = build("2099-12-31", "dMinus", "ko")
        assertTrue("D-로 시작해야 함: $result", result.startsWith("D-"))
    }

    @Test fun `미래 날짜 days ko - 남음 포함`() {
        val result = build("2099-12-31", "days", "ko")
        assertTrue("'남음' 포함해야 함: $result", result.contains("남음"))
    }

    @Test fun `미래 날짜 days ja - あと 포함`() {
        val result = build("2099-12-31", "days", "ja")
        assertTrue("'あと' 포함해야 함: $result", result.startsWith("あと"))
    }

    @Test fun `미래 날짜 days en - days left 포함`() {
        val result = build("2099-12-31", "days", "en")
        assertTrue("'days left' 포함: $result", result.contains("days left"))
    }

    // ── 과거 날짜 방향 검증 ────────────────────────────────────────

    @Test fun `과거 날짜 dMinus - D+숫자 형식`() {
        val result = build("2000-01-01", "dMinus")
        assertTrue("D+로 시작해야 함: $result", result.startsWith("D+"))
    }

    @Test fun `과거 날짜 days ko - 지남 포함`() {
        val result = build("2000-01-01", "days", "ko")
        assertTrue("'지남' 포함해야 함: $result", result.contains("지남"))
    }

    // ── weeksDays ─────────────────────────────────────────────────

    @Test fun `weeksDays ko - 주 또는 일 포함`() {
        val result = build("2099-12-31", "weeksDays", "ko")
        assertTrue("'주' 또는 '일' 포함: $result", result.contains("주") || result.contains("일"))
    }

    @Test fun `weeksDays ja - 週間 또는 日 포함`() {
        val result = build("2099-12-31", "weeksDays", "ja")
        assertTrue("週間 또는 日 포함: $result", result.contains("週間") || result.contains("日"))
    }

    // ── 감성 모드 ─────────────────────────────────────────────────

    @Test fun `mornings ko - 아침 포함`() {
        assertTrue(build("2099-12-31", "mornings", "ko").contains("아침"))
    }

    @Test fun `nights ko - 밤 포함`() {
        assertTrue(build("2099-12-31", "nights", "ko").contains("밤"))
    }

    @Test fun `hidden 모드 - 빈 문자열`() {
        assertEquals("", build("2099-12-31", "hidden"))
    }
}
