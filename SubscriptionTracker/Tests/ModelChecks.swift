import Foundation

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
}
func day(_ date: Date) -> Date { calendar.startOfDay(for: date) }
var count = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    precondition(condition(), "FAILED: \(name)"); count += 1
}
var trial = Subscription(name: "무료 테스트", amount: 29000, yearly: false, billingDate: date(2026,11,25), planName: "Plus", freeStartDate: date(2026,10,25))
check(trial.isFree(on: date(2026,10,25), calendar: calendar), "trial first day")
check(trial.isFree(on: date(2026,11,24), calendar: calendar), "trial last day")
check(!trial.isFree(on: date(2026,11,25), calendar: calendar), "paid boundary")
check(trial.currentMonthlyAmount(on: date(2026,11,24), calendar: calendar) == 0, "free excluded from total")
check(trial.currentMonthlyAmount(on: date(2026,11,25), calendar: calendar) == 29000, "paid included at boundary")
check(trial.currentMonthlyAmount(on: date(2026,10,24), calendar: calendar) == 0, "future promotion excluded")
check(trial.isAwaitingStart(on: date(2026,10,24), calendar: calendar), "scheduled trial status")
check(trial.nextPayment(on: date(2026,10,25), calendar: calendar) == day(date(2026,11,25)), "first paid day anchor")
check(trial.nextPayment(on: date(2026,11,26), calendar: calendar) == day(date(2026,12,25)), "recurrence after promotion")
check(!Subscription.validFreePeriod(start: date(2026,10,25), paidStart: date(2026,10,25), calendar: calendar), "equal dates rejected")
check(!Subscription.validFreePeriod(start: date(2026,11,25), paidStart: date(2026,10,25), calendar: calendar), "reversed dates rejected")
check(Subscription.validFreePeriod(start: date(2026,10,25), paidStart: date(2026,10,26), calendar: calendar), "one-day promotion")
check(Subscription.suggestedPaidStart(after: date(2026,10,25), calendar: calendar) == date(2026,11,25), "trial default one month")
check(Subscription.suggestedPaidStart(after: date(2026,1,31), calendar: calendar) == date(2026,2,28), "trial default month end")
let monthly = Subscription(name: "월말", amount: 12000, yearly: false, billingDate: date(2024,1,31))
check(monthly.nextPayment(on: date(2024,2,1), calendar: calendar) == day(date(2024,2,29)), "leap February clamp")
check(monthly.nextPayment(on: date(2024,3,1), calendar: calendar) == day(date(2024,3,31)), "month end anchor preserved")
check(monthly.nextPayment(on: date(2025,2,1), calendar: calendar) == day(date(2025,2,28)), "nonleap February clamp")
let yearly = Subscription(name: "윤년", amount: 120000, yearly: true, billingDate: date(2024,2,29))
check(yearly.monthlyAmount == 10000, "yearly amount normalized")
check(yearly.nextPayment(on: date(2025,2,1), calendar: calendar) == day(date(2025,2,28)), "annual leap clamp")
check(yearly.nextPayment(on: date(2028,2,1), calendar: calendar) == day(date(2028,2,29)), "annual leap anniversary restored")
check(monthly.nextPayment(on: date(2024,1,31), calendar: calendar) == day(date(2024,1,31)), "billing today included")
for bad in ["", "0", "-1", "nan", "inf", "1000000001", "hello"] {
    check(Subscription.validAmount(bad) == nil, "invalid amount \(bad)")
}
check(Subscription.validAmount("29,000") == 29000, "grouped amount")
check(Subscription.validAmount("19.99") == 19.99, "USD decimal")
let legacyData = Data("{\"id\":\"12345678-1234-1234-1234-123456789012\",\"name\":\"기존 구독\",\"amount\":12000,\"yearly\":false,\"billingDate\":0}".utf8)
let legacy = try JSONDecoder().decode(Subscription.self, from: legacyData)
check(legacy.currencyCode == "KRW" && legacy.freeStartDate == nil && legacy.planName == nil, "legacy migration")
let saved = try JSONEncoder().encode([trial, yearly, legacy])
let restored = try JSONDecoder().decode([Subscription].self, from: saved)
check(restored.count == 3 && restored[0].freeStartDate == trial.freeStartDate && restored[0].billingDate == trial.billingDate && restored[0].planName == "Plus", "promotion persistence")
trial.currency = "USD"
let currencyRestored = try JSONDecoder().decode(Subscription.self, from: JSONEncoder().encode(trial))
check(currencyRestored.currencyCode == "USD", "currency persistence")
check(CatalogService.all.count == 97, "97 catalog entries")
check(Set(CatalogService.all.map(\.id)).count == 97, "unique service IDs")
check(CatalogService.categories.count == 16, "16 categories")
for query in ["일레븐랩스", "ElevenLabs", "젠스파크", "마누스", "윌라", "수노", "티빙", "지니", "애플뮤직"] {
    check(CatalogService.all.contains { $0.matches(query) }, "search \(query)")
}
check(CatalogService.all.first { $0.name == "Genspark" }?.category == "AI 대화·검색·에이전트", "agent category")
check(CatalogService.all.first { $0.name == "Netflix" }?.plans.first { $0.name == "스탠다드" }?.amount == 13500, "known plan price")
check(CatalogService.all.first { $0.name == "윌라" }?.plans.isEmpty == true, "unverified prices not fabricated")
for service in CatalogService.all {
    check(URL(string: service.source)?.scheme == "https", "valid official URL \(service.name)")
    check(!service.displayName.isEmpty && !service.category.isEmpty, "catalog labels \(service.name)")
}
print("PASS: \(count) checks — promotion boundaries, dates, legacy data, persistence, currency, 97 services, search")

