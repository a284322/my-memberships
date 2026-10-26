package com.example.mymemberships

import org.json.JSONArray
import org.json.JSONObject
import java.time.*
import java.time.temporal.ChronoUnit
import java.text.NumberFormat
import java.util.Locale
import java.util.UUID

fun JSONObject.string(key: String): String? = if (isNull(key)) null else optString(key).takeIf { it.isNotBlank() }
fun JSONObject.date(key: String): LocalDate? = string(key)?.let { runCatching { LocalDate.parse(it) }.getOrNull() }
fun JSONObject.number(key: String): Double? = if (isNull(key)) null else optDouble(key).takeIf { it.isFinite() }
fun JSONArray.objects(): List<JSONObject> = (0 until length()).mapNotNull { optJSONObject(it) }
fun money(value: Double, currency: String): String = if (currency == "USD") "$" + String.format(Locale.US, "%,.2f", value) else NumberFormat.getIntegerInstance(Locale.KOREA).format(value) + "원"
fun validAmount(text: String): Double? = text.replace(",", "").trim().toDoubleOrNull()?.takeIf { it.isFinite() && it in 0.0..1_000_000_000.0 }
fun safeUrl(value: String?): String? = value?.takeIf { runCatching { val uri = java.net.URI(it); uri.scheme in listOf("https", "http") && !uri.host.isNullOrBlank() }.getOrDefault(false) }

