package juny.dayly

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetProgressTest {

    @Test fun `단일 아이템 - 항상 full`() =
        assertEquals(1.0f, fillFraction(0, 1), 0.001f)

    @Test fun `5개 중 첫 번째`() =
        assertEquals(0.2f, fillFraction(0, 5), 0.001f)

    @Test fun `5개 중 마지막`() =
        assertEquals(1.0f, fillFraction(4, 5), 0.001f)

    @Test fun `totalCount 0 - divide by zero guard`() =
        assertEquals(1.0f, fillFraction(0, 0), 0.001f)

    @Test fun `totalCount 0, currentIndex 임의값`() =
        assertEquals(1.0f, fillFraction(99, 0), 0.001f)

    @Test fun `음수 currentIndex - 클램프 없음, 0f 반환`() =
        assertEquals(0.0f, fillFraction(-1, 5), 0.001f)
}
