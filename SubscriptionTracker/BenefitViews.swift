import SwiftUI

struct BenefitsSection: View {
    @EnvironmentObject private var store: SubscriptionStore
    let subscriptionID: UUID
    let onEdit: (BenefitEditTarget) -> Void
    let onDelete: (ResolvedBenefit) -> Void
    private var item: Subscription? { store.items.first { $0.id == subscriptionID } }
    var body: some View {
        if let item {
            Section("내 멤버십 혜택") {
                ForEach(item.resolvedBenefits()) { benefit in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.membershipAccent).padding(.top, 2)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(benefit.definition.title).font(.subheadline.weight(.semibold))
                            if !benefit.definition.conditions.isEmpty {
                                Text(benefit.definition.conditions).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer(minLength: 0)

                    }.padding(.vertical, 7)
                }
                if item.resolvedBenefits().isEmpty { Text("공식 혜택 정보를 확인 중이에요.").font(.subheadline).foregroundStyle(.secondary) }
                if !(item.hiddenBenefitIDs ?? []).isEmpty {
                    Button("숨긴 기본 혜택 다시 표시") { var changed = item; changed.hiddenBenefitIDs = []; store.saveBenefitChanges(changed) }
                }
            }

        }
    }

}
struct BenefitSourceView: View {
    let benefit: ResolvedBenefit
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(benefit.originLabel).font(.caption).foregroundStyle(.secondary)
            if let url = Subscription.safeURL(benefit.definition.sourceURL) {
                Link(benefit.origin == .catalog ? "공식 혜택 안내" : "저장한 혜택 안내", destination: url).font(.caption)
                if let date = benefit.definition.sourcedDate { Text("정보 확인일 \(date)").font(.caption).foregroundStyle(.secondary) }
                else { Text("확인일 미입력").font(.caption).foregroundStyle(.secondary) }
            } else { Text("혜택 안내 준비 중 · 출처 미입력").font(.caption).foregroundStyle(.secondary) }
            if benefit.definition.selectionGroup != nil { Text("선택형 혜택 · 실제 선택한 옵션을 확인해 주세요.").font(.caption).foregroundStyle(.orange) }
        }
    }
}
struct BenefitEditTarget: Identifiable {
    var id: String { definition.id }
    let definition: BenefitDefinition
    let catalogBased: Bool
    let clearDate: Bool
}
struct BenefitEditor: View {
    @Environment(\.dismiss) private var dismiss
    let target: BenefitEditTarget
    let onSave: (BenefitDefinition) -> Void
    @State private var draft: BenefitDefinition
    @State private var source: String
    @State private var dateKnown: Bool
    @State private var checkedDate: Date
    init(target: BenefitEditTarget, onSave: @escaping (BenefitDefinition) -> Void) {
        self.target = target; self.onSave = onSave
        _draft = State(initialValue: target.definition)
        _source = State(initialValue: target.definition.sourceURL ?? "")
        _dateKnown = State(initialValue: !target.clearDate && target.definition.sourcedDate != nil)
        _checkedDate = State(initialValue: Self.formatter.date(from: target.definition.checkedAt ?? "") ?? Date())
    }
    private static var formatter: DateFormatter { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f }
    private var valid: Bool { !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (source.isEmpty || Subscription.safeURL(source) != nil) }
    var body: some View {
        Form {
            Section("내 혜택 정보") {
                TextField("혜택 이름", text: $draft.title)
                Picker("혜택 분류", selection: $draft.category) { ForEach(BenefitCategory.allCases, id: \.self) { Text($0.title).tag($0) } }
                TextField("가입·선택 옵션, 대상 상품 등 조건", text: $draft.conditions, axis: .vertical).lineLimit(2...6)
            }
            Section("안내와 출처") {
                TextField("혜택 안내 URL (선택)", text: $source).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                if !source.isEmpty && Subscription.safeURL(source) == nil { Text("http 또는 https 주소를 입력해 주세요.").font(.caption).foregroundStyle(.orange) }
                if Subscription.safeURL(source) != nil {
                    Toggle("직접 확인한 날짜 기록", isOn: $dateKnown)
                    if dateKnown { DatePicker("정보 확인일", selection: $checkedDate, in: ...Date(), displayedComponents: .date) }
                }
                Text("입력한 내용은 내 혜택으로 저장돼요. 공식 카탈로그 원본과 구분하며, 출처가 없으면 확인일을 기록하지 않아요.").font(.caption).foregroundStyle(.secondary)
            }
            Section { Button("혜택 저장", action: save).disabled(!valid) }
        }
        .scrollContentBackground(.hidden).background(Color.membershipBackground)
        .navigationTitle("혜택 편집").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("저장", action: save).disabled(!valid) }
        }
    }
    private func save() {
        guard valid else { return }
        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.sourceURL = source.isEmpty ? nil : source
        draft.checkedAt = dateKnown && Subscription.safeURL(source) != nil ? Self.formatter.string(from: checkedDate) : nil
        onSave(draft)
    }
}
struct MembershipLinkSection: View {
    let item: Subscription
    var body: some View {
        Section("공식 페이지에서 관리") {
            LabeledContent("가입·결제 경로", value: (item.channel ?? .unknown).title)
            if let memo = item.accountMemo, !memo.isEmpty { LabeledContent("가입 계정 메모", value: memo) }
            ForEach(MembershipPageKind.allCases, id: \.self) { kind in
                if let destination = MembershipLinks.resolve(item, kind: kind) {
                    VStack(alignment: .leading, spacing: 5) {
                        Link(kind.title, destination: destination.url)
                        if !destination.instructions.isEmpty { Text(destination.instructions).font(.caption).foregroundStyle(.secondary) }
                        if destination.isOfficial, let date = destination.checkedAt { Text("공식 안내 확인일 \(date)").font(.caption).foregroundStyle(.secondary) }
                        else if !destination.isOfficial { Text("사용자 입력 링크 · 공식 여부 직접 확인").font(.caption).foregroundStyle(.secondary) }
                    }.padding(.vertical, 3)
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(kind.title) · 안내 준비 중").foregroundStyle(.secondary)
                        if kind != .benefits && (item.channel ?? .unknown) == .unknown { Text("수정 화면에서 가입·결제 경로를 확인해 주세요.").font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
            Text("링크를 여는 것만으로 해지되지 않아요. 실제 해지는 외부 서비스에서 직접 진행하고, 앱에는 별도로 완료 기록을 남겨주세요.").font(.caption).foregroundStyle(.secondary)
        }
    }
}
struct BenefitsComparisonView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @State private var category = "전체"
    @State private var unusedOnly = false
    var body: some View {
        List {
            Section {
                Text("비슷한 혜택이 있어요").font(.headline)
                Text("같은 분류여도 제공 내용은 다를 수 있어요. 선택형 혜택과 가입 조건, 실제 이용 여부를 비교해보세요. 금액은 개별 혜택 가격이 아닌 전체 멤버십 요금이에요.")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("혜택 분류", selection: $category) { Text("전체").tag("전체"); ForEach(BenefitCategory.allCases, id: \.self) { Text($0.title).tag($0.rawValue) } }
                Toggle("‘안 씀’으로 표시한 혜택만 보기", isOn: $unusedOnly)
            }
            ForEach(BenefitCategory.allCases.filter { category == "전체" || category == $0.rawValue }, id: \.self) { group in
                let entries = BenefitComparison.entries(store.items, category: group, unusedOnly: unusedOnly)
                if !entries.isEmpty {
                    Section("\(group.title) · 멤버십 \(BenefitComparison.membershipCount(entries))개") {
                        if BenefitComparison.membershipCount(entries) > 1 { Text("비슷한 분류의 혜택이 있어요. 내용과 이용 여부를 확인해보세요.").font(.caption).foregroundStyle(.secondary) }
                        ForEach(entries) { entry in ComparisonBenefitRow(entry: entry) }
                    }
                }
            }
            if BenefitComparison.entries(store.items, category: BenefitCategory(rawValue: category), unusedOnly: unusedOnly).isEmpty {
                Text(unusedOnly ? "‘안 씀’으로 표시한 혜택이 없어요." : "비교할 혜택이 없어요. 멤버십 상세에서 혜택을 추가해 주세요.").foregroundStyle(.secondary)
            }
        }.scrollContentBackground(.hidden).background(Color.membershipBackground)
        .navigationTitle("혜택 비교")
    }
}
private struct ComparisonBenefitRow: View {
    @EnvironmentObject private var store: SubscriptionStore
    let entry: BenefitComparisonEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(entry.subscription.name).font(.headline)
            Text("전체 멤버십 요금 \(entry.subscription.recurringPrice(on: Date()).formatted(.currency(code: entry.subscription.currencyCode)))/\(entry.subscription.yearly ? "년" : "월")")
                .font(.caption).foregroundStyle(.secondary)
            Text(entry.benefit.definition.title).fontWeight(.medium)
            Text(entry.benefit.definition.conditions).font(.caption)
            Picker("이용 상태", selection: Binding(get: { entry.benefit.usage }, set: { usage in
                guard var latest = store.items.first(where: { $0.id == entry.subscription.id }) else { return }
                latest.setBenefitUsage(usage, id: entry.benefit.id); store.saveBenefitChanges(latest)
            })) { ForEach(BenefitUsage.allCases, id: \.self) { Text($0.title).tag($0) } }.pickerStyle(.menu)
            BenefitSourceView(benefit: entry.benefit)
            NavigationLink("멤버십 상세 보기") { SubscriptionDetailView(id: entry.subscription.id) }
        }.padding(.vertical, 6)
    }
}


struct MembershipQuickActions: View {
    let item: Subscription
    var body: some View {
        let benefits = item.resolvedBenefits()
        if !benefits.isEmpty {
            Text("혜택 상태 · 사용 중 \(benefits.filter { $0.usage == .using }.count) · 안 씀 \(benefits.filter { $0.usage == .unused }.count) · 확인 필요 \(benefits.filter { $0.usage == .needsReview }.count)")
                .font(.caption).foregroundStyle(.secondary)
        }
        HStack(spacing: 8) {
            ForEach(MembershipPageKind.allCases, id: \.self) { kind in
                if let destination = MembershipLinks.resolve(item, kind: kind) {
                    Link(kind == .benefits ? "혜택 안내" : (kind == .management ? "관리" : "해지 안내"), destination: destination.url)
                        .font(.caption).buttonStyle(.bordered).accessibilityLabel(kind.title)
                }
            }
        }
        Text("바로가기는 공식·저장된 안내를 열어요. 실제 해지 완료 기록은 아래에서 별도로 남길 수 있어요.")
            .font(.caption).foregroundStyle(.secondary)
    }
}
