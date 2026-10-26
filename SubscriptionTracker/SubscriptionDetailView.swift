import SwiftUI

struct SubscriptionDetailView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss
    @State private var editing = false
    @State private var showingPaymentReminder = false
    @State private var showingBillingDate = false
    @State private var benefitEditor: BenefitEditTarget?
    @State private var benefitToDelete: ResolvedBenefit?
    @State private var confirmingDelete = false
    let id: UUID
    var now = Date()
    private var item: Subscription? { store.items.first { $0.id == id } }

    var body: some View {
        Group {
            if let item {
                List {
                    Section {
                        HStack(spacing: 14) {
                            ServiceLogo(serviceID: item.serviceID, name: item.name, size: 58)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.name).font(.title3.bold())
                                if let plan = item.planName, !plan.isEmpty { Text(plan).font(.subheadline).foregroundStyle(.secondary) }
                            }
                        }.padding(.vertical, 8)
                        if let next = item.upcomingPayment(on: now) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("다음 결제일").font(.subheadline).foregroundStyle(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(next.date, format: .dateTime.year().month().day())
                                        .font(.system(size: 27, weight: .bold)).foregroundStyle(Color.membershipAccent)
                                        .minimumScaleFactor(0.7).lineLimit(1)
                                    Spacer(minLength: 0)
                                    Button("수정") { showingBillingDate = true }
                                        .font(.subheadline.weight(.semibold)).buttonStyle(.bordered)
                                        .accessibilityLabel("다음 결제일 수정")
                                }
                                Text(next.amount, format: .currency(code: item.currencyCode)).font(.title2.weight(.semibold))
                            }.padding(.vertical, 12)
                        } else { Text("예상 결제 일정 없음") }
                        Button { showingPaymentReminder = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.badge")
                                Text("결제 전 알림받기")
                                Spacer()
                                let prefs = item.reminderOverride ?? store.preferences
                                Text(prefs.enabled ? prefs.validDays.filter { item.yearly || $0 != 30 }.map { $0 == 0 ? "당일" : "\($0)일 전" }.joined(separator: ", ") : "설정 안 함")
                                    .font(.caption).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.caption)
                            }.padding(.vertical, 5)
                        }.buttonStyle(.plain).foregroundStyle(Color.membershipAccent)
                        if item.yearly { LabeledContent("월 환산 비용", value: item.currentMonthlyAmount(on: now).formatted(.currency(code: item.currencyCode))) }
                        if let page = MembershipLinks.subscriptionPage(item) {
                            Link(destination: page.url) {
                                Label(page.isOfficial ? "구독 페이지에서 이용 기간 확인" : "저장한 구독 페이지 열기", systemImage: "arrow.up.right.square")
                                    .font(.subheadline.weight(.semibold)).padding(.vertical, 6)
                            }
                            Text(page.instructions).font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("구독 페이지 주소가 없어요. 수정에서 관리 URL을 추가할 수 있어요.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    promotionSection(item)
                    BenefitsSection(subscriptionID: item.id, onEdit: { benefitEditor = $0 }, onDelete: { benefitToDelete = $0 })
                    Section { Button("구독 삭제", role: .destructive) { confirmingDelete = true } }
                    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                        Section("검증용") {
                            Button("5초 후 테스트 알림") { Task { _ = await NotificationService.shared.requestPermission(); await NotificationService.shared.testNotification(for: item) } }
                        }
                    }
                }
                .sheet(isPresented: $showingBillingDate) {
                    NavigationStack { BillingDateEditor(id: item.id) }
                }
                .sheet(isPresented: $showingPaymentReminder) {
                    NavigationStack { SubscriptionPaymentReminderView(id: item.id) }
                }
                .sheet(isPresented: $editing) {
                    NavigationStack { SubscriptionEditor(existing: item, service: CatalogService.all.first { $0.id == item.serviceID }, onSave: { let saved = store.save($0); if saved { editing = false }; return saved }) }
                }
                .sheet(item: $benefitEditor) { target in
                    NavigationStack {
                        BenefitEditor(target: target) { definition in
                            guard var latest = self.item else { return }
                            latest.saveBenefit(definition, catalogBased: target.catalogBased)
                            store.saveBenefitChanges(latest); benefitEditor = nil
                        }
                    }
                }
                .confirmationDialog("이 혜택을 목록에서 삭제할까요?", isPresented: Binding(get: { benefitToDelete != nil }, set: { if !$0 { benefitToDelete = nil } }), titleVisibility: .visible) {
                    Button("혜택 삭제", role: .destructive) {
                        if let benefit = benefitToDelete, var latest = self.item { latest.removeBenefit(benefit); store.saveBenefitChanges(latest) }
                        benefitToDelete = nil
                    }
                    Button("취소", role: .cancel) {}
                } message: { Text("멤버십 자체는 유지돼요. 공식 기본 혜택은 나중에 다시 표시할 수 있어요.") }
                .confirmationDialog("구독 기록을 삭제할까요?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                    Button("기록 삭제", role: .destructive) { if store.delete(item) { dismiss() } }
                    Button("취소", role: .cancel) {}
                } message: { Text("이 기기에 저장된 구독 기록을 삭제해요. 실제 서비스는 해지되지 않아요.") }
            } else { ContentUnavailableView("구독을 찾을 수 없어요", systemImage: "questionmark.folder") }
        }
        .scrollContentBackground(.hidden).background(Color.membershipBackground)
        .navigationTitle("구독 상세").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { if item != nil { Button("수정") { editing = true } } } }
    }
    @ViewBuilder private func promotionSection(_ item: Subscription) -> some View {
        if item.freeStartDate != nil || item.discountEndDate != nil || item.afterAmount != nil {
            Section("무료체험·할인") {
                if let end = item.resolvedFreeEnd() { LabeledContent("무료 마지막 날", value: end.formatted(date: .abbreviated, time: .omitted)) }
                if let end = item.discountEndDate { LabeledContent("할인 마지막 날", value: end.formatted(date: .abbreviated, time: .omitted)) }
                if let value = item.afterAmount { LabeledContent("종료 후 금액", value: value.formatted(.currency(code: item.currencyCode))) }
                if let date = item.amountEffectiveDate { LabeledContent("금액 적용일", value: date.formatted(date: .abbreviated, time: .omitted)) }
            }
        }
    }
}

private struct BillingDateEditor: View {
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var saveFailed = false
    let id: UUID
    private var item: Subscription? { store.items.first { $0.id == id } }
    var body: some View {
        Form {
            Section {
                DatePicker("다음 결제일", selection: $date, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
            } footer: {
                Text("선택한 날짜를 기준으로 이후 결제 일정과 알림을 갱신해요. 실제 서비스의 결제일은 바뀌지 않아요.")
                if saveFailed { Text("저장하지 못했어요. 선택한 날짜는 유지돼 있어요. 다시 저장해 주세요.").foregroundStyle(.red) }
            }
        }
        .scrollContentBackground(.hidden).background(Color.membershipBackground)
        .navigationTitle("다음 결제일 수정").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    guard var latest = item else { return }
                    latest.billingDate = Calendar.current.startOfDay(for: date)
                    if store.save(latest) { dismiss() } else { saveFailed = true }
                }.disabled(item == nil)
            }
        }
        .onAppear { date = item?.upcomingPayment(on: Date())?.date ?? Date() }
    }
}