// PRD phase 1: independent promotion boundaries and effective prices.
var event = Subscription(name: "이벤트", amount: 1000, yearly: false, billingDate: date(2026,11,10), freeStartDate: date(2026,10,1))
event.promotionVersion = 1
event.freeEndDate = date(2026,10,20)
event.afterAmount = 15000
event.amountEffectiveDate = date(2026,11,1)
check(event.isFree(on: date(2026,10,20), calendar: calendar), "new trial end inclusive")
check(!event.isFree(on: date(2026,10,21), calendar: calendar), "trial ends independently from first payment")
check(event.price(on: date(2026,10,20), calendar: calendar) == 0, "free price")
check(event.price(on: date(2026,10,21), calendar: calendar) == 1000, "gap uses explicitly configured base amount")
check(event.price(on: date(2026,11,1), calendar: calendar) == 15000, "price effective boundary")
check(event.upcomingPayment(on: date(2026,10,21), calendar: calendar)?.date == day(date(2026,11,10)), "first payment not trial end")
check(event.upcomingPayment(on: date(2026,10,21), calendar: calendar)?.amount == 15000, "future payment uses future price")
check(event.thisMonthPayments(on: date(2026,10,25), calendar: calendar).isEmpty, "no invented payment before anchor")
var discount = Subscription(name: "할인", amount: 5000, yearly: false, billingDate: date(2026,10,31))
discount.discountEndDate = date(2026,11,20)
discount.afterAmount = 12000; discount.amountEffectiveDate = date(2026,11,25)
check(discount.price(on: date(2026,11,24), calendar: calendar) == 5000, "discount gap respects explicit effective date")
check(discount.price(on: date(2026,11,25), calendar: calendar) == 12000, "discount price change")
check(discount.thisMonthPayments(on: date(2026,11,1), calendar: calendar).first?.date == day(date(2026,11,30)), "November month end")
check(discount.thisMonthPayments(on: date(2026,11,1), calendar: calendar).first?.amount == 12000, "renewal after discount")
check(discount.thisMonthPayments(on: date(2026,12,1), calendar: calendar).first?.date == day(date(2026,12,31)), "December restores original day")
var unknownEnd = event; unknownEnd.freeEndDate = nil
check(!unknownEnd.isFree(on: date(2026,10,15), calendar: calendar), "no inferred end for new records")
check(legacy.currentStatus == .active && legacy.reminderOverride == nil && legacy.purpose == nil, "new fields default for legacy")
var planned = discount; planned.status = .planned
check(planned.thisMonthPayments(on: date(2026,11,1), calendar: calendar).first?.amount == 12000, "planned cancellation still counted")
planned.decision = .later
check(planned.thisMonthPayments(on: date(2026,11,1), calendar: calendar).first?.amount == 12000, "retention decision does not change costs")
var cancelled = discount; cancelled.status = .cancelled; cancelled.cancellationEffectiveDate = date(2026,11,30); cancelled.cancellationConfirmedAt = date(2026,10,25)
check(cancelled.isEffective(on: date(2026,11,29), calendar: calendar), "before cancellation effective date")
check(!cancelled.isEffective(on: date(2026,11,30), calendar: calendar), "cancellation effective boundary")
check(cancelled.thisMonthPayments(on: date(2026,11,1), calendar: calendar).isEmpty, "payment on cancellation date excluded")
check(cancelled.thisMonthPayments(on: date(2026,10,1), calendar: calendar).count == 1, "prior monthly schedule preserved")
check(cancelled.currentMonthlyAmount(on: date(2026,12,1), calendar: calendar) == 0, "cancelled monthly cost zero")
check(cancelled.upcomingPayment(on: date(2026,12,1), calendar: calendar) == nil, "no future cancelled payment")
let annualBill = Subscription(name: "연간 갱신", amount: 120000, yearly: true, billingDate: date(2025,11,5))
check(annualBill.currentMonthlyAmount(on: date(2026,11,1), calendar: calendar) == 10000, "annual normalized cost")
check(annualBill.thisMonthPayments(on: date(2026,11,1), calendar: calendar).reduce(0) { $0 + $1.amount } == 120000, "annual actual scheduled charge")
check(annualBill.thisMonthPayments(on: date(2026,10,1), calendar: calendar).isEmpty, "no annual charge in other months")

