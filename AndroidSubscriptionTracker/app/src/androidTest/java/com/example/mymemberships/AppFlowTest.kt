package com.example.mymemberships

import android.content.Context
import android.content.Intent
import android.widget.DatePicker
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.ViewAction
import androidx.test.espresso.UiController
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.espresso.action.ViewActions.click
import androidx.compose.ui.graphics.asAndroidBitmap
import android.graphics.Bitmap
import android.view.View
import org.hamcrest.Matcher
import android.util.AtomicFile
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import org.junit.*
import org.junit.Assert.*
import java.io.File
import java.time.LocalDate
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.lifecycle.ViewModelProvider
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.net.Uri
import kotlinx.coroutines.CompletableDeferred

class AppFlowTest {
    @get:Rule val ui=createEmptyComposeRule()
    private val context get()=ApplicationProvider.getApplicationContext<Context>()
    @Before fun clean() {AtomicFile(File(context.filesDir,"memberships-test.json")).delete()}
    private fun capture(name: String) {
        ui.waitForIdle()
        val dir=File(context.getExternalFilesDir(null),"test-screenshots").apply {mkdirs()}
        File(dir,"$name.png").outputStream().use {ui.onRoot().captureToImage().asAndroidBitmap().compress(Bitmap.CompressFormat.PNG,100,it)}
    }
    @Test fun registerSearchDetailAndRestore() {
        val intent=Intent(context,MainActivity::class.java).putExtra("testing",true).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        ActivityScenario.launch<MainActivity>(intent).use { scenario ->
            ui.onNodeWithText("구독 추가하기").performClick()
            ui.onNodeWithText("서비스 이름 검색").performTextInput("넷플릭스")
            capture("service-search")
            ui.onNodeWithText("Netflix").performClick()
            ui.onNodeWithText("구독 금액").performTextReplacement("13500")
            ui.onNodeWithText("저장").performClick()
            ui.onNodeWithText("다음 결제일").assertIsDisplayed()
            ui.onNodeWithText("13,500원").assertIsDisplayed()
            val selected=LocalDate.now().plusDays(2)
            ui.onNodeWithContentDescription("다음 결제일 수정").performClick()
            onView(isAssignableFrom(DatePicker::class.java)).perform(object: ViewAction {
                override fun getConstraints(): Matcher<View> = isAssignableFrom(DatePicker::class.java)
                override fun getDescription()="다음 결제일 선택"
                override fun perform(controller: UiController,view: View) {(view as DatePicker).updateDate(selected.year,selected.monthValue-1,selected.dayOfMonth);controller.loopMainThreadUntilIdle()}
            })
            onView(withText(android.R.string.ok)).perform(click())
            assertEquals(selected,Repository(context,true).load().items.single().billingDate)
            capture("subscription-detail")
            ui.onNodeWithContentDescription("뒤로").performClick()
            capture("home")
            ui.onNodeWithText("Netflix").performClick()
            ui.onNodeWithText("결제 전 알림받기").performClick()
            ui.onNodeWithText("3일 전").assertIsDisplayed()
            ui.onNodeWithTag("reminders").performScrollToNode(hasText("알림 설정 저장"))
            ui.onNodeWithText("알림 설정 저장").performClick()
            ui.onNodeWithText("결제 전 알림받기").performClick()
            ui.onNodeWithTag("reminders").performScrollToNode(hasText("전체 기본 설정 사용"))
            ui.onNodeWithText("전체 기본 설정 사용").performClick()
            assertNull(Repository(context,true).load().items.single().reminderOverride)
            scenario.recreate()
            ui.onNodeWithText("13,500원").assertIsDisplayed()
            val saved=Repository(context,true).load().items.single()
            assertEquals("service-002",saved.serviceID)
            assertEquals(13500.0,saved.amount,0.001)
            ui.onNodeWithTag("detail-list").performScrollToNode(hasText("구독 삭제"))
            ui.onNodeWithText("구독 삭제").performClick()
            ui.onNodeWithText("삭제",useUnmergedTree=true).performClick()
            ui.onNodeWithText("구독 추가하기").assertIsDisplayed()
            assertTrue(Repository(context,true).load().items.isEmpty())
        }
    }
    @Test fun manualEntryWhenNoResultsAndSave() {
        ActivityScenario.launch<MainActivity>(Intent(context,MainActivity::class.java).putExtra("testing",true).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)).use {
            ui.onNodeWithText("구독 추가하기").performClick()
            ui.onNodeWithText("서비스 이름 검색").performTextInput("개인 멤버십 테스트")
            ui.onNodeWithText("목록에 없는 서비스 직접 입력").performClick()
            ui.onNodeWithText("서비스 이름").performTextInput("동네 도서관")
            ui.onNodeWithText("구독 금액").performTextInput("5000")
            ui.onNodeWithText("저장").performClick()
            ui.onNodeWithText("5,000원").assertIsDisplayed()
            assertEquals("동네 도서관",Repository(context,true).load().items.single().name)
        }
    }
    @Test fun atomicStoragePreservesPreviousDataAndUserFields() {
        val file=AtomicFile(File(context.cacheDir,"repository-test.json"));file.delete()
        try {
            val repo=Repository(file)
            val s=Subscription(name="보존",amount=9900.0,billingDate=LocalDate.of(2026,10,31),extras="""{"customBenefits":[{"id":"custom","title":"기존 혜택","category":"other","conditions":"가입 조건"}],"benefitUsage":{"custom":"unused"}}""")
            repo.save(Repository.Snapshot(listOf(s),ReminderPrefs(true)))
            val loaded=repo.load().items.single()
            assertEquals("기존 혜택",loaded.benefits(null).single().title)
            repo.save(Repository.Snapshot(listOf(loaded.copy(billingDate=LocalDate.of(2026,11,5))),ReminderPrefs()))
            assertEquals(loaded.id,repo.load().items.single().id)
            assertEquals("기존 혜택",repo.load().items.single().benefits(null).single().title)
        } finally {file.delete()}
    }
    @Test fun receiptRecognitionAndEditsSurviveRecreationAndCorrectService() {
        val image=File(context.cacheDir,"rotation-receipt.png")
        val bitmap=Bitmap.createBitmap(1080,900,Bitmap.Config.ARGB_8888)
        val canvas=Canvas(bitmap);canvas.drawColor(Color.WHITE)
        val paint=Paint(Paint.ANTI_ALIAS_FLAG).apply {color=Color.BLACK;textSize=52f}
        listOf("YouTube Premium","Monthly subscription","KRW 14900","Next payment: 2026-11-26").forEachIndexed {i,line -> canvas.drawText(line,40f,120f+i*110f,paint)}
        image.outputStream().use {bitmap.compress(Bitmap.CompressFormat.PNG,100,it)};bitmap.recycle()
        try {
            ActivityScenario.launch<MainActivity>(Intent(context,MainActivity::class.java).putExtra("testing",true).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)).use {scenario ->
                ui.onNodeWithText("사진·영수증으로 자동 입력").performClick()
                lateinit var state: ReceiptState
                scenario.onActivity {activity -> state=ViewModelProvider(activity)[ReceiptState::class.java];state.read(context,Uri.fromFile(image),MembershipStore(context,true).catalog)}
                ui.waitUntil(30000) {state.draft!=null && !state.busy}
                ui.onNodeWithText("서비스 이름").performTextReplacement("유튜브 뮤직")
                ui.onNodeWithTag("form").performScrollToNode(hasText("구독 금액"))
                ui.onNodeWithText("구독 금액").performTextReplacement("16000")
                val original=state
                scenario.recreate()
                scenario.onActivity {assertSame(original,ViewModelProvider(it)[ReceiptState::class.java])}
                ui.onNodeWithTag("form").performScrollToNode(hasText("구독 금액"))
                ui.onNodeWithText("구독 금액").assertTextContains("16000")
                ui.onNodeWithTag("form").performScrollToNode(hasText("금액·주기·다음 결제일을 확인했어요"))
                ui.onNodeWithTag("receipt-confirm").performClick()
                ui.onNodeWithText("저장").performClick()
                val saved=Repository(context,true).load().items.single()
                assertEquals("service-011",saved.serviceID);assertEquals("유튜브 뮤직",saved.name);assertEquals(16000.0,saved.amount,0.001)
            }
        } finally {image.delete()}
    }
    @Test fun rereadingReceiptDisablesAllSaveActionsAndResetsConfirmation() {
        var calls=0
        val gate=CompletableDeferred<String>()
        val state=ReceiptState {_,_ -> if(calls++==0) "YouTube Premium monthly KRW 14900" else gate.await()}
        val catalog=MembershipStore(context,true).catalog
        var saved=0
        try {
            ActivityScenario.launch<MainActivity>(Intent(context,MainActivity::class.java).putExtra("testing",true).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)).use {scenario ->
                scenario.onActivity {activity -> activity.setContent {MaterialTheme {ReceiptScreen(catalog,state,{}, {saved++})}};state.read(context,Uri.EMPTY,catalog)}
                ui.waitUntil(10000) {state.draft!=null}
                ui.onNodeWithTag("form").performScrollToNode(hasText("금액·주기·다음 결제일을 확인했어요"))
                ui.onNodeWithTag("receipt-confirm").performClick()
                ui.onNodeWithText("저장").assertIsEnabled()
                scenario.onActivity {state.read(context,Uri.EMPTY,catalog)}
                ui.onNodeWithText("저장").assertIsNotEnabled()
                ui.onNodeWithText("구독 저장").assertIsNotEnabled()
                assertEquals(0,saved)
                gate.complete("YouTube Premium monthly KRW 20000")
                ui.waitUntil(10000) {!state.busy}
                ui.onNodeWithText("저장").assertIsNotEnabled()
            }
        } finally {state.clear()}
    }
    @Test fun savedZeroPriceCanBeEditedWithoutReenteringAmount() {
        val zero=Subscription(name="무료",amount=0.0)
        var saved: Subscription?=null
        ActivityScenario.launch<MainActivity>(Intent(context,MainActivity::class.java).putExtra("testing",true).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)).use {scenario ->
            scenario.onActivity {it.setContent {MaterialTheme {EditorScreen(zero,null,{},save={saved=it})}}}
            ui.onNodeWithText("구독 금액").assertTextContains("0")
            ui.onNodeWithText("저장").assertIsEnabled().performClick()
            assertEquals(0.0,saved!!.amount,0.001)
        }
    }

    @Test fun notificationFailureDoesNotReportASuccessfulWriteAsFailed() {
        val store=MembershipStore(context,true,scheduleNotifications={throw IllegalStateException("injected scheduling failure")})
        val item=Subscription(name="저장 성공",amount=9900.0)
        assertTrue(store.save(item))
        assertEquals(item.id,Repository(context,true).load().items.single().id)
        assertNull(store.error);assertNotNull(store.notificationError)
    }

    @Test fun dayRefreshUpdatesCalendarMonthTotalsAndNextPayment() {
        var clock=LocalDate.of(2026,10,31)
        val store=MembershipStore(context,true,currentDate={clock})
        store.save(Subscription(name="월말 월간",amount=9900.0,billingDate=clock))
        store.save(Subscription(name="연간",amount=120000.0,yearly=true,billingDate=clock))
        ActivityScenario.launch<MainActivity>(Intent(context,MainActivity::class.java).putExtra("testing",true).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)).use {scenario ->
            scenario.onActivity {it.setContent {MaterialTheme {HomeScreen(store,{}, {}, {}, {}, {})}}}
            ui.onNodeWithText("129,900원").assertIsDisplayed()
            scenario.onActivity {clock=LocalDate.of(2026,11,1);store.refreshToday()}
            ui.onNodeWithText("129,900원").assertDoesNotExist()
            ui.onNodeWithTag("home-list").performScrollToNode(hasText("11월 30일 · 월간"))
            ui.onNodeWithText("11월 30일 · 월간").assertIsDisplayed()
        }
    }

}
