package com.example.mymemberships
import org.junit.Test
import org.junit.Assert.*
import java.time.LocalDate
class ReceiptParserTest {
    private val catalog=listOf(Service("yt","YouTube Premium","유튜브","영상",listOf("유튜브"),"https://youtube.com",listOf(Plan("Premium",14900.0,"웹","KRW",false)),emptyList(),null,null),Service("music","YouTube Music","유튜브 뮤직","음악",listOf("유튜브 뮤직"),"https://youtube.com",emptyList(),emptyList(),null,null))
    @Test fun koreanNextDatePriceCycle() {
        val r=ReceiptParser.parse("유튜브\n월간 구독\n결제 금액 14,900원\n다음 결제일: 2026년 11월 26일",catalog)
        assertEquals("yt",r.service?.id);assertNull(r.subscription().planName);assertEquals("unknown",r.subscription().channel);assertEquals(false,r.yearly);assertEquals(14900.0,r.amounts.first().value,0.001);assertEquals(LocalDate.of(2026,11,26),r.nextDate)
    }
    @Test fun longestAliasWins() {assertEquals("music",ReceiptParser.parse("유튜브 뮤직",catalog).service?.id)}
    @Test fun paidDateNeverAssumedNextDate() {
        assertNull(ReceiptParser.parse("결제일 2026-10-26\n무료체험 종료 2026-11-26\n월간",catalog).nextDate)
        assertNull(ReceiptParser.parse("Next payment:\nInvoice paid 2026-10-26",catalog).nextDate)
    }
    @Test fun dateAfterLabelNotEarlierInSameLine() {
        assertEquals(LocalDate.of(2026,11,26),ReceiptParser.parse("Paid 2026-10-26 Next payment: 2026-11-26",catalog).nextDate)
    }
    @Test fun usdAnnualAndEnglishDate() {
        val r=ReceiptParser.parse("Annual plan\nTotal US$15.49\nRenews on November 26, 2026",catalog)
        assertEquals(true,r.yearly);assertEquals("USD",r.amounts.first().currency);assertEquals(15.49,r.amounts.first().value,0.001);assertEquals(LocalDate.of(2026,11,26),r.nextDate)
    }
    @Test fun invalidDateAndAmbiguousCyclesNeedReview() {
        assertNull(ReceiptParser.parse("월간 연간\n다음 결제일 2026-02-29",catalog).yearly)
        assertNull(ReceiptParser.parse("다음 결제일 2026-02-29",catalog).nextDate)
        assertNull(ReceiptParser.parse("다음 결제일 11월 25일",catalog).nextDate)
    }
    @Test fun totalsRankAboveTaxAndAmountsDeduplicate() {
        val r=ReceiptParser.parse("세금 1,000원\n총액 13,500원\n총액 13,500원",catalog)
        assertEquals(13500.0,r.amounts.first().value,0.001);assertEquals(2,r.amounts.size)
    }
    @Test fun emptyDataDoesNotGuessService() {val r=ReceiptParser.parse("",catalog);assertNull(r.service);assertTrue(r.amounts.isEmpty());assertNull(r.nextDate);assertTrue(r.warnings.size>=4)}
    @Test fun correctedNameChangesReceiptServiceAndUnknownNameClearsWrongLinks() {
        val parsed=ReceiptParser.parse("YouTube Premium monthly KRW 14900",catalog).subscription()
        assertEquals("music",parsed.copy(name="유튜브 뮤직").correctReceiptService(catalog).serviceID)
        val unknown=parsed.copy(name="내가 입력한 서비스").correctReceiptService(catalog)
        assertNull(unknown.serviceID);assertNull(unknown.category)
        assertEquals(parsed.id,unknown.id);assertEquals(parsed.amount,unknown.amount,0.001)
    }

}
