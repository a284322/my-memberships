import Foundation
var receiptChecks = 0
func verifyReceipt(_ test: @autoclosure () -> Bool, _ label: String) {
    receiptChecks += 1
    guard test() else { fatalError("Receipt check failed: \(label)") }
}
var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(secondsFromGMT: 9*3600)!
let korean = ReceiptParser.parse("YouTube Premium\n매월 결제\n결제 금액 14,900원\n다음 결제일 2026년 11월 26일", calendar: cal)
verifyReceipt(korean.serviceID == "service-001", "YouTube matched")
verifyReceipt(korean.amounts.first?.value == 14900, "KRW grouping")
verifyReceipt(korean.amounts.first?.currency == "KRW", "KRW currency")
verifyReceipt(korean.yearly == false, "monthly")
verifyReceipt(korean.nextPayment == cal.date(from: DateComponents(year: 2026,month: 11,day: 26)), "explicit next Korean date")
let paid = ReceiptParser.parse("Netflix\nPayment date: 2026-10-01\nTotal: $15.49")
verifyReceipt(paid.nextPayment == nil, "paid receipt does not imply renewal")
verifyReceipt(paid.amounts.first?.value == 15.49, "USD decimal")
verifyReceipt(paid.amounts.first?.currency == "USD", "USD currency")
verifyReceipt(paid.yearly == nil, "unknown cycle")
let annual = ReceiptParser.parse("Claude\nAnnual subscription\nUSD 200.00\nNext billing: November 26, 2026", calendar: cal)
verifyReceipt(annual.yearly == true, "annual")
verifyReceipt(annual.nextPayment == cal.date(from: DateComponents(year:2026,month:11,day:26)), "English date")
verifyReceipt(ReceiptParser.parse("ChatGPT\nFree trial ends 2026-11-01\n$20").nextPayment == nil, "trial end independent")
verifyReceipt(ReceiptParser.parse("다음 결제일 2026-02-30").nextPayment == nil, "invalid date rejected")
verifyReceipt(ReceiptParser.parse("다음 결제일 2028.02.29",calendar:cal).nextPayment != nil, "leap date")
verifyReceipt(ReceiptParser.parse("내용 없는 문서").amounts.isEmpty, "no invented amount")
verifyReceipt(ReceiptParser.parse("모르는 서비스").name.isEmpty, "no invented service")
let candidates = ReceiptParser.parse("할인 $5\nTotal $20\nNext payment $20")
verifyReceipt(candidates.amounts.count == 2, "deduplicate amount candidates")
verifyReceipt(candidates.amounts.first?.value == 20, "prefer total")
verifyReceipt(ReceiptParser.parse("Total ₩0").amounts.first?.value == 0, "zero")
verifyReceipt(ReceiptParser.parse("$1,234.56").amounts.first?.value == 1234.56, "USD thousands")
verifyReceipt(ReceiptParser.parse("YouTube Music").serviceID == "service-011", "longer service match")
verifyReceipt(ReceiptParser.parse("월간 / 연간 가격 비교").yearly == nil, "ambiguous cycle")
verifyReceipt(ReceiptParser.parse("₩7900\n$20").amounts.count == 2, "mixed currencies")
verifyReceipt(ReceiptParser.parse("Invoice number 20261126\nCard 1234").amounts.isEmpty, "IDs not prices")
verifyReceipt(ReceiptParser.parse("Paid 2026-01-01 / Next payment 2026-02-01",calendar:cal).nextPayment == cal.date(from:DateComponents(year:2026,month:2,day:1)), "only date after next label")
verifyReceipt(ReceiptParser.parse("Next payment $20\nPayment date 2026-11-01").nextPayment == nil, "following paid date not a renewal")
print("PASS: \(receiptChecks) receipt parser checks")
