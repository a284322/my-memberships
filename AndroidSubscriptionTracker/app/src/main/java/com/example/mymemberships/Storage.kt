package com.example.mymemberships

import android.content.Context
import android.util.AtomicFile
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class Repository(private val file: AtomicFile) {
    constructor(context: Context, testing: Boolean = false): this(AtomicFile(File(context.filesDir,if(testing) "memberships-test.json" else "memberships.json")))
    data class Snapshot(val items: List<Subscription>, val defaults: ReminderPrefs)
    fun load(): Snapshot {
        val bytes = try { file.openRead().use { it.readBytes() } } catch (e: java.io.FileNotFoundException) {
            if(file.baseFile.exists() || File(file.baseFile.path+".bak").exists()) throw e
            return Snapshot(emptyList(),ReminderPrefs())
        }
        val j = JSONObject(String(bytes,Charsets.UTF_8))
        require(j.optInt("version",1) == 1) { "지원하지 않는 저장 형식이에요." }
        val array = j.getJSONArray("items")
        require(array.objects().size == array.length()) { "손상된 구독 데이터가 있어요." }
        val items = array.objects().map(Subscription::parse)
        require(items.map { it.id }.distinct().size == items.size) { "중복된 구독 ID가 있어요." }
        return Snapshot(items,ReminderPrefs.parse(j.optJSONObject("defaults")))
    }
    fun save(snapshot: Snapshot) {
        val j = JSONObject().put("version",1).put("items",JSONArray(snapshot.items.map { it.json() })).put("defaults",snapshot.defaults.json())
        val stream = file.startWrite()
        try { stream.write(j.toString().toByteArray(Charsets.UTF_8)); file.finishWrite(stream) }
        catch (e: Exception) { file.failWrite(stream);throw e }
    }
}
class MembershipStore(val context: Context, val testing: Boolean = false, private val scheduleNotifications: (Context) -> Unit = {ctx -> if(!testing) ReminderScheduler.reschedule(ctx)}, private val currentDate: () -> java.time.LocalDate = {java.time.LocalDate.now()}) {
    private val repo = Repository(context,testing)
    val catalog: List<Service> = JSONArray(context.assets.open("catalog.json").bufferedReader().use { it.readText() }).objects().map(Service::parse)
    var today by mutableStateOf(currentDate()); private set
    fun refreshToday() {today=currentDate()}
    var items by mutableStateOf<List<Subscription>>(emptyList()); private set
    var defaults by mutableStateOf(ReminderPrefs()); private set
    var error by mutableStateOf<String?>(null); private set
    var blocked by mutableStateOf(false); private set
    var notificationError by mutableStateOf<String?>(null); private set
    fun dismissNotificationError() {notificationError=null}
    fun refreshReminders() {try {scheduleNotifications(context);notificationError=null} catch(e: Exception) {notificationError="구독 기록은 보존돼 있어요. 알림을 예약하지 못했으니 권한을 확인하고 다시 시도해 주세요."}}
    init { reload() }
    fun reload() { try { val s = repo.load();items=s.items;defaults=s.defaults;blocked=false;error=null } catch (e: Exception) { blocked=true;error="저장 데이터를 읽지 못했어요. 기존 파일을 보존했어요. 앱을 다시 열어 확인해 주세요." } }
    fun save(item: Subscription): Boolean = commit(if(items.any { it.id == item.id }) items.map { if(it.id == item.id) item else it } else items+item,defaults)
    fun delete(id: String) = commit(items.filter { it.id != id },defaults)
    fun saveDefaults(prefs: ReminderPrefs) = commit(items,prefs)
    private fun commit(values: List<Subscription>, prefs: ReminderPrefs): Boolean {
        if (blocked) return false
        return try {
            repo.save(Repository.Snapshot(values,prefs));items=values;defaults=prefs;error=null
            refreshReminders()
            true
        } catch (e: Exception) { error="저장하지 못했어요. 변경 사항을 다시 저장해 주세요.";false }
    }
    fun service(item: Subscription) = catalog.firstOrNull { it.id == item.serviceID }
}
