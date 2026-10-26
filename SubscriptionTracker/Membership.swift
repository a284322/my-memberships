import Foundation

enum BenefitCategory: String, Codable, CaseIterable {
    case delivery, video, music, shopping, points, other
    var title: String {
        switch self { case .delivery: return "배송"; case .video: return "영상"; case .music: return "음악"; case .shopping: return "쇼핑 할인"; case .points: return "포인트·적립"; case .other: return "기타" }
    }
}
enum BenefitUsage: String, Codable, CaseIterable {
    case using, unused, needsReview
    var title: String { switch self { case .using: return "사용 중"; case .unused: return "안 씀"; case .needsReview: return "확인 필요" } }
}
struct BenefitDefinition: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var category: BenefitCategory
    var conditions: String
    var sourceURL: String? = nil
    var checkedAt: String? = nil
    var selectionGroup: String? = nil
    /// Never show a dated assertion without a usable supporting URL.
    var sourcedDate: String? { Subscription.safeURL(sourceURL) == nil ? nil : checkedAt }
}
struct VerifiedPage: Codable {
    let url: String
    let directions: String
    let checkedAt: String?
}
struct CatalogMembership: Decodable {
    let benefits: [BenefitDefinition]
    let benefitsPage: VerifiedPage?
    let managementPage: VerifiedPage?
    let cancellationPage: VerifiedPage?
}
struct ResolvedBenefit: Identifiable {
    var id: String { definition.id }
    let definition: BenefitDefinition
    let usage: BenefitUsage
    let origin: Origin
    let original: BenefitDefinition?
    enum Origin { case catalog, edited, custom }
    var originLabel: String { switch origin { case .catalog: return "공식 카탈로그"; case .edited: return "내가 수정한 혜택"; case .custom: return "직접 입력한 혜택" } }
}
extension Subscription {
    func resolvedBenefits(catalog: CatalogService? = nil) -> [ResolvedBenefit] {
        let catalog = catalog ?? CatalogService.all.first { $0.id == serviceID }
        let originals = catalog?.membership?.benefits ?? []
        let hidden = Set(hiddenBenefitIDs ?? [])
        let edits = benefitEdits ?? [:]
        var result = originals.filter { !hidden.contains($0.id) }.map { original in
            ResolvedBenefit(definition: edits[original.id] ?? original, usage: benefitUsage?[original.id] ?? .needsReview,
                            origin: edits[original.id] == nil ? .catalog : .edited, original: original)
        }
        let originalIDs = Set(originals.map(\.id))
        // Keep user edits even when a later catalog removes an original benefit.
        for key in edits.keys.sorted() where !originalIDs.contains(key) && !hidden.contains(key) {
            if let definition = edits[key] { result.append(.init(definition: definition, usage: benefitUsage?[key] ?? .needsReview, origin: .edited, original: nil)) }
        }
        result += (customBenefits ?? []).filter { !hidden.contains($0.id) }.map { .init(definition: $0, usage: benefitUsage?[$0.id] ?? .needsReview, origin: .custom, original: nil) }
        return result
    }
    mutating func setBenefitUsage(_ usage: BenefitUsage, id: String) {
        if benefitUsage == nil { benefitUsage = [:] }; benefitUsage?[id] = usage
    }
    mutating func saveBenefit(_ definition: BenefitDefinition, catalogBased: Bool) {
        var definition = definition
        if Subscription.safeURL(definition.sourceURL) == nil { definition.checkedAt = nil }
        if catalogBased {
            if benefitEdits == nil { benefitEdits = [:] }; benefitEdits?[definition.id] = definition
        } else {
            var values = customBenefits ?? []
            if let index = values.firstIndex(where: { $0.id == definition.id }) { values[index] = definition } else { values.append(definition) }
            customBenefits = values
        }
        hiddenBenefitIDs?.removeAll { $0 == definition.id }
    }
    mutating func removeBenefit(_ resolved: ResolvedBenefit) {
        if resolved.origin == .custom {
            customBenefits?.removeAll { $0.id == resolved.id }; benefitUsage?.removeValue(forKey: resolved.id)
        } else { hiddenBenefitIDs = Array(Set((hiddenBenefitIDs ?? []) + [resolved.id])).sorted() }
    }
    func applyingBenefitChanges(from edited: Subscription) -> Subscription {
        var result = self
        result.customBenefits = edited.customBenefits; result.benefitEdits = edited.benefitEdits
        result.hiddenBenefitIDs = edited.hiddenBenefitIDs; result.benefitUsage = edited.benefitUsage
        return result
    }
}
struct BenefitComparisonEntry: Identifiable {
    var id: String { subscription.id.uuidString + benefit.id }
    let subscription: Subscription
    let benefit: ResolvedBenefit
}
enum BenefitComparison {
    static func entries(_ items: [Subscription], category: BenefitCategory? = nil, unusedOnly: Bool = false) -> [BenefitComparisonEntry] {
        items.filter { $0.currentStatus != .cancelled }.flatMap { item in
            item.resolvedBenefits().filter { (category == nil || $0.definition.category == category) && (!unusedOnly || $0.usage == .unused) }
                .map { BenefitComparisonEntry(subscription: item, benefit: $0) }
        }
    }
    static func membershipCount(_ entries: [BenefitComparisonEntry]) -> Int { Set(entries.map { $0.subscription.id }).count }
}
enum MembershipPageKind: String, CaseIterable {
    case benefits, management, cancellation
    var title: String { switch self { case .benefits: return "혜택 자세히 보기"; case .management: return "멤버십 관리"; case .cancellation: return "해지 방법 보기" } }
}
struct MembershipDestination {
    let url: URL
    let instructions: String
    let checkedAt: String?
    let isOfficial: Bool
}
enum MembershipLinks {
    static func subscriptionPage(_ item: Subscription) -> MembershipDestination? {
        if let destination = resolve(item, kind: .management) { return destination }
        guard let service = CatalogService.all.first(where: { $0.id == item.serviceID }) else { return nil }
        if (item.channel ?? .unknown) == .unknown, let page = service.membership?.managementPage,
           let url = Subscription.safeURL(page.url) {
            return .init(url: url, instructions: page.directions + " Apple·Google에서 결제했다면 해당 스토어에서 확인하세요.", checkedAt: page.checkedAt, isOfficial: true)
        }
        guard let url = Subscription.safeURL(service.source) else { return nil }
        return .init(url: url, instructions: "공식 페이지에서 로그인 후 계정·구독 메뉴를 확인하세요. 이용 기간과 갱신일은 가입한 결제 경로에 따라 달라요.", checkedAt: nil, isOfficial: true)
    }

