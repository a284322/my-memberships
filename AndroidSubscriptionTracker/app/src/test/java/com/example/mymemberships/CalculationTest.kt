package com.example.mymemberships

import org.junit.Test
import org.junit.Assert.*
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime

class CalculationTest {
    private fun date(value: String)=LocalDate.parse(value)
    @Test fun monthEndKeepsOriginalAnchor() {
        val s=Subscription(name="월말",amount=10000.0,billingDate=date("2024-01-31"))
        assertEquals(listOf("2024-01-31","2024-02-29","2024-03-31","2024-04-30"),s.payments(date("2024-01-01"),date("2024-05-01")).map {it.date.toString()})
        assertEquals(date("2024-03-31"),s.upcoming(date("2024-03-01"))?.date)
    }
    @Test fun leapYearReturnsTo29() {
        val s=Subscription(name="연간",amount=120000.0,yearly=true,billingDate=date("2024-02-29"))
        assertEquals(listOf("2024-02-29","2025-02-28","2026-02-28","2027-02-28","2028-02-29"),s.payments(date("2024-01-01"),date("2029-01-01")).map {it.date.toString()})
    }
    @Test fun annualConversionAndCalendarMonthDiffer() {
        val s=Subscription(name="연간",amount=120000.0,yearly=true,billingDate=date("2025-10-25"))
        assertEquals(10000.0,s.monthly(date("2026-10-01")),0.001)
        assertEquals(120000.0,s.thisMonth(date("2026-10-26")).sumOf {it.amount},0.001)
        assertTrue(s.thisMonth(date("2026-11-01")).isEmpty())
    }
    @Test fun freeEndDoesNotBecomeFirstPayment() {
        val s=Subscription(name="체험",amount=10000.0,billingDate=date("2026-11-10"),freeStartDate=date("2026-10-01"),freeEndDate=date("2026-10-31"))
        assertEquals(0.0,s.price(date("2026-10-31")),0.001)
        assertEquals(date("2026-11-10"),s.upcoming(date("2026-10-20"))?.date)
        assertEquals(10000.0,s.price(date("2026-11-01")),0.001)
    }
    @Test fun zeroPaymentsSkippedAndPromotionUsesEffectiveDate() {
        val s=Subscription(name="할인",amount=5000.0,afterAmount=10000.0,amountEffectiveDate=date("2026-11-15"),discountEndDate=date("2026-11-10"),billingDate=date("2026-10-20"))
        assertEquals(5000.0,s.price(date("2026-11-14")),0.001)
        assertEquals(10000.0,s.price(date("2026-11-15")),0.001)
        assertEquals(10000.0,s.upcoming(date("2026-10-21"))?.amount ?: -1.0,0.001)
        val free=s.copy(amount=0.0)
        assertEquals(date("2026-11-20"),free.upcoming(date("2026-10-01"))?.date)
    }
    @Test fun cancellationInclusiveAndPlannedStillCounts() {
        val s=Subscription(name="해지",amount=10000.0,billingDate=date("2026-10-31"),status="cancelled",cancellationEffectiveDate=date("2026-11-30"))
        assertEquals(listOf(date("2026-10-31")),s.payments(date("2026-10-01"),date("2026-12-31")).map {it.date})
        assertEquals(10000.0,s.copy(status="planned").price(date("2026-12-31")),0.001)
        assertTrue(s.copy(cancellationEffectiveDate=null).payments(date("2026-10-01"),date("2026-12-31")).isEmpty())
    }
    @Test fun reminderDefaultsDisabledAndDistinctFutureOnly() {
        val s=Subscription(name="알림",amount=10000.0,billingDate=date("2026-10-31"))
        val now=LocalDateTime.parse("2026-10-28T10:00:00")
        assertTrue(ReminderPlanner.events(listOf(s),ReminderPrefs(),now).isEmpty())
        val events=ReminderPlanner.events(listOf(s),ReminderPrefs(true,listOf(0,1,3,3,7,30,999)),now)
        assertEquals(2,events.count {it.fire.toLocalDate() < date("2026-11-01")})
        assertTrue(events.all {it.fire>now});assertTrue(events.none {it.id.endsWith(".30")})
        assertEquals(events.size,events.map {it.id}.distinct().size)
    }
    @Test fun overridesAndCancellationCancelEvents() {
        val base=Subscription(name="알림",amount=10000.0,billingDate=date("2026-10-31"))
        val now=LocalDateTime.parse("2026-10-01T00:00:00")
        val defaults=ReminderPrefs(true)
        assertTrue(ReminderPlanner.events(listOf(base.copy(reminderOverride=ReminderPrefs())),defaults,now).isEmpty())
        assertTrue(ReminderPlanner.events(listOf(base.copy(status="cancelled")),defaults,now).isEmpty())
        assertTrue(ReminderPlanner.events(emptyList(),defaults,now).isEmpty())
        assertTrue(ReminderPlanner.events(listOf(base.copy(yearly=true)),ReminderPrefs(true,listOf(30)),now).isNotEmpty())
    }
    @Test fun oldRecordDefaultsAndUnknownFieldsPreserved() {
        val j=JSONObject("""{"id":"old","name":"기존","amount":10000,"billingDate":"2026-10-31","futureField":"keep"}""")
        val s=Subscription.parse(j)
        assertEquals("KRW",s.currency);assertEquals("active",s.status);assertNull(s.reminderOverride)
        assertEquals("keep",s.copy(name="수정").json().getString("futureField"))
        assertEquals(s.copy(extras=s.json().toString()),Subscription.parse(s.json()))
    }
    @Test fun validAmountAndUrlRejectUnsafeInput() {
        for(value in listOf("NaN","Infinity","-1","1000000001","bad")) assertNull(validAmount(value))
        assertEquals(13500.0,validAmount("13,500"))
        for(url in listOf("javascript:alert(1)","file:///etc/passwd","https://", "x")) assertNull(safeUrl(url))
        assertEquals("https://www.netflix.com/",safeUrl("https://www.netflix.com/"))
    }
    @Test fun linkPrioritizesUserAndBillingChannel() {
        val s=Subscription(name="직접",amount=1.0)
        assertNull(s.subscriptionPage(null))
        assertEquals("https://play.google.com/store/account/subscriptions",s.copy(channel="google").subscriptionPage(null)?.url)
        assertEquals("https://apps.apple.com/account/subscriptions",s.copy(channel="apple").subscriptionPage(null)?.url)
        assertEquals(false,s.copy(managementURL="https://example.org/manage").subscriptionPage(null)?.official)
    }
    @Test fun dateEditPreservesOtherFields() {
        val s=Subscription(name="수정",amount=13500.0,planName="스탠다드",billingDate=date("2026-10-31"),reminderOverride=ReminderPrefs(true))
        val edited=s.copy(billingDate=date("2026-11-05"))
        assertEquals(s.id,edited.id);assertEquals(s.amount,edited.amount,0.001);assertEquals(s.reminderOverride,edited.reminderOverride)
        assertEquals(date("2026-11-05"),edited.upcoming(date("2026-10-26"))?.date)
    }
    @Test fun largeCatalogRemindersIncludeEverySubscription() {
        val items=(1..97).map {Subscription(name="서비스 $it",amount=9900.0,billingDate=date("2026-11-01"))}
        val events=ReminderPlanner.events(items,ReminderPrefs(true,listOf(0,1,3,7)),LocalDateTime.parse("2026-10-01T00:00:00"),limit=400)
        assertEquals(97,events.filter {it.fire.toLocalDate()==date("2026-10-25")}.map {it.subscriptionID}.distinct().size)
        assertEquals(97,events.filter {it.fire.toLocalDate()==date("2026-11-01")}.map {it.subscriptionID}.distinct().size)
    }

}
