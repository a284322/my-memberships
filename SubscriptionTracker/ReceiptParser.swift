import Foundation

struct ReceiptAmount: Equatable {
    let value: Double
    let currency: String
    let evidence: String
    let score: Int
}
struct ReceiptRecognition {
    var serviceID: String?
    var name: String = ""
    var amounts: [ReceiptAmount] = []
    var yearly: Bool?
    var nextPayment: Date?
}
enum ReceiptParser {
    static func parse(_ text: String, calendar: Calendar = .current) -> ReceiptRecognition {
        var result = ReceiptRecognition()
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let normalized = text.lowercased()
        let matches = CatalogService.all.compactMap { service -> (CatalogService, Int)? in
            let terms = [service.name] + service.aliases
            let length = terms.filter { term in
                let escaped = NSRegularExpression.escapedPattern(for: term.lowercased())
                return normalized.range(of: "(?<![a-z0-9])" + escaped + "(?![a-z0-9])", options: .regularExpression) != nil
            }.map(\.count).max() ?? 0
            return length > 0 ? (service, length) : nil
        }.sorted { $0.1 > $1.1 }
        if let service = matches.first?.0 { result.serviceID = service.id; result.name = service.displayName }
        let annual = normalized.range(of: "연간|연 구독|매년|annual|yearly|per year|/year|/yr", options: .regularExpression) != nil
        let monthly = normalized.range(of: "월간|월 구독|매월|monthly|per month|/month|/mo", options: .regularExpression) != nil
        if annual != monthly { result.yearly = annual }
        let pattern = #"(?:₩|KRW)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)|([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(?:원|KRW)|(?:US\$|USD|\$)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)|([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*USD"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        var found: [ReceiptAmount] = []
        for (index, line) in lines.enumerated() {
            let ns = line as NSString
            for match in regex.matches(in: line, range: NSRange(location: 0, length: ns.length)) {
                guard let group = (1...4).first(where: { match.range(at: $0).location != NSNotFound }),
                      let value = Double(ns.substring(with: match.range(at: group)).replacingOccurrences(of: ",", with: "")), value >= 0, value < 1_000_000_000 else { continue }
                let context = (index > 0 ? lines[index-1] + " " : "") + line
                let lower = context.lowercased()
                var score = 0
                if lower.range(of: "다음.*결제|구독료|월회비|청구 금액|결제 금액|총액|합계|total|amount due|next payment", options: .regularExpression) != nil { score += 10 }
                if lower.range(of: "할인|부가세|세금|적립|환불|discount|tax|subtotal|refund", options: .regularExpression) != nil { score -= 8 }
                found.append(.init(value: value, currency: group <= 2 ? "KRW" : "USD", evidence: line, score: score))
            }
        }
        for amount in found.sorted(by: { $0.score > $1.score }) {
            if !result.amounts.contains(where: { $0.value == amount.value && $0.currency == amount.currency }) { result.amounts.append(amount) }
        }
        // Only a date explicitly labelled as the NEXT payment/renewal is eligible.
        // Invoice, order, payment and free-trial end dates never imply the next renewal.
        for (index, line) in lines.enumerated() {
            guard let labelRange = line.range(of: "다음\\s*(결제|청구|갱신)|next\\s*(payment|billing|charge|renewal)|renews?\\s*(on|at)|갱신\\s*예정", options: [.regularExpression, .caseInsensitive]) else { continue }
            let following = index+1 < lines.count ? lines[index+1] : ""
            let standaloneDate = following.range(of: #"^(?:20[0-9]{2}\s*[년./-]|(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+[0-9])"#, options: [.regularExpression, .caseInsensitive]) != nil
            let context = String(line[labelRange.upperBound...]) + (standaloneDate ? " " + following : "")
            if let date = parseDate(context, calendar: calendar) { result.nextPayment = date; break }
        }
        return result
    }
    private static func parseDate(_ text: String, calendar: Calendar) -> Date? {
        let pattern = #"(20[0-9]{2})\s*(?:년|[./-])\s*([0-9]{1,2})\s*(?:월|[./-])\s*([0-9]{1,2})\s*일?"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let ns = text as NSString
        if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) {
            let values = (1...3).compactMap { Int(ns.substring(with: match.range(at: $0))) }
            if values.count == 3, let date = calendar.date(from: DateComponents(year: values[0], month: values[1], day: values[2])), calendar.component(.year, from: date) == values[0], calendar.component(.month, from: date) == values[1], calendar.component(.day, from: date) == values[2] { return date }
        }
        let english = try! NSRegularExpression(pattern: #"[A-Za-z]{3,9}\s+[0-9]{1,2},?\s+20[0-9]{2}"#)
        if let match = english.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) {
            let candidate = ns.substring(with: match.range)
            for format in ["MMMM d, yyyy", "MMM d, yyyy", "MMMM d yyyy", "MMM d yyyy"] {
                let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.calendar = calendar; f.timeZone = calendar.timeZone; f.dateFormat = format; f.isLenient = false
                if let date = f.date(from: candidate) { return date }
            }
        }
        return nil
    }
}
