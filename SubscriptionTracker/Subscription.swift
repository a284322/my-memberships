import Foundation

enum SubscriptionStatus: String, Codable, CaseIterable {
    case active, planned, cancelled
    var title: String { switch self { case .active: return "이용 중"; case .planned: return "해지 예정"; case .cancelled: return "해지 완료" } }
}
enum RetentionDecision: String, Codable, CaseIterable {
    case keep, later, cancel
    var title: String { switch self { case .keep: return "계속 이용"; case .later: return "나중에 결정"; case .cancel: return "해지 예정" } }
}
enum BillingChannel: String, Codable, CaseIterable {
    case web, apple, google, other, unknown
    var title: String { switch self { case .web: return "웹"; case .apple: return "Apple App Store"; case .google: return "Google Play"; case .other: return "기타"; case .unknown: return "모름" } }
}
struct ReminderPreferences: Codable, Equatable {
    var enabled = false
    var days = [3]
    var hour = 9
    var minute = 0
    var validDays: [Int] { Array(Set(days.filter { [0, 1, 3, 7, 30].contains($0) })).sorted() }
}

struct Subscription: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var yearly: Bool
    var billingDate: Date
    var planName: String? = nil
    var serviceID: String? = nil
    var category: String? = nil
    var currency: String? = nil
    var freeStartDate: Date? = nil
    var promotionVersion: Int? = nil
    /// Inclusive last free/discounted day; independent from billing and price application dates.
    var freeEndDate: Date? = nil
    var discountEndDate: Date? = nil
    var afterAmount: Double? = nil
    var amountEffectiveDate: Date? = nil
    var purpose: String? = nil
    var neededUntil: Date? = nil
    var reviewReminder: Bool? = nil
    var decision: RetentionDecision? = nil
    var status: SubscriptionStatus? = nil
    var channel: BillingChannel? = nil
    var accountMemo: String? = nil
    var cancellationURL: String? = nil
    var cancellationEffectiveDate: Date? = nil
    var cancellationConfirmedAt: Date? = nil
    var reminderOverride: ReminderPreferences? = nil
    var customBenefits: [BenefitDefinition]? = nil
    var benefitEdits: [String: BenefitDefinition]? = nil
    var hiddenBenefitIDs: [String]? = nil
    var benefitUsage: [String: BenefitUsage]? = nil
    var benefitInfoURL: String? = nil
    var managementURL: String? = nil

    var currencyCode: String { currency ?? "KRW" }
    var currentStatus: SubscriptionStatus { status ?? .active }
    var monthlyAmount: Double { yearly ? amount / 12 : amount }
    func currentAnnualAmount(on date: Date, calendar: Calendar = .current) -> Double {
        currentMonthlyAmount(on: date, calendar: calendar) * 12
    }
    func recurringPrice(on date: Date, calendar: Calendar = .current) -> Double {
        if let effective = amountEffectiveDate, let afterAmount,
           calendar.startOfDay(for: date) >= calendar.startOfDay(for: effective) { return afterAmount }
        return amount
    }
    var nextPayment: Date { nextPayment(on: Date()) }
    var isFreeNow: Bool { isFree(on: Date()) }

    func resolvedFreeEnd(calendar: Calendar = .current) -> Date? {
        if let freeEndDate { return freeEndDate }
        // Preserve the old app's implicit promotion boundary only for legacy records.
        if promotionVersion == nil && freeStartDate != nil { return calendar.date(byAdding: .day, value: -1, to: billingDate) }
        return nil
    }
    func isFree(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let start = freeStartDate, let end = resolvedFreeEnd(calendar: calendar) else { return false }
        let today = calendar.startOfDay(for: date)
        return today >= calendar.startOfDay(for: start) && today <= calendar.startOfDay(for: end)
    }
    func isAwaitingStart(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let start = freeStartDate else { return false }
        return calendar.startOfDay(for: date) < calendar.startOfDay(for: start)
    }
    func isEffective(on date: Date, calendar: Calendar = .current) -> Bool {
        guard currentStatus == .cancelled else { return true }
        // Confirmed cancellation without a date cannot silently create more charges.
        guard let end = cancellationEffectiveDate else { return false }
        return calendar.startOfDay(for: date) < calendar.startOfDay(for: end)
    }
    func price(on date: Date, calendar: Calendar = .current) -> Double {
        if !isEffective(on: date, calendar: calendar) || isFree(on: date, calendar: calendar) { return 0 }
        if let effective = amountEffectiveDate, let afterAmount,
           calendar.startOfDay(for: date) >= calendar.startOfDay(for: effective) { return afterAmount }
        return amount
    }
    func currentMonthlyAmount(on date: Date, calendar: Calendar = .current) -> Double {
        if promotionVersion == nil && isAwaitingStart(on: date, calendar: calendar) { return 0 }
        return price(on: date, calendar: calendar) / (yearly ? 12 : 1)
    }
    func nextPayment(on date: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: date)
        let anchor = calendar.startOfDay(for: billingDate)
        guard anchor < today else { return anchor }
        let component: Calendar.Component = yearly ? .year : .month
        let elapsed = max(0, calendar.dateComponents([component], from: anchor, to: today).value(for: component) ?? 0)
        let candidate = calendar.date(byAdding: component, value: elapsed, to: anchor) ?? anchor
        return candidate >= today ? candidate : (calendar.date(byAdding: component, value: elapsed + 1, to: anchor) ?? candidate)
    }
    /// Recurrence is always calculated from the original anchor to avoid February drift.
    func payments(from start: Date, to end: Date, calendar: Calendar = .current) -> [PaymentOccurrence] {
        let anchor = calendar.startOfDay(for: billingDate)
        let start = calendar.startOfDay(for: start)
        let component: Calendar.Component = yearly ? .year : .month
        let firstIndex = max(0, (calendar.dateComponents([component], from: anchor, to: start).value(for: component) ?? 0) - 1)
        var result: [PaymentOccurrence] = []
        for index in firstIndex..<(firstIndex + 600) {
            guard let date = calendar.date(byAdding: component, value: index, to: anchor), date < end else { break }
            if date >= start && isEffective(on: date, calendar: calendar) {
                let value = price(on: date, calendar: calendar)
                if value > 0 { result.append(.init(subscriptionID: id, date: date, amount: value, yearly: yearly)) }
            }
        }
        return result
    }
    func upcomingPayment(on date: Date, calendar: Calendar = .current) -> PaymentOccurrence? {
        guard let end = calendar.date(byAdding: .year, value: 5, to: date) else { return nil }
        return payments(from: date, to: end, calendar: calendar).first
    }
    func thisMonthPayments(on date: Date, calendar: Calendar = .current) -> [PaymentOccurrence] {
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        return payments(from: interval.start, to: interval.end, calendar: calendar)
    }
    static func validAmount(_ text: String, allowZero: Bool = false) -> Double? {
        guard let value = Double(text.replacingOccurrences(of: ",", with: "")), value.isFinite,
              (allowZero ? value >= 0 : value > 0), value <= 1_000_000_000 else { return nil }
        return value
    }
    static func suggestedPaidStart(after start: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: 1, to: start) ?? start
    }
    static func validFreePeriod(start: Date, paidStart: Date, calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: start) < calendar.startOfDay(for: paidStart)
    }
    static func safeURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { return nil }
        return url
    }
}
struct PaymentOccurrence: Identifiable {
    var id: String { subscriptionID.uuidString + String(date.timeIntervalSince1970) }
    let subscriptionID: UUID
    let date: Date
    let amount: Double
    let yearly: Bool
}
struct ReminderEvent: Identifiable {
    let id: String
    let subscriptionID: UUID
    let fireDate: Date
    let title: String
    let body: String
}