let enabled = ReminderPreferences(enabled: true, days: [0,1,3,7,30], hour: 9, minute: 0)
let testNow = date(2026,10,1)
let reminders = ReminderPlanner.events(for: [discount], defaults: enabled, now: testNow, calendar: calendar)
check(reminders.allSatisfy { $0.fireDate > testNow }, "no past notifications")
check(reminders.allSatisfy { calendar.component(.hour, from: $0.fireDate) == 9 }, "configured local hour")
check(!reminders.contains { $0.id.hasSuffix(".30") }, "monthly excludes 30-day option")
check(reminders.contains { $0.title.contains("할인 종료") && $0.body.contains("12,000") }, "discount notice includes after price")
check(reminders.contains { $0.title.contains("결제 3일 전") }, "3-day payment notice")
let defaultOff = ReminderPlanner.events(for: [discount], defaults: ReminderPreferences(), now: testNow, calendar: calendar)
check(defaultOff.isEmpty, "no permission-free auto opt-in")
var overridden = discount; overridden.reminderOverride = ReminderPreferences(enabled: false)
check(ReminderPlanner.events(for: [overridden], defaults: enabled, now: testNow, calendar: calendar).isEmpty, "per-subscription opt-out")
overridden.reminderOverride = enabled
check(!ReminderPlanner.events(for: [overridden], defaults: ReminderPreferences(), now: testNow, calendar: calendar).isEmpty, "individual opt-in")
var review = discount; review.neededUntil = date(2026,10,8); review.reviewReminder = true; review.purpose = "면접 준비"
let reviewOnly = ReminderPlanner.events(for: [review], defaults: ReminderPreferences(), now: testNow, calendar: calendar)
check(reviewOnly.count == 1 && reviewOnly[0].body.contains("면접 준비"), "independent purpose review notification")
let annualNotices = ReminderPlanner.events(for: [annualBill], defaults: enabled, now: testNow, calendar: calendar)
check(annualNotices.contains { $0.id.hasSuffix(".30") }, "annual 30-day notification")
let cancelledNotices = ReminderPlanner.events(for: [cancelled], defaults: enabled, now: testNow, calendar: calendar)
check(cancelledNotices.allSatisfy { $0.fireDate < day(date(2026,11,30)) }, "no notices on or after cancellation")
check(!cancelledNotices.contains { $0.title.contains("12,000") && $0.id.contains("payment") }, "no reminders for cancelled renewals")
check(ReminderPlanner.events(for: [], defaults: enabled, now: testNow, calendar: calendar).isEmpty, "deleted subscription clears plan")
var moved = discount; moved.billingDate = date(2026,11,15)
let movedNotices = ReminderPlanner.events(for: [moved], defaults: enabled, now: testNow, calendar: calendar)
check(movedNotices.first(where: { $0.id.contains("payment") })?.fireDate != reminders.first(where: { $0.id.contains("payment") })?.fireDate, "modified schedule replaces dates")
let many = (0..<40).map { Subscription(name: "알림\($0)", amount: 1000, yearly: false, billingDate: date(2026,10,10)) }
let limited = ReminderPlanner.events(for: many, defaults: enabled, now: testNow, calendar: calendar)
check(limited.count == 60 && Set(limited.map(\.id)).count == 60, "bounded unique notification budget")
check(zip(limited, limited.dropFirst()).allSatisfy { $0.fireDate <= $1.fireDate }, "closest notifications scheduled first")
check(ReminderPreferences(days: [3,3,100,-1,7]).validDays == [3,7], "invalid reminder offsets filtered")
var midnightCal = calendar
midnightCal.timeZone = TimeZone(identifier: "America/New_York")!
let dstItem = Subscription(name: "DST", amount: 1, yearly: false, billingDate: midnightCal.date(from: DateComponents(year: 2026,month: 11,day: 3,hour: 12))!)
let dstEvents = ReminderPlanner.events(for: [dstItem], defaults: enabled, now: midnightCal.date(from: DateComponents(year: 2026,month: 10,day: 20))!, calendar: midnightCal)
check(dstEvents.allSatisfy { midnightCal.component(.hour, from: $0.fireDate) == 9 }, "DST keeps local notification time")
let suite = "SubscriptionTests." + UUID().uuidString
let testDefaults = UserDefaults(suiteName: suite)!
defer { testDefaults.removePersistentDomain(forName: suite) }
let repo = SubscriptionRepository(defaults: testDefaults, key: "subscriptions.v1")
testDefaults.set(legacyData, forKey: "legacy-single")
testDefaults.set(Data(("[" + String(data: legacyData, encoding: .utf8)! + "]").utf8), forKey: "subscriptions.v1")
let legacyList = try repo.load()
check(legacyList.count == 1, "repository loads legacy list")
review.accountMemo = "test@example.com"; review.channel = .apple; review.cancellationURL = "https://example.com/help"
try repo.save([review, cancelled, event])
let savedAgain = try repo.load()
check(savedAgain.count == 3 && savedAgain[0].purpose == "면접 준비" && savedAgain[0].channel == .apple && savedAgain[0].reviewReminder == true, "new fields restored from same storage")
check(savedAgain[1].cancellationConfirmedAt != nil && savedAgain[1].currentStatus == .cancelled, "cancellation confirmation preserved")
check(savedAgain[2].freeEndDate != savedAgain[2].billingDate && savedAgain[2].afterAmount == 15000, "independent promotion fields persist")
let damaged = Data("not-json".utf8); testDefaults.set(damaged, forKey: "subscriptions.v1")
do { _ = try repo.load(); check(false, "corrupt data must fail") } catch { check(testDefaults.data(forKey: "subscriptions.v1") == damaged, "failed load preserves original bytes") }
check(Subscription.safeURL("javascript:alert(1)") == nil && Subscription.safeURL("https://example.com/help") != nil, "cancellation URL validation")
var guidanceItem = legacy; guidanceItem.channel = .unknown
check(CancellationGuidance.resolve(guidanceItem) == nil, "no invented cancellation links")
guidanceItem.channel = .apple
check(CancellationGuidance.resolve(guidanceItem)?.url.host == "support.apple.com", "Apple billing guidance")
guidanceItem.channel = .google
check(CancellationGuidance.resolve(guidanceItem)?.url.host == "support.google.com", "Play billing guidance")
guidanceItem.channel = .web; guidanceItem.serviceID = "service-002"
check(CancellationGuidance.resolve(guidanceItem)?.url.absoluteString == "https://help.netflix.com/ko/node/407", "verified Netflix guidance")
var futurePromotion = event
futurePromotion.freeStartDate = date(2026,10,10)
futurePromotion.freeEndDate = date(2026,10,20)
check(futurePromotion.currentMonthlyAmount(on: date(2026,10,5), calendar: calendar) == 1000, "new future promotion does not erase current paid cost")
check(futurePromotion.currentMonthlyAmount(on: date(2026,10,15), calendar: calendar) == 0, "new promotion zero only inside interval")
print("PASS: \(count) total checks including PRD phase 1")

