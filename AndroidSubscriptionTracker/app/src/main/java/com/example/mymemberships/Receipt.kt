package com.example.mymemberships

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.PickVisualMediaRequest
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await
import java.io.File
import java.time.LocalDate
import java.util.Locale

data class AmountCandidate(val value: Double,val currency: String,val score: Int)
data class ReceiptResult(val service: Service?,val amounts: List<AmountCandidate>,val yearly: Boolean?,val nextDate: LocalDate?) {
    val warnings: List<String> get() = buildList {
        if(service==null) add("서비스를 찾지 못했어요. 이름을 직접 입력해 주세요.")
        if(amounts.isEmpty()) add("금액을 찾지 못했어요. 실제 구독 금액을 입력해 주세요.")
        if(amounts.size>1) add("여러 금액을 찾았어요. 다음 결제 금액을 확인해 주세요.")
        if(yearly==null) add("결제 주기를 확인하지 못해 월간으로 표시했어요.")
        if(nextDate==null) add("명시된 다음 결제일을 찾지 못해 오늘로 표시했어요. 날짜를 확인해 주세요.")
        add("문자 인식 결과는 틀릴 수 있어요. 결제한 날짜와 다음 결제일을 구분해 주세요.")
    }
    fun subscription() = seed(service).copy(planName=null,channel="unknown",amount=amounts.firstOrNull()?.value ?: 0.0,currency=amounts.firstOrNull()?.currency ?: "KRW",yearly=yearly ?: false,billingDate=nextDate ?: LocalDate.now())
}
object ReceiptParser {
    private val next=Regex("다음\\s*(?:결제|청구|갱신)(?:\\s*(?:예정|일자|날짜|일))?|next\\s*(?:payment|billing|charge|renewal)(?:\\s*date)?|renews?\\s*(?:on|at)",RegexOption.IGNORE_CASE)
    fun parse(text: String,catalog: List<Service>): ReceiptResult {
        val service=catalog.flatMap { s -> (listOf(s.name)+s.aliases).map { s to it } }.filter {(_,alias) -> Regex("(?<![\\p{L}\\p{N}])"+Regex.escape(alias)+"(?![\\p{L}\\p{N}])",RegexOption.IGNORE_CASE).containsMatchIn(text) }.maxByOrNull {it.second.length}?.first
        val annual=Regex("연간|연\\s*구독|매년|annual|yearly|per year|/year|/yr",RegexOption.IGNORE_CASE).containsMatchIn(text)
        val monthly=Regex("월간|월\\s*구독|매월|monthly|per month|/month|/mo",RegexOption.IGNORE_CASE).containsMatchIn(text)
        val amounts=mutableListOf<AmountCandidate>();val lines=text.lines()
        val patterns=listOf("KRW" to Regex("(?:₩|KRW)\\s*([0-9][0-9,]*(?:\\.[0-9]{1,2})?)|([0-9][0-9,]*(?:\\.[0-9]{1,2})?)\\s*(?:원|KRW)",RegexOption.IGNORE_CASE),"USD" to Regex("(?:USD|US\\$|\\$)\\s*([0-9][0-9,]*(?:\\.[0-9]{1,2})?)|([0-9][0-9,]*(?:\\.[0-9]{1,2})?)\\s*USD",RegexOption.IGNORE_CASE))
        for((index,line) in lines.withIndex()) for((currency,regex) in patterns) for(m in regex.findAll(line)) {
            val value=validAmount(m.groups[1]?.value ?: m.groups[2]?.value ?: "") ?: continue
            val context=(if(index>0) lines[index-1]+" " else "")+line
            val score=(if(Regex("합계|총액|구독료|결제\\s*금액|next|total|amount due",RegexOption.IGNORE_CASE).containsMatchIn(context)) 10 else 0) - (if(Regex("할인액|세금|환불|tax|refund|discount",RegexOption.IGNORE_CASE).containsMatchIn(line)) 8 else 0)
            amounts+=AmountCandidate(value,currency,score)
        }
        var date: LocalDate?=null
        for((index,line) in lines.withIndex()) {
            val label=next.find(line) ?: continue
            val tail=line.substring(label.range.last+1)
            date=parseDate(tail)
            if(date==null && tail.trim().trim(':','-').isBlank()) date=lines.getOrNull(index+1)?.takeIf { Regex("^\\s*(?:[12][0-9]{3}|[A-Za-z]+\\s+[0-9])").containsMatchIn(it) }?.let(::parseDate)
            if(date!=null) break
        }
        return ReceiptResult(service,amounts.sortedByDescending {it.score}.distinctBy {it.value to it.currency},if(annual xor monthly) annual else null,date)
    }
    fun parseDate(text: String): LocalDate? {
        val m=Regex("(?<![0-9])([12][0-9]{3})\\s*(?:년|[./-])\\s*([0-9]{1,2})\\s*(?:월|[./-])\\s*([0-9]{1,2})(?![0-9])").find(text)
        if(m!=null) return runCatching {LocalDate.of(m.groupValues[1].toInt(),m.groupValues[2].toInt(),m.groupValues[3].toInt())}.getOrNull()
        val e=Regex("([A-Za-z]+)\\s+([0-9]{1,2}),?\\s+([12][0-9]{3})").find(text) ?: return null
        val months=listOf("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec")
        val month=months.indexOf(e.groupValues[1].take(3).lowercase(Locale.US))+1
        return runCatching {LocalDate.of(e.groupValues[3].toInt(),month,e.groupValues[2].toInt())}.getOrNull()
    }
}
object ReceiptOCR {
    suspend fun read(context: Context,uri: Uri): String = withContext(Dispatchers.IO) {
        val tmp=File.createTempFile("receipt-",".tmp",context.cacheDir)
        val korean=TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
        val latin=TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        try {
            context.contentResolver.openInputStream(uri)?.use { input -> tmp.outputStream().use { out ->
                val buf=ByteArray(65536);var total=0
                while(true) {val n=input.read(buf);if(n<0) break;total+=n;require(total<=25*1024*1024) {"25MB 이하 파일을 선택해 주세요."};out.write(buf,0,n)}
            }} ?: error("파일을 열 수 없어요.")
            suspend fun recognize(bitmap: Bitmap): String = try {
                val image=InputImage.fromBitmap(bitmap,0)
                val ko=korean.process(image).await().text
                val en=latin.process(image).await().text
                (ko.lines()+en.lines()).filter {it.isNotBlank()}.distinct().joinToString("\n")
            } finally {bitmap.recycle()}
            val isPDF=tmp.inputStream().use {ByteArray(5).let { header -> val count=it.read(header); if(count==5) String(header,Charsets.US_ASCII) else "" }} == "%PDF-"
            if(isPDF) {
                ParcelFileDescriptor.open(tmp,ParcelFileDescriptor.MODE_READ_ONLY).use { fd -> PdfRenderer(fd).use { renderer ->
                    (0 until minOf(5,renderer.pageCount)).map {i ->
                        renderer.openPage(i).use {page ->
                            val scale=minOf(2400f/page.width,2400f/page.height,3f)
                            val bitmap=Bitmap.createBitmap((page.width*scale).toInt().coerceAtLeast(1),(page.height*scale).toInt().coerceAtLeast(1),Bitmap.Config.ARGB_8888)
                            bitmap.eraseColor(android.graphics.Color.WHITE);page.render(bitmap,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            recognize(bitmap)
                        }
                    }.joinToString("\n")
                }}
            } else {
                val bitmap=if(Build.VERSION.SDK_INT>=28) ImageDecoder.decodeBitmap(ImageDecoder.createSource(tmp)) {decoder,info,_ ->
                    val scale=minOf(1.0,2400.0/maxOf(info.size.width,info.size.height));decoder.setTargetSize((info.size.width*scale).toInt().coerceAtLeast(1),(info.size.height*scale).toInt().coerceAtLeast(1));decoder.allocator=ImageDecoder.ALLOCATOR_SOFTWARE
                } else {
                    val options=BitmapFactory.Options().apply {inJustDecodeBounds=true};BitmapFactory.decodeFile(tmp.path,options)
                    options.inSampleSize=maxOf(1,maxOf(options.outWidth,options.outHeight)/2400);options.inJustDecodeBounds=false
                    val decoded=BitmapFactory.decodeFile(tmp.path,options) ?: error("이미지를 읽을 수 없어요.")
                    val exif=androidx.exifinterface.media.ExifInterface(tmp)
                    val matrix=android.graphics.Matrix()
                    if(exif.isFlipped) matrix.postScale(-1f,1f)
                    matrix.postRotate(exif.rotationDegrees.toFloat())
                    if(!matrix.isIdentity) Bitmap.createBitmap(decoded,0,0,decoded.width,decoded.height,matrix,true).also {if(it!==decoded) decoded.recycle()} else decoded
                }
                recognize(bitmap)
            }
        } finally {korean.close();latin.close();tmp.delete()}
    }
}
// Memory-only state survives Activity recreation without writing receipt text to disk.
class ReceiptState(private val reader: suspend (Context,Uri) -> String = {context,uri -> ReceiptOCR.read(context,uri)}): androidx.lifecycle.ViewModel() {
    private val scope=CoroutineScope(SupervisorJob()+Dispatchers.Main.immediate)
    private var job: Job?=null
    private var generation=0
    var busy by mutableStateOf(false); private set
    var error by mutableStateOf<String?>(null); private set
    var result by mutableStateOf<ReceiptResult?>(null); private set
    var draft by mutableStateOf<Subscription?>(null); private set
    var text by mutableStateOf(""); private set
    var confirmationToken by mutableIntStateOf(0); private set
    fun read(context: Context,uri: Uri,catalog: List<Service>) {
        val token=++generation
        job?.cancel();busy=true;error=null;confirmationToken++
        job=scope.launch {
            try {
                val recognized=reader(context.applicationContext,uri)
                if(token!=generation) return@launch
                require(recognized.isNotBlank()) {"문자를 찾지 못했어요."}
                text=recognized;result=ReceiptParser.parse(text,catalog);draft=result!!.subscription()
            } catch(e: CancellationException) {throw e}
            catch(e: Exception) {if(token==generation) error=(if(e.message?.contains("25MB")==true) e.message else "사진을 읽지 못했어요. 선명한 이미지 또는 암호가 없는 PDF를 선택해 주세요.")+(if(draft!=null) " 아래에는 이전 인식 결과가 남아 있어요." else "")}
            finally {if(token==generation) busy=false}
        }
    }
    fun clear() {generation++;job?.cancel();busy=false;error=null;result=null;draft=null;text="";confirmationToken++}
    override fun onCleared() {scope.cancel()}
}
@Composable fun ReceiptScreen(catalog: List<Service>,state: ReceiptState,back: () -> Unit,save: (Subscription) -> Unit) {
    val context=LocalContext.current
    var showText by remember {mutableStateOf(false)}
    val photo=rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) {uri -> if(uri!=null) state.read(context,uri,catalog)}
    val file=rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) {uri -> if(uri!=null) state.read(context,uri,catalog)}
    val header: @Composable () -> Unit = {
        Column(verticalArrangement=Arrangement.spacedBy(12.dp)) {
            Text("결제 화면이나 영수증을 선택해 주세요",fontWeight=FontWeight.Bold)
            Button(onClick={photo.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))},enabled=!state.busy,modifier=Modifier.fillMaxWidth(),colors=ButtonDefaults.buttonColors(containerColor=Yellow,contentColor=Ink)) {Icon(Icons.Default.PhotoLibrary,null);Spacer(Modifier.width(8.dp));Text("사진에서 불러오기")}
            OutlinedButton(onClick={file.launch(arrayOf("image/*","application/pdf"))},enabled=!state.busy,modifier=Modifier.fillMaxWidth()) {Text("이미지·PDF 파일 선택")}
            Hint("문자 인식은 이 기기에서 처리해요. 원본과 인식 내용은 저장하지 않아요. 최대 25MB · PDF 앞 5쪽")
            if(state.busy) {LinearProgressIndicator(Modifier.fillMaxWidth());Hint("영수증을 읽고 있어요…")}
            state.error?.let {Hint(it)}
            if(state.text.isNotBlank()) {TextButton(onClick={showText=!showText}) {Text(if(showText) "인식 내용 접기" else "인식 내용 확인")};if(showText) Text(state.text.take(10000))}
        }
    }
    val draft=state.draft;val result=state.result
    if(draft!=null && result!=null) key(draft.id) { EditorScreen(draft,result.service,back,save,receipt=true,warnings=result.warnings,header=header,savingAllowed=!state.busy,confirmationToken=state.confirmationToken,receiptCatalog=catalog,blankInitialAmount=result.amounts.isEmpty()) }
    else Shell("사진·영수증 자동 입력",back) {padding -> Column(Modifier.padding(padding).padding(20.dp)) {header()} }
}