    static func resolve(_ item: Subscription, kind: MembershipPageKind) -> MembershipDestination? {
        let manual: String?
        switch kind { case .benefits: manual = item.benefitInfoURL; case .management: manual = item.managementURL; case .cancellation: manual = item.cancellationURL }
        if let url = Subscription.safeURL(manual) { return .init(url: url, instructions: "사용자가 입력한 안내 링크예요. 방문한 사이트의 주소와 가입 조건을 확인해 주세요.", checkedAt: nil, isOfficial: false) }
        let channel = item.channel ?? .unknown
        if kind != .benefits && channel == .apple {
            return .init(url: URL(string: kind == .management ? "https://apps.apple.com/account/subscriptions" : "https://support.apple.com/ko-kr/118428")!, instructions: "Apple 계정으로 로그인하거나 iPhone 설정 → 이름 → 구독에서 관리하세요.", checkedAt: "2026-10-25", isOfficial: true)
        }
        if kind != .benefits && channel == .google {
            return .init(url: URL(string: kind == .management ? "https://play.google.com/store/account/subscriptions" : "https://support.google.com/googleplay/answer/7018481?hl=ko")!, instructions: "구독한 Google 계정으로 로그인 → 정기 결제에서 관리하세요.", checkedAt: "2026-10-25", isOfficial: true)
        }
        let membership = CatalogService.all.first { $0.id == item.serviceID }?.membership
        let page: VerifiedPage?
        switch kind {
        case .benefits: page = membership?.benefitsPage
        case .management: page = channel == .web ? membership?.managementPage : nil
        case .cancellation: page = channel == .web ? membership?.cancellationPage : nil
        }
        if let page, let url = Subscription.safeURL(page.url) { return .init(url: url, instructions: page.directions, checkedAt: page.checkedAt, isOfficial: true) }
        if kind == .cancellation, let guidance = CancellationGuidance.resolve(item) {
            return .init(url: guidance.url, instructions: guidance.label, checkedAt: "2026-10-25", isOfficial: true)
        }
        return nil
    }
}
