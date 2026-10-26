package com.example.mymemberships

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.repeatOnLifecycle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import java.time.LocalDate
import java.time.temporal.ChronoUnit

val Yellow = Color(0xFFFFD629)
val Lime = Color(0xFFD9F092)
val Olive = Color(0xFF596F14)
val Ink = Color(0xFF2E380F)
val Cream = Color(0xFFFFFEF5)
val Muted = Color(0xFF686E5E)
class MainActivity: ComponentActivity() {
    private var incoming by mutableStateOf<String?>(null)
    private lateinit var store: MembershipStore
    private lateinit var receiptState: ReceiptState
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        incoming=intent.getStringExtra("subscriptionID")
        val testing = BuildConfig.DEBUG && intent.getBooleanExtra("testing",false)
        store=MembershipStore(applicationContext,testing)
        receiptState=androidx.lifecycle.ViewModelProvider(this)[ReceiptState::class.java]
        if(!testing) store.refreshReminders()
        setContent {
            MaterialTheme(colorScheme=lightColorScheme(primary=Olive,onPrimary=Color.White,primaryContainer=Yellow,onPrimaryContainer=Ink,secondary=Olive,secondaryContainer=Lime,background=Cream,surface=Color.White,onSurface=Ink,onBackground=Ink)) {
                MembershipApp(store,incoming,receiptState) { incoming=null }
            }
        }
    }
    override fun onNewIntent(intent: Intent) { super.onNewIntent(intent);setIntent(intent);incoming=intent.getStringExtra("subscriptionID") }
    override fun onResume() { super.onResume();if(::store.isInitialized) {store.refreshToday();store.refreshReminders()} }
}
@Composable fun MembershipApp(store: MembershipStore, incoming: String?, receiptState: ReceiptState, consumed: () -> Unit) {
    var screen by rememberSaveable { mutableStateOf("home") }
    var itemID by rememberSaveable { mutableStateOf<String?>(null) }
    var serviceID by rememberSaveable { mutableStateOf<String?>(null) }
    val item=store.items.firstOrNull { it.id == itemID }
    val service=store.catalog.firstOrNull { it.id == serviceID }
    LaunchedEffect(incoming) { if(incoming != null) { itemID=incoming;screen=if(store.items.any { it.id == incoming }) "detail" else "home";consumed() } }
    fun back() { screen=when(screen) { "edit","reminder" -> if(item != null) "detail" else "home"; "new" -> "picker";else -> "home" };if(screen=="home") receiptState.clear() }
    BackHandler(screen != "home") { back() }
    val open: (Subscription) -> Unit = { itemID=it.id;screen="detail" }
    val lifecycleOwner=LocalLifecycleOwner.current
    LaunchedEffect(store,lifecycleOwner) {lifecycleOwner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {while(true) {store.refreshToday();kotlinx.coroutines.delay(30_000)}}}
    when(screen) {
        "home" -> HomeScreen(store,{screen="picker"},{screen="receipt"},open,{screen="defaults"},{screen="compare"})
        "picker" -> ServicePicker(store.catalog,{back()}) { s -> serviceID=s?.id;screen="new" }
        "new" -> {
            val seed=remember(serviceID) { seed(service) }
            EditorScreen(seed,service,{back()},save={ if(store.save(it)) open(it) },newEntry=true,blankInitialAmount=true)
        }
        "edit" -> if(item != null) EditorScreen(item,store.service(item),{back()},save={ if(store.save(it)) open(it) }) else HomeScreen(store,{screen="picker"},{screen="receipt"},open,{screen="defaults"},{screen="compare"})
        "detail" -> if(item != null) DetailScreen(item,store,{screen="home"},{screen="edit"},{screen="reminder"},{if(store.delete(item.id)) screen="home"}) else LaunchedEffect(Unit) { screen="home" }
        "reminder" -> if(item != null) ReminderScreen(item.reminderOverride ?: store.defaults,item.yearly,"결제 전 알림받기",{back()},save={ if(store.save(item.copy(reminderOverride=it))) screen="detail" },onUseDefaults={if(store.save(item.copy(reminderOverride=null))) screen="detail"},usingDefaults=item.reminderOverride==null)
        "defaults" -> ReminderScreen(store.defaults,true,"전체 알림 설정",{back()},save={ if(store.saveDefaults(it)) screen="home" })
        "receipt" -> ReceiptScreen(store.catalog,receiptState,{receiptState.clear();screen="home"}) { if(store.save(it)) {receiptState.clear();open(it)} }
        "compare" -> CompareScreen(store,{screen="home"},open)
    }
    if(store.notificationError != null) AlertDialog(onDismissRequest={store.dismissNotificationError()},title={Text("알림 예약 안내")},text={Text(store.notificationError!!)},confirmButton={TextButton(onClick={store.refreshReminders()}) {Text("다시 시도")}},dismissButton={TextButton(onClick={store.dismissNotificationError()}) {Text("닫기")}})
    if(store.error != null) AlertDialog(onDismissRequest={}, title={Text("저장 안내")},text={Text(store.error!!)}, confirmButton={TextButton(onClick={store.reload()}) {Text("다시 확인")}})
}
fun seed(service: Service?): Subscription {
    val p=service?.plans?.firstOrNull()
    return Subscription(name=service?.name ?: "",serviceID=service?.id,category=service?.category,planName=p?.name,amount=p?.amount ?: 0.0,yearly=p?.yearly ?: false,currency=p?.currency ?: "KRW",channel=when { p?.channel?.contains("App Store")==true -> "apple";p?.channel?.contains("Google")==true -> "google";p?.channel?.contains("웹")==true -> "web";else -> "unknown" })
}
@OptIn(ExperimentalMaterial3Api::class)
@Composable fun Shell(title: String,back: (() -> Unit)? = null,action: @Composable () -> Unit = {},content: @Composable (PaddingValues) -> Unit) {
    Scaffold(modifier=Modifier.imePadding(),containerColor=Cream,topBar={TopAppBar(title={Text(title,fontWeight=FontWeight.Bold)},colors=TopAppBarDefaults.topAppBarColors(containerColor=Cream),navigationIcon={if(back != null) IconButton(onClick=back) {Icon(Icons.AutoMirrored.Filled.ArrowBack,"뒤로")}},actions={action()})},content=content)
}
@Composable fun SurfaceCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) { Column(modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(Color.White).padding(20.dp),verticalArrangement=Arrangement.spacedBy(12.dp),content=content) }
@Composable fun SectionTitle(text: String) { Text(text,fontSize=19.sp,fontWeight=FontWeight.Bold) }
@Composable fun Hint(text: String) { Text(text,color=Muted,fontSize=13.sp,lineHeight=20.sp) }
@Composable fun ServiceLogo(serviceID: String?,size: Int=44) {
    val resource=remember(serviceID) { logoResource(serviceID) }
    Box(Modifier.size(size.dp).clip(RoundedCornerShape((size/4).dp)).background(Cream),contentAlignment=Alignment.Center) {
        if(resource != 0) Image(painterResource(resource),null,Modifier.fillMaxSize().padding(4.dp)) else Icon(Icons.Default.CreditCard,null,tint=Olive,modifier=Modifier.size((size*0.65).dp))
    }
}
@Composable fun HomeScreen(store: MembershipStore,add: () -> Unit,receipt: () -> Unit,open: (Subscription) -> Unit,reminders: () -> Unit,compare: () -> Unit) {
    val today=store.today
    val active=store.items.filter { it.status != "cancelled" }
    val upcoming=active.mapNotNull { s -> s.upcoming(today)?.let { s to it } }.sortedWith(compareBy({it.second.date},{it.first.name}))
    Shell("내 구독",action={IconButton(onClick=reminders) { Icon(Icons.Default.NotificationsNone,"전체 알림 설정") }}) { padding ->
        LazyColumn(Modifier.fillMaxSize().padding(padding).testTag("home-list"),contentPadding=PaddingValues(20.dp),verticalArrangement=Arrangement.spacedBy(18.dp)) {
            item { Hint("매달 나가는 비용, 한눈에") }
            item {
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(Brush.linearGradient(listOf(Yellow,Color(0xFFFFED87)))).padding(24.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
                    Text("월 환산 총액",fontWeight=FontWeight.Medium,color=Ink)
                    val currencies=active.map { it.currency }.distinct().ifEmpty { listOf("KRW") }
                    for(currency in currencies) {
                        val values=active.filter { it.currency == currency }
                        val monthly=values.sumOf { it.monthly(today) }
                        Text(money(monthly,currency),fontSize=34.sp,fontWeight=FontWeight.Bold,color=Ink)
                        Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) { Text("연 환산",color=Ink);Text(money(monthly*12,currency),fontWeight=FontWeight.SemiBold,color=Ink) }
                        Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween) { Text("이번 달 결제 예정",color=Ink);Text(money(values.sumOf { s -> s.thisMonth(today).sumOf { it.amount } },currency),fontWeight=FontWeight.SemiBold,color=Ink) }
                    }
                    if(active.any { it.yearly && it.thisMonth(today).isNotEmpty() }) Text("이번 달에는 연간 구독 갱신 금액이 포함돼요.",fontSize=12.sp,color=Ink)
                    Text("결제 내역 연동이 아닌, 등록한 일정 기준 예상액이에요.",fontSize=12.sp,color=Ink)
                }
            }
            item { Button(onClick=add,modifier=Modifier.fillMaxWidth().height(58.dp),shape=RoundedCornerShape(18.dp),colors=ButtonDefaults.buttonColors(containerColor=Yellow,contentColor=Ink)) { Icon(Icons.Default.AddCircle,null);Spacer(Modifier.width(10.dp));Text("구독 추가하기",fontSize=18.sp,fontWeight=FontWeight.Bold) } }
            item {
                Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(Lime).clickable(onClick=receipt).padding(20.dp),verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(14.dp)) {
                    Icon(Icons.Default.DocumentScanner,null,Modifier.size(34.dp),tint=Ink)
                    Column(Modifier.weight(1f)) {Text("사진·영수증으로 자동 입력",fontWeight=FontWeight.Bold,fontSize=17.sp);Text("사진을 선택하면 구독 정보를 채워줘요",fontSize=12.sp,color=Ink)}
                    Icon(Icons.Default.ChevronRight,null,tint=Ink)
                }
            }
            item { Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween,verticalAlignment=Alignment.CenterVertically) {SectionTitle("다가오는 결제일");Text("빠른 날짜순",fontSize=12.sp,color=Olive,modifier=Modifier.clip(RoundedCornerShape(20.dp)).background(Lime).padding(10.dp,5.dp))} }
            if(active.isEmpty()) item { SurfaceCard { Icon(Icons.Default.CreditCard,null,tint=Olive,modifier=Modifier.size(32.dp));Text("첫 구독을 등록해 보세요",fontWeight=FontWeight.Bold);Hint("서비스를 선택하거나 영수증을 불러오면 쉽게 시작할 수 있어요.") } }
            items(upcoming,key={it.first.id}) { (s,p) ->
                SurfaceCard(Modifier.clickable { open(s) }) {
                    Row(verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(14.dp)) {
                        ServiceLogo(s.serviceID)
                        Column(Modifier.weight(1f),verticalArrangement=Arrangement.spacedBy(4.dp)) {Text(s.name,fontWeight=FontWeight.Bold);Text("${p.date.monthValue}월 ${p.date.dayOfMonth}일 · ${if(s.yearly) "연간" else "월간"}",color=Muted,fontSize=13.sp)}
                        Column(horizontalAlignment=Alignment.End) {Text(money(p.amount,s.currency),fontWeight=FontWeight.Bold);val days=ChronoUnit.DAYS.between(today,p.date);Text(when(days) {0L->"오늘";1L->"내일";else->"${days}일 후"},color=Olive,fontSize=12.sp)}
                    }
                }
            }
            items(active.filter { it.upcoming(today)==null },key={it.id}) { s -> SurfaceCard(Modifier.clickable {open(s)}) { Row(verticalAlignment=Alignment.CenterVertically) {ServiceLogo(s.serviceID);Spacer(Modifier.width(12.dp));Column {Text(s.name,fontWeight=FontWeight.Bold);Hint("다음 결제 일정을 확인해 주세요")}} } }
            if(active.isNotEmpty()) item { OutlinedButton(onClick=compare,modifier=Modifier.fillMaxWidth()) {Icon(Icons.Default.Layers,null);Spacer(Modifier.width(8.dp));Text("멤버십 혜택 비교")} }
            item { Spacer(Modifier.height(12.dp)) }
        }
    }
}
@Composable fun ServicePicker(catalog: List<Service>,back: () -> Unit,choose: (Service?) -> Unit) {
    var query by rememberSaveable { mutableStateOf("") };var category by rememberSaveable { mutableStateOf("전체") }
    Shell("구독 추가",back) { padding ->
        Column(Modifier.padding(padding).padding(horizontal=20.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
            OutlinedTextField(query,{query=it},label={Text("서비스 이름 검색")},placeholder={Text("유튜브, 넷플릭스, 쿠팡…")},leadingIcon={Icon(Icons.Default.Search,null)},trailingIcon={if(query.isNotEmpty()) IconButton(onClick={query=""}) {Icon(Icons.Default.Close,"검색어 지우기")}},singleLine=true,modifier=Modifier.fillMaxWidth())
            Choice("카테고리",category,listOf("전체")+catalog.map { it.category }.distinct()) { category=it }
            val result=catalog.filter { (category=="전체" || it.category==category) && it.matches(query) }
            LazyColumn(verticalArrangement=Arrangement.spacedBy(10.dp),contentPadding=PaddingValues(bottom=28.dp)) {
                if(result.isEmpty()) item { Hint("일치하는 서비스가 없어요. 직접 등록해 주세요.") }
                items(result,key={it.id}) { s -> SurfaceCard(Modifier.clickable {choose(s)}) {Row(verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(14.dp)) {ServiceLogo(s.id);Column(Modifier.weight(1f)) {Text(s.name,fontWeight=FontWeight.SemiBold);Hint(s.category)};Icon(Icons.Default.ChevronRight,null)}} }
                item { OutlinedButton(onClick={choose(null)},modifier=Modifier.fillMaxWidth().heightIn(min=52.dp)) {Icon(Icons.Default.Edit,null);Spacer(Modifier.width(8.dp));Text("목록에 없는 서비스 직접 입력")} }
            }
        }
    }
}
@Composable fun DetailScreen(item: Subscription,store: MembershipStore,back: () -> Unit,edit: () -> Unit,reminder: () -> Unit,deleted: () -> Unit) {
    val service=store.service(item);val today=store.today;val next=item.upcoming(today)
    var delete by remember { mutableStateOf(false) }
    val context=LocalContext.current
    Shell("구독 상세",back,action={TextButton(onClick=edit) {Text("수정",fontWeight=FontWeight.Bold)}}) { padding ->
        LazyColumn(Modifier.padding(padding).testTag("detail-list"),contentPadding=PaddingValues(20.dp),verticalArrangement=Arrangement.spacedBy(18.dp)) {
            item { Row(verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(16.dp)) {ServiceLogo(item.serviceID,62);Column {Text(item.name,fontSize=24.sp,fontWeight=FontWeight.Bold);item.planName?.let { Hint(it) }}} }
            item { SurfaceCard {
                Text("다음 결제일",color=Muted)
                Row(verticalAlignment=Alignment.CenterVertically) {
                    Text(next?.date?.let { "${it.year}. ${it.monthValue}. ${it.dayOfMonth}." } ?: "일정 없음",fontSize=27.sp,fontWeight=FontWeight.Bold,color=Olive,modifier=Modifier.weight(1f))
                    TextButton(onClick={showDatePicker(context,next?.date ?: today,today) {store.save(item.copy(billingDate=it))}},modifier=Modifier.semantics {contentDescription="다음 결제일 수정"}) {Icon(Icons.Default.EditCalendar,null,Modifier.size(18.dp));Spacer(Modifier.width(5.dp));Text("수정")}
                }
                Text(money(next?.amount ?: 0.0,item.currency),fontSize=30.sp,fontWeight=FontWeight.Bold)
                Hint(if(item.yearly) "연간 결제" else "매월 결제")
                HorizontalDivider(color=Cream)
                Row(Modifier.fillMaxWidth().clickable(onClick=reminder).padding(vertical=6.dp),verticalAlignment=Alignment.CenterVertically) {Icon(Icons.Default.NotificationsNone,null,tint=Olive);Spacer(Modifier.width(8.dp));Column(Modifier.weight(1f)) {Text("결제 전 알림받기",fontWeight=FontWeight.SemiBold);val p=item.reminderOverride ?: store.defaults;Hint(if(p.enabled) p.validDays.filter { item.yearly || it!=30 }.joinToString(" · ") { if(it==0) "당일" else "${it}일 전" }+" · %02d:%02d".format(p.hour,p.minute) else "설정 안 함")};Icon(Icons.Default.ChevronRight,null)}
                if(item.yearly) Hint("월 환산 비용  ${money(item.monthly(today),item.currency)}")
            } }
            item { SurfaceCard {
                val page=item.subscriptionPage(service)
                if(page != null) {Text("구독 페이지에서 이용 기간 확인",fontWeight=FontWeight.Bold);Hint(page.directions);LinkButton(if(page.official) "구독 중인 웹페이지 열기" else "저장한 구독 페이지 열기",page.url)} else {Text("구독 페이지",fontWeight=FontWeight.Bold);Hint("수정 화면에서 관리 URL을 추가할 수 있어요.")}
                Hint("이용 기간은 로그인한 서비스에서 확인해 주세요.")
            } }
            if(item.freeEndDate != null || item.discountEndDate != null || item.amountEffectiveDate != null) item { SurfaceCard {
                SectionTitle("체험·할인 안내")
                item.freeEndDate?.let {Hint("무료체험 종료일  $it")};item.discountEndDate?.let {Hint("할인 종료일  $it")}
                if(item.afterAmount != null) Hint("종료 후 금액  ${money(item.afterAmount,item.currency)}")
                item.amountEffectiveDate?.let {Hint("금액 적용일  $it")}
                Hint("체험 종료일과 첫 유료 결제일은 다를 수 있어요.")
            } }
            item { SectionTitle("내 멤버십 혜택") }
            val benefits=item.benefits(service)
            if(benefits.isEmpty()) item {SurfaceCard {Hint("확인된 혜택 안내를 준비하고 있어요.")}}
            items(benefits,key={it.id}) { b -> SurfaceCard {
                Row(horizontalArrangement=Arrangement.spacedBy(10.dp)) {Icon(Icons.Default.CheckCircle,null,tint=Olive,modifier=Modifier.size(20.dp));Column {Text(b.title,fontWeight=FontWeight.SemiBold);if(b.conditions.isNotBlank()) Hint(b.conditions)}}
            } }
            service?.benefitsPage?.let { page -> item {LinkButton("혜택 자세히 보기",page.url);page.checkedAt?.let {Hint("정보 확인일 $it · 최신 조건은 공식 페이지에서 확인해 주세요.")}} }
            item {TextButton(onClick={delete=true},modifier=Modifier.fillMaxWidth()) {Text("구독 삭제",color=Color(0xFFAA4339))};Hint("앱의 기록을 삭제해도 실제 서비스 구독은 해지되지 않아요.")}
        }
    }
    if(delete) AlertDialog(onDismissRequest={delete=false},title={Text("구독을 삭제할까요?")},text={Text("이 기기의 기록과 예약 알림을 삭제해요. 실제 구독은 해지되지 않아요.")},confirmButton={TextButton(onClick={delete=false;deleted()}) {Text("삭제")}},dismissButton={TextButton(onClick={delete=false}) {Text("취소")}})
}
@Composable fun LinkButton(label: String,url: String) {
    val context=LocalContext.current
    var failed by remember {mutableStateOf(false)}
    OutlinedButton(onClick={runCatching { context.startActivity(Intent(Intent.ACTION_VIEW,android.net.Uri.parse(safeUrl(url) ?: return@OutlinedButton))) }.onFailure {failed=true}},modifier=Modifier.fillMaxWidth()) {Text(label);Spacer(Modifier.width(8.dp));Icon(Icons.Default.OpenInNew,null,Modifier.size(17.dp))}
    if(failed) Hint("링크를 열 수 없어요. 브라우저 설치 여부를 확인해 주세요.")
}
@Composable fun CompareScreen(store: MembershipStore,back: () -> Unit,open: (Subscription) -> Unit) {
    var category by rememberSaveable {mutableStateOf("video")}
    val entries=store.items.filter {it.status != "cancelled"}.flatMap {s -> s.benefits(store.service(s)).filter {it.category==category}.map {s to it}}
    Shell("멤버십 혜택 비교",back) {padding -> LazyColumn(Modifier.padding(padding),contentPadding=PaddingValues(20.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
        item {Choice("혜택 분류",benefitCategories.getValue(category),benefitCategories.values.toList()) {label -> category=benefitCategories.entries.first {it.value==label}.key}}
        item {Hint("${benefitCategories[category]} 혜택이 있는 멤버십 ${entries.map {it.first.id}.distinct().size}개예요. 비슷한 혜택의 제공 내용과 가입 조건을 비교해 보세요.")}
        if(entries.isEmpty()) item {SurfaceCard {Hint("이 분류의 등록된 혜택이 없어요.")}}
        items(entries,key={it.first.id+it.second.id}) {(s,b) -> SurfaceCard {
            Row(Modifier.clickable {open(s)},verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.spacedBy(10.dp)) {ServiceLogo(s.serviceID);Column {Text(s.name,fontWeight=FontWeight.Bold);Hint("전체 멤버십 요금 ${money(s.amount,s.currency)} / ${if(s.yearly) "년" else "월"}")}}
            Text(b.title,fontWeight=FontWeight.SemiBold);if(b.conditions.isNotBlank()) Hint(b.conditions)
            b.sourceURL?.let {LinkButton("공식 혜택 안내",it)}
        }}
        item {Hint("같은 분류여도 제공 내용은 다를 수 있어요. 표시 금액은 개별 혜택 가격이 아닌 전체 멤버십 요금이에요.")}
    }}
}
