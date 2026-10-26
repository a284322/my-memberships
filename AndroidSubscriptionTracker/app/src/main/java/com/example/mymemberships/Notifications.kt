package com.example.mymemberships

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import java.time.*

object ReminderScheduler {
    const val CHANNEL = "payments"
    private fun pending(context: Context, id: String, extras: ReminderEvent? = null, testing: Boolean = false): PendingIntent {
        val intent = Intent(context,ReminderReceiver::class.java).setData(Uri.parse("membership://alarm/"+Uri.encode((if(testing) "test." else "")+id))).putExtra("testing",testing)
        if (extras != null) intent.putExtra("subscriptionID",extras.subscriptionID).putExtra("title",extras.title).putExtra("body",extras.body).putExtra("eventID",extras.id)
        return PendingIntent.getBroadcast(context,0,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    fun allowed(context: Context): Boolean = (Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context,Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) && NotificationManagerCompat.from(context).areNotificationsEnabled() && (context.getSystemService(NotificationManager::class.java).getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE)
    fun createChannel(context: Context) {
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(NotificationChannel(CHANNEL,"결제 전 알림",NotificationManager.IMPORTANCE_DEFAULT).apply { description="다가오는 구독 결제일과 무료체험·할인 종료를 알려드려요." })
    }
    private fun eventJson(e: ReminderEvent) = org.json.JSONObject().put("id",e.id).put("subscriptionID",e.subscriptionID).put("fire",e.fire.toString()).put("title",e.title).put("body",e.body)
    private fun event(j: org.json.JSONObject) = ReminderEvent(j.getString("id"),j.getString("subscriptionID"),LocalDateTime.parse(j.getString("fire")),j.getString("title"),j.getString("body"))
    private fun post(context: Context, e: ReminderEvent, testing: Boolean, now: LocalDateTime): Boolean {
        val open = Intent(context,MainActivity::class.java).putExtra("subscriptionID",e.subscriptionID).putExtra("testing",testing).setData(Uri.parse("membership://subscription/${e.subscriptionID}")).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val click = PendingIntent.getActivity(context,0,open,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val delayed = e.fire.toLocalDate() < now.toLocalDate()
        val body = if(delayed) "${e.fire.toLocalDate()}에 예약된 알림이에요. ${e.body}" else e.body
        val n = NotificationCompat.Builder(context,CHANNEL).setSmallIcon(R.drawable.ic_notification).setContentTitle(if(delayed) "지연된 알림 · ${e.title}" else e.title).setContentText(body).setStyle(NotificationCompat.BigTextStyle().bigText(body)).setAutoCancel(true).setContentIntent(click).build()
        return try { NotificationManagerCompat.from(context).notify(e.id,0,n); true } catch (_: SecurityException) { false }
    }
    @Synchronized fun reschedule(context: Context, testing: Boolean = false, now: LocalDateTime = LocalDateTime.now()) {
        // Read first: a transient read failure must not destroy the existing reservations.
        val snapshot = Repository(context,testing).load()
        createChannel(context)
        val alarm = context.getSystemService(AlarmManager::class.java)
        val prefs = context.getSharedPreferences(if(testing) "scheduled-test" else "scheduled",Context.MODE_PRIVATE)
        val old = runCatching { JSONArray(prefs.getString("ids","[]")) }.getOrDefault(JSONArray())
        val stored = runCatching { JSONArray(prefs.getString("events","[]")).objects().map(::event) }.getOrDefault(emptyList())
        val posted = runCatching { org.json.JSONObject(prefs.getString("posted","{}")!!) }.getOrDefault(org.json.JSONObject())
        val canNotify = allowed(context)
        if(canNotify) {
            // Deliver every still-valid due sibling before cancelling anything, including Doze delays.
            for(previous in stored.filter { it.fire <= now && it.fire >= now.minusDays(7) }) {
                if(posted.has(previous.id)) continue
                val item = snapshot.items.firstOrNull {it.id==previous.subscriptionID} ?: continue
                val current = ReminderPlanner.events(listOf(item),snapshot.defaults,previous.fire.minusNanos(1),limit=50000).firstOrNull {it.id==previous.id && it.fire==previous.fire} ?: continue
                if(!item.isEffective(now.toLocalDate())) continue
                if(post(context,current,testing,now)) posted.put(current.id,now.toString())
            }
        }
        val expired = posted.keys().asSequence().filter { key -> runCatching {LocalDateTime.parse(posted.getString(key)) < now.minusDays(7)}.getOrDefault(true) }.toList()
        expired.forEach {posted.remove(it)}
        // Persist delivery history before cancellation so a second broadcast cannot repeat the batch.
        check(prefs.edit().putString("posted",posted.toString()).commit()) {"알림 전달 기록을 저장하지 못했어요."}
        val future = if(canNotify) ReminderPlanner.events(snapshot.items,snapshot.defaults,now,limit=400) else emptyList()
        val nextEvent = future.firstOrNull()
        val ids = listOfNotNull(nextEvent?.id)+if(snapshot.items.isNotEmpty()) listOf("refresh") else emptyList()
        // One wake-up drains the whole due batch. Hundreds of simultaneous alarms are unnecessary.
        // Install replacements before cancelling obsolete requests, so a failure keeps old wake-ups alive.
        check(prefs.edit().putString("events",JSONArray(future.map(::eventJson)).toString()).putString("ids",JSONArray(ids).toString()).commit())
        if(nextEvent!=null) alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,nextEvent.fire.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli(),pending(context,nextEvent.id,nextEvent,testing))
        if(snapshot.items.isNotEmpty()) {
            val next = now.toLocalDate().plusDays(1).atTime(8,0).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,next,pending(context,"refresh",testing=testing))
        }
        for(i in 0 until old.length()) if(old.getString(i) !in ids) alarm.cancel(pending(context,old.getString(i),testing=testing))

    }
}
class ReminderReceiver: BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val testing = BuildConfig.DEBUG && intent.getBooleanExtra("testing",false)
        runCatching {ReminderScheduler.reschedule(context,testing)}
    }
}
class RescheduleReceiver: BroadcastReceiver() { override fun onReceive(context: Context,intent: Intent) {
    if(intent.action in setOf(Intent.ACTION_BOOT_COMPLETED,Intent.ACTION_TIME_CHANGED,Intent.ACTION_TIMEZONE_CHANGED,Intent.ACTION_MY_PACKAGE_REPLACED)) runCatching {ReminderScheduler.reschedule(context)}
} }