enum ReminderPlanner {
    static let prefix = "subscription."
    static func events(for items: [Subscription], defaults: ReminderPreferences, now: Date, calendar: Calendar = .current, limit: Int = 60) -> [ReminderEvent] {
        guard let horizon = calendar.date(byAdding: .year, value: 3, to: now) else { return [] }
        var events: [ReminderEvent] = []
        for item in items {
            let prefs = item.reminderOverride ?? defaults
            guard prefs.enabled || item.reviewReminder == true else { continue }
            let days = prefs.enabled ? prefs.validDays.filter { item.yearly || $0 != 30 } : []
            func add(date: Date, lead: Int, kind: String, title: String, body: String) {
                guard let shifted = calendar.date(byAdding: .day, value: -lead, to: date),
                      let fire = calendar.date(bySettingHour: min(23,max(0,prefs.hour)), minute: min(59,max(0,prefs.minute)), second: 0, of: shifted),
                      fire > now, item.isEffective(on: fire, calendar: calendar) else { return }
                events.append(.init(id: prefix + item.id.uuidString + "." + kind + "." + String(Int(date.timeIntervalSince1970)) + "." + String(lead), subscriptionID: item.id,
                    fireDate: fire, title: title, body: body))
            }
            for payment in item.payments(from: now, to: horizon, calendar: calendar) {
                for lead in days {
                    let label = lead == 0 ? "오늘 결제 예정" : "결제 \(lead)일 전"
                    let price = payment.amount.formatted(.currency(code: item.currencyCode))
                    add(date: payment.date, lead: lead, kind: "payment", title: "\(item.name) \(label) · \(price)", body: "이용 중인 혜택을 확인하고 계속 사용할지 결정해보세요.")
                }
            }
            let milestones: [(String, Date?)] = [("무료체험 종료", item.resolvedFreeEnd(calendar: calendar)), ("할인 종료", item.discountEndDate)]
            for (kind, date) in milestones {
                guard let date, date < horizon, item.isEffective(on: date, calendar: calendar) else { continue }
                let after = item.afterAmount.map { " 종료 후 금액 \($0.formatted(.currency(code: item.currencyCode)))." } ?? " 종료 후 적용 금액을 확인해 주세요."
                for lead in days {
                    add(date: date, lead: lead, kind: kind, title: "\(item.name) \(kind) \(lead == 0 ? "당일" : "\(lead)일 전")", body: "필요한 구독인지 다시 확인해보세요." + after)
                }
            }
            if item.reviewReminder == true, let date = item.neededUntil, date < horizon, item.isEffective(on: date, calendar: calendar) {
                add(date: date, lead: 0, kind: "review", title: "\(item.name) 유지 여부 확인", body: item.purpose.flatMap { $0.isEmpty ? nil : "구독 목적: \($0)" } ?? "필요 기간이 끝났어요. 계속 이용할지 확인해보세요.")
            }
        }
        return Array(events.sorted { $0.fireDate == $1.fireDate ? $0.id < $1.id : $0.fireDate < $1.fireDate }.prefix(max(0, limit)))
    }
}