// Shopping/lifestyle membership extension.
let wowCatalog = CatalogService.all.first { $0.id == "service-096" }!
let naverCatalog = CatalogService.all.first { $0.id == "service-097" }!
check(wowCatalog.category == "쇼핑·생활" && naverCatalog.name == "네이버플러스 멤버십", "shopping catalog naming")
check(!naverCatalog.name.contains("네이버페이"), "payment service is not membership name")
check(wowCatalog.plans.first?.amount == 7890 && wowCatalog.plans.first?.sourceURL != nil, "sourced wow reference plan")
check(naverCatalog.plans.first(where: { $0.yearly })?.amount == 46800, "Naver annual billed amount")
check(CatalogService.all.contains { $0.matches("쿠팡와우") } && CatalogService.all.contains { $0.matches("네이버 플러스") }, "membership aliases")
var wowItem = Subscription(name: wowCatalog.name, amount: 7890, yearly: false, billingDate: date(2026,10,25), serviceID: wowCatalog.id, channel: .web)
var naverItem = Subscription(name: naverCatalog.name, amount: 46800, yearly: true, billingDate: date(2026,10,25), serviceID: naverCatalog.id, channel: .web)
var directItem = Subscription(name: "직접 입력", amount: 2100, yearly: false, billingDate: date(2026,10,25))
let membershipItems = [wowItem, naverItem, directItem]
let costMonth = membershipItems.reduce(0) { $0 + $1.currentMonthlyAmount(on: date(2026,10,25), calendar: calendar) }
check(costMonth == 13890, "membership monthly total")
check(membershipItems.reduce(0) { $0 + $1.currentAnnualAmount(on: date(2026,10,25), calendar: calendar) } == 166680, "membership annualized total")
check(membershipItems.flatMap { $0.thisMonthPayments(on: date(2026,10,25), calendar: calendar) }.reduce(0) { $0 + $1.amount } == 56790, "membership monthly schedule total differs from normalized total")
check(wowItem.resolvedBenefits().allSatisfy { $0.usage == .needsReview && $0.origin == .catalog }, "benefits default review state")
check(!wowItem.resolvedBenefits().isEmpty && !naverItem.resolvedBenefits().isEmpty, "official benefits loaded")
let selectedOptions = naverItem.resolvedBenefits().filter { $0.definition.selectionGroup != nil }
check(selectedOptions.count >= 2 && selectedOptions.allSatisfy { $0.usage == .needsReview && !$0.definition.conditions.isEmpty }, "choice benefits not automatically treated as all in use")
let original = wowItem.resolvedBenefits().first!
let originalJSON = try JSONEncoder().encode(wowItem)
let beforeNotices = ReminderPlanner.events(for: [wowItem], defaults: enabled, now: date(2026,10,1), calendar: calendar)
wowItem.setBenefitUsage(.unused, id: original.id)
check(wowItem.resolvedBenefits().first?.usage == .unused, "usage selection stored separately")
check(wowCatalog.membership?.benefits.first == original.definition, "catalog immutable after usage change")
var edited = original.definition; edited.title = "나의 배송 혜택"; edited.conditions = "내 가입 조건"; edited.checkedAt = nil
wowItem.saveBenefit(edited, catalogBased: true)
check(wowItem.resolvedBenefits().first?.definition.title == "나의 배송 혜택" && wowItem.resolvedBenefits().first?.origin == .edited, "user edit overlays catalog")
check(wowCatalog.membership?.benefits.first?.title != "나의 배송 혜택", "official catalog original remains intact")
let custom = BenefitDefinition(id: "custom.check", title: "매장 할인", category: .shopping, conditions: "내 조건", sourceURL: nil, checkedAt: "2026-10-25")
directItem.saveBenefit(custom, catalogBased: false)
check(directItem.customBenefits?.first?.checkedAt == nil, "no fabricated check date without source")
check(directItem.resolvedBenefits().first?.definition.title == "매장 할인", "custom membership benefits")
var editedFinancial = wowItem; editedFinancial.amount = 1; editedFinancial.status = .cancelled; editedFinancial.billingDate = date(2030,1,1)
let originalFinancial = try JSONDecoder().decode(Subscription.self, from: originalJSON)
let applied = originalFinancial.applyingBenefitChanges(from: editedFinancial)
check(applied.amount == 7890 && applied.currentStatus == .active && applied.billingDate == wowItem.billingDate, "benefit-only save cannot alter financial or status fields")
check(applied.benefitUsage?[original.id] == .unused, "benefit-only save retains user states")
let afterNotices = ReminderPlanner.events(for: [applied], defaults: enabled, now: date(2026,10,1), calendar: calendar)
check(beforeNotices.map(\.id) == afterNotices.map(\.id) && beforeNotices.map(\.fireDate) == afterNotices.map(\.fireDate), "benefit state does not change notification plan")
check(applied.currentMonthlyAmount(on: date(2026,10,25), calendar: calendar) == 7890, "benefit state does not change cost")
var removed = wowItem; removed.removeBenefit(removed.resolvedBenefits().first!)
check(!removed.resolvedBenefits().contains { $0.id == original.id }, "hide catalog benefit")
removed.hiddenBenefitIDs = []
check(removed.resolvedBenefits().first?.definition.title == "나의 배송 혜택", "restore catalog benefit preserves edit")
let customResolved = directItem.resolvedBenefits().first!; directItem.removeBenefit(customResolved)
check(directItem.resolvedBenefits().isEmpty, "delete custom benefit")
directItem.saveBenefit(custom, catalogBased: false)
let storedMemberships = try JSONDecoder().decode([Subscription].self, from: JSONEncoder().encode([wowItem, naverItem, directItem]))
check(storedMemberships[0].benefitEdits?[original.id]?.title == "나의 배송 혜택" && storedMemberships[0].benefitUsage?[original.id] == .unused, "benefit edits and usage restored after persistence")
check(storedMemberships[2].customBenefits?.count == 1, "custom benefits restored")
check(legacy.customBenefits == nil && legacy.benefitUsage == nil && legacy.managementURL == nil, "legacy no benefit fields loads")
check(BenefitComparison.membershipCount(BenefitComparison.entries([wowItem,naverItem], category: .video)) == 2, "similar category counts memberships")
check(BenefitComparison.membershipCount(BenefitComparison.entries([wowItem], category: .delivery)) == 1, "multiple benefits in same membership counted once")
check(BenefitComparison.entries([wowItem,naverItem], unusedOnly: true).count == 1, "unused benefit review filter")
var endedMembership = naverItem; endedMembership.status = .cancelled; endedMembership.cancellationEffectiveDate = date(2026,10,25)
check(BenefitComparison.entries([endedMembership]).isEmpty, "cancelled memberships excluded from active comparison")
var pendingMembership = naverItem; pendingMembership.status = .planned
check(!BenefitComparison.entries([pendingMembership]).isEmpty, "planned cancellations remain comparable")
var ownPrice = naverItem; ownPrice.amount = 12345
check(ownPrice.amount == 12345 && naverCatalog.plans.first?.amount == 4900, "catalog updates do not overwrite stored amount")
check(wowItem.recurringPrice(on: date(2026,10,25), calendar: calendar) == 7890, "comparison uses full membership fee")
check(MembershipLinks.resolve(wowItem, kind: .benefits)?.url.host == "news.coupang.com", "official wow benefit link")
check(MembershipLinks.resolve(wowItem, kind: .management)?.url.absoluteString == "https://loyalty.coupang.com/loyalty/management/home", "signed-in official direct management route")
check(MembershipLinks.resolve(naverItem, kind: .management)?.url.absoluteString == "https://nid.naver.com/membership/my", "Naver management link")
check(MembershipLinks.resolve(naverItem, kind: .cancellation)?.url.host == "help.naver.com", "Naver cancellation guide")
var appleMember = naverItem; appleMember.channel = .apple
check(MembershipLinks.resolve(appleMember, kind: .management)?.url.host == "apps.apple.com", "management follows Apple billing")
check(MembershipLinks.resolve(appleMember, kind: .cancellation)?.url.host == "support.apple.com", "cancellation follows Apple billing")
var playMember = naverItem; playMember.channel = .google
check(MembershipLinks.resolve(playMember, kind: .management)?.url.host == "play.google.com", "management follows Google billing")
var unknownChannel = wowItem; unknownChannel.channel = .unknown
check(MembershipLinks.resolve(unknownChannel, kind: .management) == nil, "unknown channel no invented management URL")
check(MembershipLinks.resolve(directItem, kind: .benefits) == nil, "custom membership missing links stay unavailable")
directItem.benefitInfoURL = "https://example.com/help"; directItem.managementURL = "https://example.com/account"
check(MembershipLinks.resolve(directItem, kind: .benefits)?.isOfficial == false && MembershipLinks.resolve(directItem, kind: .benefits)?.checkedAt == nil, "user URL not claimed officially verified")
check(MembershipLinks.resolve(directItem, kind: .management)?.url.absoluteString == "https://example.com/account", "manual management link preserved")
for catalog in [wowCatalog,naverCatalog] {
    for benefit in catalog.membership!.benefits {
        check(benefit.sourcedDate != nil && Subscription.safeURL(benefit.sourceURL) != nil, "official benefits source and check date together")
    }
}
print("PASS: \(count) total checks including membership benefits")
let freshDefinition = BenefitDefinition(id: original.id, title: "변경된 공식 혜택 이름", category: .delivery, conditions: "새 공식 조건", sourceURL: "https://news.coupang.com/archives/64216/", checkedAt: "2026-10-25")
let changedMembership = CatalogMembership(benefits: [freshDefinition], benefitsPage: wowCatalog.membership?.benefitsPage, managementPage: wowCatalog.membership?.managementPage, cancellationPage: wowCatalog.membership?.cancellationPage)
let changedCatalog = CatalogService(id: wowCatalog.id, name: wowCatalog.name, displayName: wowCatalog.displayName, category: wowCatalog.category, aliases: wowCatalog.aliases, source: wowCatalog.source, note: wowCatalog.note, plans: wowCatalog.plans, membership: changedMembership)
check(wowItem.resolvedBenefits(catalog: changedCatalog).first?.definition.title == "나의 배송 혜택", "catalog change preserves user overlay")
check(wowItem.resolvedBenefits(catalog: changedCatalog).first?.usage == .unused, "catalog change preserves usage state")
let removedMembership = CatalogMembership(benefits: [], benefitsPage: nil, managementPage: nil, cancellationPage: nil)
let removedCatalog = CatalogService(id: wowCatalog.id, name: wowCatalog.name, displayName: wowCatalog.displayName, category: wowCatalog.category, aliases: wowCatalog.aliases, source: wowCatalog.source, note: wowCatalog.note, plans: wowCatalog.plans, membership: removedMembership)
check(wowItem.resolvedBenefits(catalog: removedCatalog).contains { $0.definition.title == "나의 배송 혜택" }, "removed catalog entry does not discard saved user edit")
print("PASS: \(count) final checks")
check(MembershipLinks.subscriptionPage(appleMember)?.url.host == "apps.apple.com", "subscription page Apple channel")
check(MembershipLinks.subscriptionPage(playMember)?.url.host == "play.google.com", "subscription page Google channel")
check(MembershipLinks.subscriptionPage(directItem)?.isOfficial == false, "manual subscription page marked manual")
check(MembershipLinks.subscriptionPage(unknownChannel)?.url.host == "loyalty.coupang.com", "unknown route uses verified management page")
var youtubePageItem = Subscription(name: "YouTube", amount: 14900, yearly: false, billingDate: Date(), serviceID: "service-001")
check(MembershipLinks.subscriptionPage(youtubePageItem)?.url.path == "/paid_memberships", "YouTube official memberships path")
youtubePageItem.serviceID = nil
check(MembershipLinks.subscriptionPage(youtubePageItem) == nil, "unidentified manual service no invented URL")
print("PASS: \(count) checks including subscription page links")

