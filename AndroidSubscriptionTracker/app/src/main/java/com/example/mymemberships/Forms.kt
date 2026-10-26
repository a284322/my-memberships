package com.example.mymemberships

import android.Manifest
import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import java.time.*

fun showDatePicker(context: Context,date: LocalDate,min: LocalDate? = null,choose: (LocalDate) -> Unit) {
    DatePickerDialog(context,{_,y,m,d -> choose(LocalDate.of(y,m+1,d))},date.year,date.monthValue-1,date.dayOfMonth).apply {
        min?.let {datePicker.minDate=it.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()}
    }.show()
}
@Composable fun Choice(label: String,value: String,values: List<String>,onChange: (String) -> Unit) {
    var expanded by remember {mutableStateOf(false)}
    Box {OutlinedButton(onClick={expanded=true},modifier=Modifier.fillMaxWidth()) {Text("$label: $value",modifier=Modifier.weight(1f));Icon(Icons.Default.ExpandMore,null)}
        DropdownMenu(expanded,onDismissRequest={expanded=false}) {values.forEach {v -> DropdownMenuItem(text={Text(v)},onClick={expanded=false;onChange(v)})}}
    }
}
@Composable fun DateField(label: String,value: LocalDate,change: (LocalDate) -> Unit) {
    val context=LocalContext.current
    OutlinedButton(onClick={showDatePicker(context,value,choose=change)},modifier=Modifier.fillMaxWidth()) {Icon(Icons.Default.CalendarMonth,null);Spacer(Modifier.width(8.dp));Text("$label: $value")}
}
@Composable fun OptionalDate(label: String,value: String,change: (String) -> Unit) {
    Row(verticalAlignment=Alignment.CenterVertically) {Checkbox(value.isNotBlank(),{change(if(it) LocalDate.now().toString() else "")});Text(label)}
    if(value.isNotBlank()) DateField(label,LocalDate.parse(value)) {change(it.toString())}
}
val channels=linkedMapOf("unknown" to "모름","web" to "웹","google" to "Google Play","apple" to "Apple App Store","other" to "기타")
@Composable fun EditorScreen(initial: Subscription,service: Service?,back: () -> Unit,save: (Subscription) -> Unit,receipt: Boolean = false,warnings: List<String> = emptyList(),header: @Composable () -> Unit = {},savingAllowed: Boolean = true,confirmationToken: Int = 0,receiptCatalog: List<Service> = emptyList(),newEntry: Boolean = false,blankInitialAmount: Boolean = false) {
    var name by rememberSaveable(initial.id) {mutableStateOf(initial.name)}
    var plan by rememberSaveable(initial.id) {mutableStateOf(initial.planName ?: "")}
    var amount by rememberSaveable(initial.id) {mutableStateOf(if(initial.amount==0.0 && blankInitialAmount) "" else initial.amount.toString().removeSuffix(".0"))}
    var currency by rememberSaveable(initial.id) {mutableStateOf(initial.currency)}
    var yearly by rememberSaveable(initial.id) {mutableStateOf(initial.yearly)}
    var date by rememberSaveable(initial.id) {mutableStateOf(initial.billingDate.toString())}
    var channel by rememberSaveable(initial.id) {mutableStateOf(initial.channel)}
    var freeStart by rememberSaveable(initial.id) {mutableStateOf(initial.freeStartDate?.toString() ?: "")}
    var freeEnd by rememberSaveable(initial.id) {mutableStateOf(initial.freeEndDate?.toString() ?: "")}
    var discountEnd by rememberSaveable(initial.id) {mutableStateOf(initial.discountEndDate?.toString() ?: "")}
    var after by rememberSaveable(initial.id) {mutableStateOf(initial.afterAmount?.toString()?.removeSuffix(".0") ?: "")}
    var effective by rememberSaveable(initial.id) {mutableStateOf(initial.amountEffectiveDate?.toString() ?: "")}
    var url by rememberSaveable(initial.id) {mutableStateOf(initial.managementURL ?: "")}
    var advanced by rememberSaveable {mutableStateOf(false)}
    var confirmed by remember {mutableStateOf(false)}
    val valuesKey=listOf(name,plan,amount,currency,yearly,date,channel,freeStart,freeEnd,discountEnd,after,effective,url)
    LaunchedEffect(valuesKey,confirmationToken) {confirmed=false}
    val error=when {
        name.isBlank()->"서비스 이름을 입력해 주세요."
        validAmount(amount)==null -> "금액을 올바르게 입력해 주세요."
        freeStart.isNotBlank() && freeEnd.isNotBlank() && freeEnd < freeStart -> "무료체험 종료일은 시작일 이후로 선택해 주세요."
        freeStart.isBlank() != freeEnd.isBlank() -> "무료체험 시작일과 종료일을 함께 입력해 주세요."
        after.isNotBlank() && validAmount(after)==null -> "종료 후 금액을 확인해 주세요."
        after.isNotBlank() != effective.isNotBlank() -> "종료 후 금액과 금액 적용일을 함께 입력해 주세요."
        effective.isNotBlank() && (freeEnd.isNotBlank() && effective<=freeEnd || discountEnd.isNotBlank() && effective<=discountEnd) -> "금액 적용일은 체험·할인 종료일 다음 날부터 선택해 주세요."
        url.isNotBlank() && safeUrl(url)==null -> "관리 URL은 http 또는 https 주소로 입력해 주세요."
        else -> null
    }
    val submit: () -> Unit = { if(savingAllowed && error==null && (!receipt || confirmed)) save(initial.copy(name=name.trim(),planName=plan.trim().ifBlank {null},amount=validAmount(amount)!!,currency=currency,yearly=yearly,billingDate=LocalDate.parse(date),channel=channel,freeStartDate=freeStart.takeIf {it.isNotBlank()}?.let(LocalDate::parse),freeEndDate=freeEnd.takeIf {it.isNotBlank()}?.let(LocalDate::parse),discountEndDate=discountEnd.takeIf {it.isNotBlank()}?.let(LocalDate::parse),afterAmount=after.takeIf {it.isNotBlank()}?.let(::validAmount),amountEffectiveDate=effective.takeIf {it.isNotBlank()}?.let(LocalDate::parse),managementURL=url.trim().ifBlank {null}).let {if(receipt) it.correctReceiptService(receiptCatalog) else it}) }
    Shell(if(receipt) "자동 입력 확인" else if(newEntry) "구독 등록" else "구독 수정",back,action={TextButton(onClick=submit,enabled=savingAllowed && error==null && (!receipt || confirmed)) {Text("저장",fontWeight=FontWeight.Bold)}}) {padding ->
        LazyColumn(Modifier.padding(padding).testTag("form"),contentPadding=PaddingValues(20.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
            item {header()}
            if(service!=null) item {Row(verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(12.dp)) {ServiceLogo(service.id,52);Text(service.name,fontWeight=FontWeight.Bold)}}
            if(warnings.isNotEmpty()) item {SurfaceCard {Text("저장 전 확인해 주세요",fontWeight=FontWeight.Bold);warnings.forEach {Hint(it)}}}
            item {OutlinedTextField(name,{name=it},label={Text("서비스 이름")},singleLine=true,modifier=Modifier.fillMaxWidth())}
            if(service?.plans?.isNotEmpty()==true) item {
                val labels=service.plans.map {"${it.name} · ${money(it.amount,it.currency)} · ${it.channel}${if(it.yearly) " · 연간" else ""}"}
                Choice("플랜 선택","직접 입력 또는 선택",labels) {label -> val p=service.plans[labels.indexOf(label)];plan=p.name;amount=p.amount.toString().removeSuffix(".0");currency=p.currency;yearly=p.yearly;channel=when {p.channel.contains("App Store")->"apple";p.channel.contains("Google")->"google";p.channel.contains("웹")->"web";else->"unknown"}}
                Hint("가입 경로·플랜에 따라 요금이 달라요. 실제 결제 금액으로 수정해 주세요.")
            }
            item {OutlinedTextField(plan,{plan=it},label={Text("플랜 이름 (선택)")},singleLine=true,modifier=Modifier.fillMaxWidth())}
            item {OutlinedTextField(amount,{amount=it},label={Text("구독 금액")},singleLine=true,keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),modifier=Modifier.fillMaxWidth())}
            item {Choice("통화",currency,listOf("KRW","USD")) {currency=it}}
            item {Choice("결제 주기",if(yearly) "연간" else "월간",listOf("월간","연간")) {yearly=it=="연간"}}
            item {DateField("다음 결제일",LocalDate.parse(date)) {date=it.toString()}}
            item {Choice("가입·결제 경로",channels[channel] ?: "모름",channels.values.toList()) {label -> channel=channels.entries.first {it.value==label}.key}}
            item {OutlinedTextField(url,{url=it},label={Text("구독 관리 URL (선택)")},keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Uri),modifier=Modifier.fillMaxWidth());Hint("직접 등록한 서비스도 로그인 후 확인할 페이지를 저장할 수 있어요.")}
            item {TextButton(onClick={advanced=!advanced}) {Text(if(advanced) "체험·할인 설정 접기" else "무료체험·할인 기간 설정 (선택)")}}
            if(advanced) {
                item {OptionalDate("무료체험 시작일",freeStart) {freeStart=it}}
                item {OptionalDate("무료체험 종료일",freeEnd) {freeEnd=it}}
                item {OptionalDate("할인 종료일",discountEnd) {discountEnd=it}}
                item {OutlinedTextField(after,{after=it},label={Text("종료 후 금액 (선택)")},keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),modifier=Modifier.fillMaxWidth())}
                item {OptionalDate("금액 적용일",effective) {effective=it};Hint("무료체험 종료일과 첫 유료 결제일은 별도로 설정해 주세요.")}
            }
            if(receipt) item {Row(verticalAlignment=Alignment.CenterVertically) {Checkbox(confirmed,{confirmed=it},modifier=Modifier.testTag("receipt-confirm"));Text("금액·주기·다음 결제일을 확인했어요")}}
            if(error!=null && (name.isNotBlank() || amount.isNotBlank())) item {Hint(if(name.isBlank()) "서비스 이름을 입력해 주세요." else error)}
            item {Button(enabled=savingAllowed && error==null && (!receipt || confirmed),onClick=submit,modifier=Modifier.fillMaxWidth().height(54.dp),colors=ButtonDefaults.buttonColors(containerColor=Yellow,contentColor=Ink)) {Text("구독 저장",fontWeight=FontWeight.Bold)}}
            item {Spacer(Modifier.height(24.dp))}
        }
    }
}
@Composable fun ReminderScreen(initial: ReminderPrefs,yearly: Boolean,title: String,back: () -> Unit,save: (ReminderPrefs) -> Unit,onUseDefaults: (() -> Unit)? = null,usingDefaults: Boolean = false) {
    val context=LocalContext.current
    var enabled by rememberSaveable {mutableStateOf(initial.enabled)}
    var days by rememberSaveable {mutableStateOf(initial.validDays.filter {yearly || it!=30})}
    var hour by rememberSaveable {mutableIntStateOf(initial.hour)};var minute by rememberSaveable {mutableIntStateOf(initial.minute)}
    var denied by remember {mutableStateOf(!ReminderScheduler.allowed(context))}
    val permission=rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {allowed -> denied=!allowed;enabled=allowed}
    Shell(title,back) {padding -> LazyColumn(Modifier.padding(padding).testTag("reminders"),contentPadding=PaddingValues(20.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
        item {SurfaceCard {
            Row(verticalAlignment=Alignment.CenterVertically) {Column(Modifier.weight(1f)) {Text("결제 전 알림",fontWeight=FontWeight.Bold);Hint("추천: 3일 전 오전 9시")};Switch(enabled,{on -> if(!on) enabled=false else if(Build.VERSION.SDK_INT>=33 && !ReminderScheduler.allowed(context)) permission.launch(Manifest.permission.POST_NOTIFICATIONS) else {enabled=true;denied=!ReminderScheduler.allowed(context)}})}
            Hint(if(title=="전체 알림 설정") "개별 설정이 없는 구독에 적용돼요. 연간 구독은 30일 전도 선택할 수 있어요." else "이 구독에만 적용되는 설정이에요.")
        }}
        if(denied) item {SurfaceCard {Hint("알림 권한이 꺼져 있어요. 휴대폰 설정에서 알림을 허용해 주세요.");TextButton(onClick={context.startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE,context.packageName))}) {Text("알림 설정 열기")}}}
        item {SectionTitle("알림 받을 날짜")}
        if(onUseDefaults!=null) item {Hint(if(usingDefaults) "현재 전체 기본 설정을 사용 중이에요." else "현재 이 구독의 개별 설정을 사용 중이에요.");OutlinedButton(onClick=onUseDefaults,modifier=Modifier.fillMaxWidth()) {Text("전체 기본 설정 사용")}}
        for(day in if(yearly) listOf(0,1,3,7,30) else listOf(0,1,3,7)) item {Row(verticalAlignment=Alignment.CenterVertically) {Checkbox(day in days,{selected -> days=if(selected) (days+day).distinct() else days-day});Text(if(day==0) "결제 당일" else "${day}일 전")}}
        item {OutlinedButton(onClick={TimePickerDialog(context,{_,h,m ->hour=h;minute=m},hour,minute,true).show()},modifier=Modifier.fillMaxWidth()) {Text("알림 시간  %02d:%02d".format(hour,minute))}}
        item {Hint("절전 모드나 기기 설정에 따라 알림이 지정한 시간보다 늦게 도착할 수 있어요.")}
        item {Button(onClick={save(ReminderPrefs(enabled,days,hour,minute))},enabled=!enabled || days.isNotEmpty(),modifier=Modifier.fillMaxWidth(),colors=ButtonDefaults.buttonColors(containerColor=Yellow,contentColor=Ink)) {Text("알림 설정 저장")}}
    }}
}