struct SubscriptionRepository {
    let defaults: UserDefaults
    let key: String
    func load() throws -> [Subscription] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([Subscription].self, from: data)
    }
    func save(_ items: [Subscription]) throws {
        let data = try JSONEncoder().encode(items)
        defaults.set(data, forKey: key)
    }
}

struct CancellationGuidance {
    let url: URL
    let label: String
    static func resolve(_ item: Subscription) -> CancellationGuidance? {
        if let url = Subscription.safeURL(item.cancellationURL) { return .init(url: url, label: "사용자가 저장한 안내") }
        let link: String?
        switch item.channel ?? .unknown {
        case .apple: link = "https://support.apple.com/ko-kr/118428"
        case .google: link = "https://support.google.com/googleplay/answer/7018481?hl=ko"
        case .web:
            if item.serviceID == "service-002" { link = "https://help.netflix.com/ko/node/407" }
            else if item.serviceID == "service-019" { link = "https://help.openai.com/en/articles/7232927-canceling-your-chatgpt-subscription" }
            else { link = nil }
        default: link = nil
        }
        guard let link, let url = URL(string: link) else { return nil }
        return .init(url: url, label: "공식 도움말 · 2026.10.25 확인 · 선택한 결제 경로 기준")
    }
}

/// A repeating payment is used only when dates and prices remain valid without app execution.
struct ReminderReservation {
    let event: ReminderEvent
    let repeating: DateComponents?
}
struct ReminderReservationPlan {
    let reservations: [ReminderReservation]
    let limitedThrough: Date?
}
enum ReminderReservationPlanner {
    static func plan(items: [Subscription], preferences: ReminderPreferences, now: Date, calendar: Calendar = .current, limit: Int = 60) -> ReminderReservationPlan {
        let events = ReminderPlanner.events(for: items, defaults: preferences, now: now, calendar: calendar, limit: 50_000)
        var candidates: [ReminderReservation] = []
        var repeatingKeys = Set<String>()
        for event in events {
            guard let item = items.first(where: { $0.id == event.subscriptionID }) else { continue }
            let components = event.id.split(separator: ".")
            let kind = components.count >= 3 ? String(components[components.count - 3]) : ""
            let lead = Int(components.last ?? "") ?? -1
            let key = item.id.uuidString + "." + String(lead)
            if kind == "payment" && repeatingKeys.contains(key) { continue }
            if kind == "payment", let repeatDate = repeatingComponents(item: item, lead: lead, fire: event.fireDate, now: now, calendar: calendar) {
                if repeatingKeys.insert(key).inserted { candidates.append(ReminderReservation(event: event, repeating: repeatDate)) }
            } else { candidates.append(ReminderReservation(event: event, repeating: nil)) }
        }
        let chosen = Array(candidates.prefix(max(0, limit)))
        let limited = candidates.count > chosen.count ? chosen.last?.event.fireDate : nil
        return ReminderReservationPlan(reservations: chosen, limitedThrough: limited)
    }
    private static func repeatingComponents(item: Subscription, lead: Int, fire: Date, now: Date, calendar: Calendar) -> DateComponents? {
        guard lead >= 0, item.currentStatus != .cancelled,
              item.freeStartDate == nil, item.freeEndDate == nil, item.discountEndDate == nil,
              item.afterAmount == nil, item.amountEffectiveDate == nil else { return nil }
        var result = calendar.dateComponents([.hour, .minute, .second], from: fire)
        if item.yearly {
            // Crossing a leap-day must not silently move a reminder in a later year.
            let expected = calendar.dateComponents([.month, .day], from: fire)
            for year in 0..<8 {
                guard let payment = calendar.date(byAdding: .year, value: year, to: item.billingDate),
                      let shifted = calendar.date(byAdding: .day, value: -lead, to: payment) else { return nil }
                let check = calendar.dateComponents([.month, .day], from: shifted)
                if check.month != expected.month || check.day != expected.day { return nil }
            }
            result.month = expected.month; result.day = expected.day
        } else {
            let day = calendar.component(.day, from: item.billingDate)
            guard day <= 28, day - lead >= 1 else { return nil }
            result.day = day - lead
        }
        // Never enable a repeat which would start before the original billing anchor.
        guard let next = calendar.nextDate(after: now, matching: result, matchingPolicy: .nextTime),
              abs(next.timeIntervalSince(fire)) < 1 else { return nil }
        return result
    }
}
