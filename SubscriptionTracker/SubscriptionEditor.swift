import SwiftUI

struct SubscriptionEditor: View {
    @Environment(\.dismiss) private var dismiss
    let existing: Subscription?
    let service: CatalogService?
    let onSave: (Subscription) -> Bool
    @State private var draft: Subscription
    @State private var amount: String
    @State private var afterText: String
    @State private var freeEnabled: Bool
    @State private var freeEndKnown: Bool
    @State private var freeStart: Date
    @State private var freeEnd: Date
    @State private var discountEnabled: Bool
    @State private var discountEnd: Date
    @State private var afterEnabled: Bool
    @State private var effectiveDate: Date
    @State private var purposeEndEnabled: Bool
    @State private var purposeEnd: Date
    @State private var reminderMode: Int
    @State private var reminder: ReminderPreferences
    @State private var selectedPlanID = ""
    @State private var saveFailed = false

    init(existing: Subscription?, service: CatalogService?, onSave: @escaping (Subscription) -> Bool) {
        self.existing = existing; self.service = service; self.onSave = onSave
        let initialPlan = existing == nil ? service?.plans.first : nil
        let initialChannel: BillingChannel = initialPlan?.channel.contains("App Store") == true ? .apple : (initialPlan?.channel.contains("웹") == true ? .web : .unknown)
        let item = existing ?? Subscription(name: service?.displayName ?? "", amount: initialPlan?.amount ?? 0, yearly: initialPlan?.yearly ?? false, billingDate: Date(), planName: initialPlan.map { "\($0.name) · \($0.channel)" }, serviceID: service?.id, category: service?.category, channel: initialChannel)
        _draft = State(initialValue: item)
        _amount = State(initialValue: existing.map { String($0.amount) } ?? initialPlan.map { String($0.amount) } ?? "")
        _selectedPlanID = State(initialValue: initialPlan?.id ?? "")
        _afterText = State(initialValue: item.afterAmount.map(String.init(describing:)) ?? "")
        _freeEnabled = State(initialValue: item.freeStartDate != nil)
        _freeEndKnown = State(initialValue: item.resolvedFreeEnd() != nil)
        _freeStart = State(initialValue: item.freeStartDate ?? Date())
        _freeEnd = State(initialValue: item.resolvedFreeEnd() ?? Date())
        _discountEnabled = State(initialValue: item.discountEndDate != nil)
        _discountEnd = State(initialValue: item.discountEndDate ?? Date())
        _afterEnabled = State(initialValue: item.afterAmount != nil)
        _effectiveDate = State(initialValue: item.amountEffectiveDate ?? Date())
        _purposeEndEnabled = State(initialValue: item.neededUntil != nil)
        _purposeEnd = State(initialValue: item.neededUntil ?? Date())
        _reminderMode = State(initialValue: item.reminderOverride.map { $0.enabled ? 1 : 2 } ?? 0)
        _reminder = State(initialValue: item.reminderOverride ?? ReminderPreferences(enabled: true))
    }
    private func optional(_ key: WritableKeyPath<Subscription, String?>) -> Binding<String> {
        Binding(get: { draft[keyPath: key] ?? "" }, set: { draft[keyPath: key] = $0 })
    }
    private var validationMessage: String? {
        if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "서비스 이름을 입력해 주세요." }
        if Subscription.validAmount(amount, allowZero: true) == nil { return "결제 금액을 0 이상으로 입력해 주세요." }
        if freeEnabled && freeEndKnown && Calendar.current.startOfDay(for: freeEnd) < Calendar.current.startOfDay(for: freeStart) { return "무료 마지막 날은 시작일보다 빠를 수 없어요." }
        if afterEnabled {
            if Subscription.validAmount(afterText, allowZero: true) == nil { return "종료 후 금액을 입력해 주세요." }
            if freeEnabled && freeEndKnown && Calendar.current.startOfDay(for: effectiveDate) <= Calendar.current.startOfDay(for: freeEnd) { return "금액 적용일은 무료 마지막 날보다 뒤로 설정해 주세요." }
            if discountEnabled && Calendar.current.startOfDay(for: effectiveDate) <= Calendar.current.startOfDay(for: discountEnd) { return "금액 적용일은 할인 마지막 날보다 뒤로 설정해 주세요." }
        }
        for value in [draft.cancellationURL, draft.benefitInfoURL, draft.managementURL] {
            if let value, !value.isEmpty, Subscription.safeURL(value) == nil { return "안내 URL은 http 또는 https 주소로 입력해 주세요." }
        }
        if reminderMode == 1 && reminder.validDays.filter({ draft.yearly || $0 != 30 }).isEmpty { return "개별 알림 날짜를 하나 이상 선택하거나 알림을 꺼주세요." }
        return nil
    }
    var body: some View {
        Form {
            serviceSection
            planSection
            paymentSection
            promotionSection
            purposeSection
            channelSection
            notificationSection
            if draft.currentStatus == .cancelled {
                Section("해지 기록") {
                    DatePicker("해지 효력 발생일", selection: Binding(get: { draft.cancellationEffectiveDate ?? Date() }, set: { draft.cancellationEffectiveDate = $0 }), displayedComponents: .date)
                    Text("해지 상태는 상세 화면에서 변경할 수 있어요.").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section {
                if saveFailed { Text("저장하지 못했어요. 입력 내용은 유지돼 있어요. 다시 저장해 주세요.").font(.caption).foregroundStyle(.red) }
                if let message = validationMessage { Text(message).font(.caption).foregroundStyle(.orange) }
                Button(existing == nil ? "구독 저장" : "변경 저장", action: save)
                    .frame(maxWidth: .infinity).disabled(validationMessage != nil).accessibilityIdentifier("subscription.save")
                Text("기록용 설정이에요. 실제 결제·해지는 각 서비스에서 직접 진행해 주세요.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden).background(Color.membershipBackground)
        .navigationTitle(existing == nil ? "구독 등록" : "구독 수정").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if existing != nil { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
            ToolbarItem(placement: .confirmationAction) { Button("저장", action: save).disabled(validationMessage != nil) }
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("입력 완료") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } }
        }
    }
    private var serviceSection: some View {
        Section("서비스") {
            TextField("서비스 이름", text: $draft.name).accessibilityIdentifier("subscription.name")
            if let service { Text(service.category).font(.caption).foregroundStyle(.secondary) }
        }
    }
    @ViewBuilder private var planSection: some View {
        if let service {
            Section("플랜 선택") {
                ForEach(service.plans) { plan in
                    Button {
                        selectedPlanID = plan.id; draft.planName = "\(plan.name) · \(plan.channel)"
                        amount = String(plan.amount); draft.currency = plan.currency; draft.yearly = plan.yearly
                        if existing == nil { draft.channel = plan.channel.contains("App Store") ? .apple : (plan.channel.contains("웹") ? .web : .unknown) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) { Text(plan.name); Text(plan.channel).font(.caption).foregroundStyle(.secondary) }
                            Spacer(); Text(plan.amount, format: .currency(code: plan.currency))
                            if selectedPlanID == plan.id { Image(systemName: "checkmark.circle.fill") }
                        }
                    }
                }
                if let chosen = service.plans.first(where: { $0.id == selectedPlanID }) {
                    if let conditions = chosen.conditions { Text(conditions).font(.caption).foregroundStyle(.secondary) }
                    if let url = Subscription.safeURL(chosen.sourceURL) { Link("요금 출처 확인", destination: url) }
                }
                if service.plans.isEmpty { Text("플랜과 실제 결제 금액을 직접 입력해 주세요.").font(.caption).foregroundStyle(.secondary) }
                else { Text("한국 참고 요금 · 2026.10.25 확인. 저장된 금액은 자동으로 바뀌지 않아요.").font(.caption).foregroundStyle(.secondary) }
                if let url = URL(string: service.source) { Link("공식 사이트에서 확인", destination: url) }
                if !service.note.isEmpty { Text(service.note).font(.caption).foregroundStyle(.secondary) }
            }
        }
    }
    private var paymentSection: some View {
        Section("결제 정보") {
            TextField("플랜 이름 (선택)", text: optional(\.planName))
            HStack { Text("현재 기본 금액"); TextField("금액", text: $amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing).accessibilityIdentifier("subscription.amount") }
            Picker("통화", selection: Binding(get: { draft.currencyCode }, set: { draft.currency = $0 })) { Text("원 KRW").tag("KRW"); Text("달러 USD").tag("USD") }
            Picker("결제 주기", selection: $draft.yearly) { Text("매월").tag(false); Text("매년").tag(true) }
            DatePicker("다음 결제일·주기 기준일", selection: $draft.billingDate, displayedComponents: .date)
            Text("무료 종료일과 첫 결제일은 각각 확인해 입력해 주세요. 연간 금액은 1년 동안 청구될 전체 금액이에요.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var promotionSection: some View {
        Section("무료체험·할인 종료") {
            Toggle("무료체험 기록", isOn: $freeEnabled)
            if freeEnabled {
                DatePicker("무료 시작일", selection: $freeStart, displayedComponents: .date)
                Toggle("무료 종료일을 알고 있어요", isOn: $freeEndKnown)
                if freeEndKnown { DatePicker("무료 마지막 날", selection: $freeEnd, displayedComponents: .date) }
                else { Text("종료일이 없으면 무료 기간을 추정하지 않아요. 금액 0원을 직접 기록하거나 종료일을 확인해 주세요.").font(.caption).foregroundStyle(.secondary) }
            }
            Toggle("할인 종료일 기록", isOn: $discountEnabled)
            if discountEnabled { DatePicker("할인 마지막 날", selection: $discountEnd, displayedComponents: .date) }
            Toggle("종료 후 금액·적용일 기록", isOn: $afterEnabled)
            if afterEnabled {
                HStack { Text("종료 후 금액"); TextField("금액", text: $afterText).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                DatePicker("금액 적용일", selection: $effectiveDate, displayedComponents: .date)
            }
            Text("무료 마지막 날까지는 0원이에요. 이후 금액은 별도 금액 적용일부터 바뀌며, 결제는 위 결제 일정에만 잡혀요.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var purposeSection: some View {
        Section("구독 목적") {
            TextField("예: 영어 면접 준비", text: optional(\.purpose), axis: .vertical).lineLimit(2...4)
            Toggle("필요 기간 종료일 기록", isOn: $purposeEndEnabled)
            if purposeEndEnabled {
                DatePicker("필요 기간 종료일", selection: $purposeEnd, displayedComponents: .date)
                Toggle("종료일에 유지 여부 알림", isOn: Binding(get: { draft.reviewReminder ?? false }, set: { value in
                    draft.reviewReminder = value
                    if value { Task { _ = await NotificationService.shared.requestPermission() } }
                }))
            }
        }
    }
    private var channelSection: some View {
        Section("가입·해지 정보") {
            Picker("가입·결제 경로", selection: Binding(get: { draft.channel ?? .unknown }, set: { draft.channel = $0 })) {
                ForEach(BillingChannel.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            TextField("가입 계정 메모 (선택)", text: optional(\.accountMemo)).textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField("혜택 안내 URL (선택)", text: optional(\.benefitInfoURL)).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField("멤버십 관리 URL (선택)", text: optional(\.managementURL)).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField("해지 안내 URL (선택)", text: optional(\.cancellationURL)).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
            Text("비밀번호는 입력하지 마세요.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var notificationSection: some View {
        Section("이 구독의 알림") {
            Picker("결제 전 알림", selection: $reminderMode) { Text("전체 기본 설정").tag(0); Text("개별 설정").tag(1); Text("끔").tag(2) }
                .onChange(of: reminderMode) { _, mode in if mode == 1 { Task { _ = await NotificationService.shared.requestPermission() } } }
            if reminderMode == 1 { ReminderFields(value: $reminder, yearly: draft.yearly) }
            NotificationPermissionNote()
            Text("결제 알림 설정은 무료·할인 종료 전 알림에도 적용돼요. 필요 기간 재검토 알림은 위에서 따로 선택해요.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private func save() {
        guard validationMessage == nil, let value = Subscription.validAmount(amount, allowZero: true) else { return }
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines); draft.amount = value
        draft.freeStartDate = freeEnabled ? freeStart : nil
        draft.freeEndDate = freeEnabled && freeEndKnown ? freeEnd : nil
        draft.promotionVersion = 1
        draft.discountEndDate = discountEnabled ? discountEnd : nil
        draft.afterAmount = afterEnabled ? Subscription.validAmount(afterText, allowZero: true) : nil
        draft.amountEffectiveDate = afterEnabled ? effectiveDate : nil
        draft.neededUntil = purposeEndEnabled ? purposeEnd : nil
        if !purposeEndEnabled { draft.reviewReminder = false }
        if reminderMode == 0 { draft.reminderOverride = nil }
        else { reminder.enabled = reminderMode == 1; draft.reminderOverride = reminder }
        saveFailed = !onSave(draft)
    }
}