data class ReminderPrefs(val enabled: Boolean = false, val days: List<Int> = listOf(3), val hour: Int = 9, val minute: Int = 0) {
    val validDays get() = days.filter { it in listOf(0,1,3,7,30) }.distinct().sorted()
    fun json() = JSONObject().put("enabled", enabled).put("days", JSONArray(validDays)).put("hour", hour).put("minute", minute)
    companion object { fun parse(j: JSONObject?) = if (j == null) ReminderPrefs() else ReminderPrefs(j.optBoolean("enabled"), j.optJSONArray("days")?.let { a -> (0 until a.length()).map { a.optInt(it) } } ?: listOf(3), j.optInt("hour",9).coerceIn(0,23), j.optInt("minute",0).coerceIn(0,59)) }
}
data class Benefit(val id: String, val title: String, val category: String, val conditions: String = "", val sourceURL: String? = null, val checkedAt: String? = null) {
    companion object { fun parse(j: JSONObject) = Benefit(j.getString("id"), j.getString("title"), j.optString("category","other"), j.optString("conditions"), safeUrl(j.string("sourceURL")), j.string("checkedAt")) }
}
val benefitCategories = linkedMapOf("delivery" to "배송", "video" to "영상", "music" to "음악", "shopping" to "쇼핑 할인", "points" to "포인트·적립", "other" to "기타")
data class Plan(val name: String, val amount: Double, val channel: String, val currency: String, val yearly: Boolean)
data class Page(val url: String, val directions: String, val checkedAt: String? = null, val official: Boolean = true)
data class Service(val id: String, val name: String, val displayName: String, val category: String, val aliases: List<String>, val source: String, val plans: List<Plan>, val benefits: List<Benefit>, val benefitsPage: Page?, val managementPage: Page?) {
    fun matches(query: String) = listOf(name, displayName, category).plus(aliases).any { it.contains(query.trim(), true) }
    companion object {
        fun page(j: JSONObject?) = j?.let { safeUrl(it.string("url"))?.let { url -> Page(url,it.optString("directions"),it.string("checkedAt")) } }
        fun parse(j: JSONObject): Service {
            val m = j.optJSONObject("membership")
            val aliases = j.optJSONArray("aliases")
            return Service(j.getString("id"),j.getString("name"),j.getString("displayName"),j.getString("category"),aliases?.let { a -> (0 until a.length()).map { a.getString(it) } } ?: emptyList(),j.getString("source"),
                j.optJSONArray("plans")?.objects()?.map { Plan(it.getString("name"),it.getDouble("amount"),it.getString("channel"),it.getString("currency"),it.optBoolean("yearly")) } ?: emptyList(),
                m?.optJSONArray("benefits")?.objects()?.map(Benefit::parse) ?: emptyList(),page(m?.optJSONObject("benefitsPage")),page(m?.optJSONObject("managementPage")))
        }
    }
}
data class Payment(val date: LocalDate, val amount: Double)
data class Subscription(
    val id: String = UUID.randomUUID().toString(), val name: String, val amount: Double,
    val yearly: Boolean = false, val billingDate: LocalDate = LocalDate.now(),
    val serviceID: String? = null, val planName: String? = null, val category: String? = null,
    val currency: String = "KRW", val channel: String = "unknown",
    val freeStartDate: LocalDate? = null, val freeEndDate: LocalDate? = null, val discountEndDate: LocalDate? = null,
    val afterAmount: Double? = null, val amountEffectiveDate: LocalDate? = null,
    val managementURL: String? = null, val reminderOverride: ReminderPrefs? = null,
    val status: String = "active", val cancellationEffectiveDate: LocalDate? = null,
    val extras: String = "{}"
) {
    fun isEffective(date: LocalDate) = status != "cancelled" || (cancellationEffectiveDate != null && date < cancellationEffectiveDate)
    fun isFree(date: LocalDate) = freeStartDate != null && freeEndDate != null && date >= freeStartDate && date <= freeEndDate
    fun price(date: LocalDate): Double = when {
        !isEffective(date) || isFree(date) -> 0.0
        afterAmount != null && amountEffectiveDate != null && date >= amountEffectiveDate -> afterAmount
        else -> amount
    }
    fun monthly(date: LocalDate) = price(date) / if (yearly) 12 else 1
    fun occurrence(index: Long): LocalDate = if (yearly) billingDate.plusYears(index) else billingDate.plusMonths(index)
    fun payments(start: LocalDate, end: LocalDate): List<Payment> {
        val elapsed = if (yearly) ChronoUnit.YEARS.between(billingDate,start) else ChronoUnit.MONTHS.between(billingDate,start)
        val first = (elapsed - 1).coerceAtLeast(0)
        val result = mutableListOf<Payment>()
        for (index in first until first+600) {
            val date = occurrence(index)
            if (date >= end) break
            if (date >= start && price(date) > 0) result += Payment(date,price(date))
        }
        return result
    }
    fun upcoming(today: LocalDate) = payments(today,today.plusYears(5)).firstOrNull()
    fun thisMonth(today: LocalDate) = payments(today.withDayOfMonth(1),today.withDayOfMonth(1).plusMonths(1))
    fun benefits(service: Service?): List<Benefit> {
        val j = JSONObject(extras)
        val hidden = j.optJSONArray("hiddenBenefitIDs")?.let { a -> (0 until a.length()).map { a.getString(it) }.toSet() } ?: emptySet()
        val edits = j.optJSONObject("benefitEdits")
        val originals = service?.benefits ?: emptyList()
        val all = originals.map { edits?.optJSONObject(it.id)?.let(Benefit::parse) ?: it }.toMutableList()
        edits?.keys()?.forEach { if (originals.none { b -> b.id == it }) edits.optJSONObject(it)?.let { b -> all += Benefit.parse(b) } }
        all += j.optJSONArray("customBenefits")?.objects()?.map(Benefit::parse) ?: emptyList()
        return all.filter { it.id !in hidden }
    }
    fun subscriptionPage(service: Service?): Page? {
        safeUrl(managementURL)?.let { return Page(it,"직접 저장한 구독 페이지에서 이용 기간과 결제일을 확인하세요.", official=false) }
        if (channel == "apple") return Page("https://apps.apple.com/account/subscriptions","Apple 계정에 로그인한 뒤 해당 구독을 선택하세요.")
        if (channel == "google") return Page("https://play.google.com/store/account/subscriptions","구독한 Google 계정으로 로그인한 뒤 해당 구독을 선택하세요.")
        return service?.managementPage ?: safeUrl(service?.source)?.let { Page(it,"로그인 후 계정 또는 구독 메뉴에서 이용 기간을 확인하세요.") }
    }
    fun json(): JSONObject = JSONObject(extras).apply {
        put("id",id); put("name",name); put("amount",amount); put("yearly",yearly); put("billingDate",billingDate.toString())
        put("serviceID",serviceID);put("planName",planName);put("category",category);put("currency",currency);put("channel",channel)
        put("freeStartDate",freeStartDate?.toString());put("freeEndDate",freeEndDate?.toString());put("discountEndDate",discountEndDate?.toString())
        put("promotionVersion",1);put("afterAmount",afterAmount);put("amountEffectiveDate",amountEffectiveDate?.toString())
        put("managementURL",managementURL);put("reminderOverride",reminderOverride?.json());put("status",status);put("cancellationEffectiveDate",cancellationEffectiveDate?.toString())
    }
    companion object {
        fun parse(j: JSONObject): Subscription {
            val amount = j.getDouble("amount")
            require(amount.isFinite() && amount in 0.0..1_000_000_000.0)
            val after = j.number("afterAmount")
            require(after == null || after in 0.0..1_000_000_000.0)
            return Subscription(j.getString("id"),j.getString("name"),amount,j.optBoolean("yearly"),LocalDate.parse(j.getString("billingDate")),
                j.string("serviceID"),j.string("planName"),j.string("category"),j.string("currency") ?: "KRW",j.string("channel") ?: "unknown",
                j.date("freeStartDate"),j.date("freeEndDate"),j.date("discountEndDate"),after,j.date("amountEffectiveDate"),j.string("managementURL"),
                j.optJSONObject("reminderOverride")?.let(ReminderPrefs::parse),j.string("status") ?: "active",j.date("cancellationEffectiveDate"),j.toString())
        }
    }
}
data class ReminderEvent(val id: String, val subscriptionID: String, val fire: LocalDateTime, val title: String, val body: String)
object ReminderPlanner {
    fun events(items: List<Subscription>, defaults: ReminderPrefs, now: LocalDateTime, limit: Int = 60): List<ReminderEvent> {
        val result = mutableListOf<ReminderEvent>()
        for (item in items) {
            val prefs = item.reminderOverride ?: defaults
            if (!prefs.enabled) continue
            val days = prefs.validDays.filter { item.yearly || it != 30 }
            fun add(date: LocalDate, lead: Int, kind: String, title: String, body: String) {
                val fire = date.minusDays(lead.toLong()).atTime(prefs.hour,prefs.minute)
                if (fire > now && item.isEffective(fire.toLocalDate()) && item.isEffective(date)) result += ReminderEvent("${item.id}.$kind.$date.$lead", item.id,fire,title,body)
            }
            for (payment in item.payments(now.toLocalDate(), now.toLocalDate().plusYears(3))) for (lead in days) {
                add(payment.date,lead,"payment","${item.name} ${if (lead == 0) "오늘 결제 예정" else "결제 ${lead}일 전"} · ${money(payment.amount,item.currency)}","이용 중인 혜택을 확인하고 계속 사용할지 결정해보세요.")
            }
            for ((label,date) in listOf("무료체험 종료" to item.freeEndDate,"할인 종료" to item.discountEndDate)) if (date != null) for (lead in days) {
                add(date,lead,label,"${item.name} $label ${if(lead == 0) "당일" else "${lead}일 전"}", item.afterAmount?.let { "종료 후 금액 ${money(it,item.currency)}. 적용일과 첫 결제일을 확인하세요." } ?: "종료 후 금액과 첫 결제일을 확인하세요.")
            }
        }
        return result.sortedWith(compareBy({it.fire},{it.id})).take(limit.coerceAtLeast(0))
    }
}

fun Subscription.correctReceiptService(catalog: List<Service>): Subscription {
    val match=catalog.firstOrNull {service -> (listOf(service.name,service.displayName)+service.aliases).any {it.equals(name.trim(),ignoreCase=true)}}
    return copy(serviceID=match?.id,category=match?.category)
}
