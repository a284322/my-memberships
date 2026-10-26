package com.example.mymemberships
import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.graphics.pdf.PdfDocument
import android.net.Uri
import android.util.AtomicFile
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ApplicationProvider
import androidx.test.rule.GrantPermissionRule
import kotlinx.coroutines.runBlocking
import org.junit.*
import org.junit.Assert.*
import org.json.JSONArray
import java.io.File
import java.time.LocalDate
import java.time.LocalDateTime
class DeviceServicesTest {
    @get:Rule val ui=createEmptyComposeRule()
    @get:Rule val permission: GrantPermissionRule=GrantPermissionRule.grant(Manifest.permission.POST_NOTIFICATIONS)
    private val context get()=ApplicationProvider.getApplicationContext<Context>()
    private fun draw(canvas: Canvas) {
        canvas.drawColor(Color.WHITE)
        val p=Paint(Paint.ANTI_ALIAS_FLAG).apply {color=Color.BLACK;textSize=52f;typeface=Typeface.create("sans-serif",Typeface.NORMAL)}
        listOf("YouTube Premium","Monthly subscription","Total KRW 14900","Next payment: 2026-11-26").forEachIndexed {i,line -> canvas.drawText(line,40f,120f+i*110f,p)}
    }
    @Test fun bundledImageOCRAndPDF()= runBlocking {
        val file=File(context.cacheDir,"synthetic-receipt.png")
        val pdf=File(context.cacheDir,"synthetic-receipt.pdf")
        try {
            val bitmap=Bitmap.createBitmap(1080,900,Bitmap.Config.ARGB_8888);draw(Canvas(bitmap));file.outputStream().use {bitmap.compress(Bitmap.CompressFormat.PNG,100,it)};bitmap.recycle()
            val catalog=MembershipStore(context,true).catalog
            val imageResult=ReceiptParser.parse(ReceiptOCR.read(context,Uri.fromFile(file)),catalog)
            assertEquals("service-001",imageResult.service?.id);assertEquals(14900.0,imageResult.amounts.first().value,0.001);assertEquals(LocalDate.of(2026,11,26),imageResult.nextDate)
            val document=PdfDocument()
            try {val page=document.startPage(PdfDocument.PageInfo.Builder(1080,900,1).create());draw(page.canvas);document.finishPage(page);pdf.outputStream().use {document.writeTo(it)}} finally {document.close()}
            val pdfResult=ReceiptParser.parse(ReceiptOCR.read(context,Uri.fromFile(pdf)),catalog)
            assertEquals("service-001",pdfResult.service?.id);assertEquals(LocalDate.of(2026,11,26),pdfResult.nextDate)
        } finally {file.delete();pdf.delete()}
    }
    @Test fun scheduleDisableAndNotificationTapOpensCorrectDetail() {
        val repo=Repository(context,true)
        val fire=LocalDateTime.now().plusDays(1).withHour(9).withMinute(0).withSecond(0).withNano(0)
        val item=Subscription(name="알림 이동 테스트",amount=12300.0,billingDate=fire.toLocalDate().plusDays(3),reminderOverride=ReminderPrefs(true))
        repo.save(Repository.Snapshot(listOf(item),ReminderPrefs()))
        try {
            context.getSharedPreferences("scheduled-test",Context.MODE_PRIVATE).edit().clear().commit()
            ReminderScheduler.createChannel(context);ReminderScheduler.reschedule(context,true,fire.minusMinutes(1))
            val prefs=context.getSharedPreferences("scheduled-test",Context.MODE_PRIVATE)
            assertTrue(JSONArray(prefs.getString("ids","[]")).length()>1)
            ReminderScheduler.reschedule(context,true,fire.plusSeconds(1))
            val manager=context.getSystemService(NotificationManager::class.java)
            val notification=manager.activeNotifications.first {it.tag?.startsWith(item.id)==true}
            notification.notification.contentIntent.send()
            ui.waitUntil(10000) {ui.onAllNodesWithText("알림 이동 테스트").fetchSemanticsNodes().isNotEmpty()}
            ui.onNodeWithText("다음 결제일").assertIsDisplayed()
            repo.save(Repository.Snapshot(listOf(item.copy(reminderOverride=ReminderPrefs())),ReminderPrefs()))
            ReminderScheduler.reschedule(context,true)
            assertEquals(listOf("refresh"),JSONArray(prefs.getString("ids","[]")).let {a -> (0 until a.length()).map {a.getString(it)}})
            repo.save(Repository.Snapshot(emptyList(),ReminderPrefs()));ReminderScheduler.reschedule(context,true)
            assertEquals(0,JSONArray(prefs.getString("ids","[]")).length())
            manager.cancel(notification.tag,notification.id)
        } finally {AtomicFile(File(context.filesDir,"memberships-test.json")).delete();ReminderScheduler.reschedule(context,true)}
    }
    @Test fun delayedSiblingsDeliveredTogetherOnceAndInvalidRecordsExcluded() {
        val repo=Repository(context,true)
        val fire=LocalDateTime.now().plusDays(1).withHour(9).withMinute(0).withSecond(0).withNano(0)
        val items=(1..4).map {Subscription(name="동시 알림 $it",amount=9900.0,billingDate=fire.toLocalDate().plusDays(3),reminderOverride=ReminderPrefs(true))}
        val manager=context.getSystemService(NotificationManager::class.java)
        val prefs=context.getSharedPreferences("scheduled-test",Context.MODE_PRIVATE)
        prefs.edit().clear().commit()
        repo.save(Repository.Snapshot(items,ReminderPrefs()))
        try {
            ReminderScheduler.reschedule(context,true,fire.minusMinutes(1))
            // A deleted subscription must not survive in a previously scheduled due batch.
            repo.save(Repository.Snapshot(items.take(2)+items[3].copy(reminderOverride=ReminderPrefs()),ReminderPrefs()))
            ReminderScheduler.reschedule(context,true,fire.plusMinutes(15))
            val active=manager.activeNotifications.filter {n -> items.any {n.tag?.startsWith(it.id)==true}}
            assertEquals(2,active.size)
            val postedBefore=prefs.getString("posted",null)
            ReminderScheduler.reschedule(context,true,fire.plusMinutes(16))
            assertEquals(postedBefore,prefs.getString("posted",null))
            assertEquals(2,manager.activeNotifications.count {n -> items.any {n.tag?.startsWith(it.id)==true}})
            repo.save(Repository.Snapshot(emptyList(),ReminderPrefs()))
            ReminderScheduler.reschedule(context,true,fire.plusMinutes(17))
            assertEquals(0,JSONArray(prefs.getString("ids","[]")).length())
        } finally {
            manager.activeNotifications.filter {n -> items.any {n.tag?.startsWith(it.id)==true}}.forEach {manager.cancel(it.tag,it.id)}
            repo.save(Repository.Snapshot(emptyList(),ReminderPrefs()));ReminderScheduler.reschedule(context,true)
        }
    }

}