// Stable monthly payments must outlive the finite one-off queue without duplicate dates.
let reservationNow = day(date(2026,10,1))

let steadyItems = (1...12).map { Subscription(name: "반복 \($0)", amount: 9900, yearly: false, billingDate: date(2026,9,15)) }
let steadyPlan = ReminderReservationPlanner.plan(items: steadyItems, preferences: ReminderPreferences(enabled: true, days: [0,1,3,7]), now: reservationNow, calendar: calendar)
check(steadyPlan.reservations.count == 48, "12 stable monthly plans need only 48 repeating reservations")
check(steadyPlan.reservations.allSatisfy { $0.repeating != nil }, "steady monthly plans repeat without opening the app")
check(steadyPlan.limitedThrough == nil, "no false finite coverage for fully repeating plans")
check(Set(steadyPlan.reservations.map { $0.event.id }).count == 48, "repeating reservations deduplicated")
let monthEndPlans = (1...12).map { Subscription(name: "월말 \($0)", amount: 9900, yearly: false, billingDate: date(2026,8,31)) }
let limitedPlan = ReminderReservationPlanner.plan(items: monthEndPlans, preferences: ReminderPreferences(enabled: true, days: [0,1,3,7]), now: reservationNow, calendar: calendar)
check(limitedPlan.reservations.count == 60 && limitedPlan.limitedThrough != nil, "month-end finite queue exposes coverage limit")
check(limitedPlan.reservations.allSatisfy { $0.repeating == nil }, "never repeat a 31st-day charge on missing dates")
var changingPrice = steadyItems[0]; changingPrice.afterAmount = 15000; changingPrice.amountEffectiveDate = date(2026,11,1)
check(ReminderReservationPlanner.plan(items: [changingPrice], preferences: ReminderPreferences(enabled: true), now: reservationNow, calendar: calendar).reservations.allSatisfy { $0.repeating == nil }, "future price change cannot leak old repeating price")
let futureAnchor = Subscription(name: "미래 가입", amount: 9900, yearly: false, billingDate: date(2027,2,15))
let futurePlan = ReminderReservationPlanner.plan(items: [futureAnchor], preferences: ReminderPreferences(enabled: true), now: reservationNow, calendar: calendar)
check(futurePlan.reservations.allSatisfy { $0.repeating == nil }, "future anchor must not start repeats early")
let annualSafe = Subscription(name: "연간 반복", amount: 120000, yearly: true, billingDate: date(2024,10,15))
check(ReminderReservationPlanner.plan(items: [annualSafe], preferences: ReminderPreferences(enabled: true,days:[0,3,30]), now: reservationNow, calendar: calendar).reservations.allSatisfy { $0.repeating != nil }, "stable annual dates repeat")
let leapAnchor = Subscription(name: "윤년", amount: 120000, yearly: true, billingDate: date(2024,2,29))
check(ReminderReservationPlanner.plan(items: [leapAnchor], preferences: ReminderPreferences(enabled: true), now: reservationNow, calendar: calendar).reservations.allSatisfy { $0.repeating == nil }, "leap anchor remains accurate one-off")
let crossMonth = Subscription(name: "월초", amount: 9900, yearly: false, billingDate: date(2026,9,1))
check(ReminderReservationPlanner.plan(items:[crossMonth], preferences:ReminderPreferences(enabled:true,days:[3]),now:reservationNow,calendar:calendar).reservations.allSatisfy { $0.repeating == nil }, "prior-month length changes are not flattened into fixed-day repeats")
var badWrite = trial; badWrite.amount = .nan
let failureRepo = SubscriptionRepository(defaults: testDefaults, key: "failed-save-check")
try failureRepo.save([trial])
let beforeBadWrite = try failureRepo.load()
do { try failureRepo.save([badWrite]); check(false, "nonfinite save should fail") } catch { check((try! failureRepo.load()).map(\.id) == beforeBadWrite.map(\.id), "failed save preserves previous data") }
print("PASS: \(count) checks including repeating reservations and failed-save preservation")
