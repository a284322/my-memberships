import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = SubscriptionStore()
    @ObservedObject private var notifications = NotificationService.shared
    @State private var showingAdd = false
    @State private var showingReceiptImport = false
    @State private var showingSettings = false
    @State private var selectedID: UUID?
    @State private var now = Date()
    private let dayTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private var active: [Subscription] { store.items.filter { $0.currentStatus != .cancelled }.sorted { ($0.upcomingPayment(on: now)?.date ?? .distantFuture) < ($1.upcomingPayment(on: now)?.date ?? .distantFuture) } }
    private var upcoming: [Subscription] { active.filter { $0.upcomingPayment(on: now) != nil } }
    private var withoutPayment: [Subscription] { active.filter { $0.upcomingPayment(on: now) == nil } }
    private var currencies: [String] { let codes = Set(store.items.map(\.currencyCode)); return codes.isEmpty ? ["KRW"] : codes.sorted() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("내 구독").font(.system(size: 30, weight: .bold))
                        Text("매달 나가는 비용, 한눈에").font(.subheadline).foregroundStyle(.secondary)
                    }.padding(.top, 8)
                    ForEach(currencies, id: \.self) { currency in
                        let items = store.items.filter { $0.currencyCode == currency }
                        let month = items.reduce(0) { $0 + $1.currentMonthlyAmount(on: now) }
                        let payments = items.flatMap { $0.thisMonthPayments(on: now) }
                        VStack(alignment: .leading, spacing: 22) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("월 환산 비용").font(.subheadline).foregroundStyle(Color.membershipInk.opacity(0.8))
                                Text(month, format: .currency(code: currency))
                                    .font(.system(size: 38, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
                            }
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("연 환산").font(.caption).foregroundStyle(Color.membershipInk.opacity(0.8))
                                    Text(month * 12, format: .currency(code: currency)).font(.subheadline.weight(.semibold))
                                }
                                Rectangle().fill(Color.membershipInk.opacity(0.18)).frame(width: 1, height: 35)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("이번 달 결제 예정").font(.caption).foregroundStyle(Color.membershipInk.opacity(0.8))
                                    Text(payments.reduce(0) { $0 + $1.amount }, format: .currency(code: currency)).font(.subheadline.weight(.semibold))
                                }
                            }
                            if payments.contains(where: \.yearly) {
                                Label("연간 구독 갱신이 포함돼요", systemImage: "calendar")
                                    .font(.caption).foregroundStyle(Color.membershipInk.opacity(0.85))
                            }
                        }.foregroundStyle(Color.membershipInk).padding(24).frame(maxWidth: .infinity, alignment: .leading)
                            .background(LinearGradient(colors: [.membershipYellowLight, .membershipYellowDeep], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
                    }
                    Button { showingAdd = true } label: {
                        Label("구독 추가하기", systemImage: "plus.circle.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.buttonStyle(.borderedProminent).tint(.membershipYellow).foregroundStyle(Color.membershipInk).controlSize(.large)
                    Button { showingReceiptImport = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 26, weight: .semibold))
                                .frame(width: 52, height: 52)
                                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 15))
                            VStack(alignment: .leading, spacing: 5) {
                                Text("사진·영수증으로 자동 입력").font(.headline)
                                Text("사진을 선택하면 구독 정보를 채워줘요").font(.caption)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right").font(.subheadline.weight(.bold))
                        }.foregroundStyle(Color.membershipInk)
                            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.membershipLime, in: RoundedRectangle(cornerRadius: 22))
                    }.buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("다가오는 결제일").font(.title3.weight(.bold))
                            Text("\(upcoming.count)").font(.caption.weight(.bold)).foregroundStyle(Color.membershipInk).padding(.horizontal, 9).padding(.vertical, 5).background(Color.membershipLime, in: Capsule())
                            Spacer()
                            Text("빠른 날짜순").font(.caption).foregroundStyle(.secondary)
                        }
                        if active.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "plus.square.on.square").font(.system(size: 30, weight: .light)).foregroundStyle(Color.membershipAccent)
                                Text("첫 구독을 추가해보세요").font(.headline)
                                Text("결제일과 혜택을 함께 관리해요").font(.subheadline).foregroundStyle(.secondary)
                                Button("구독 추가") { showingAdd = true }.buttonStyle(.borderedProminent).tint(.membershipYellow).foregroundStyle(Color.membershipInk).controlSize(.large)
                            }.frame(maxWidth: .infinity).padding(.vertical, 32).background(.white, in: RoundedRectangle(cornerRadius: 20))
                        } else {
                            VStack(spacing: 0) {
                                if upcoming.isEmpty { Text("다가오는 결제 일정이 없어요").font(.subheadline).foregroundStyle(.secondary).padding(20) }
                                ForEach(upcoming) { item in
                                    Button { selectedID = item.id } label: { UpcomingPaymentRow(item: item, now: now).padding(18) }.buttonStyle(.plain)
                                    if item.id != upcoming.last?.id { Divider().padding(.leading, 74) }
                                }
                            }.background(.white, in: RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    if !withoutPayment.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("결제 일정 없음").font(.headline)
                            VStack(spacing: 0) {
                                ForEach(withoutPayment) { item in
                                    Button { selectedID = item.id } label: { SubscriptionRow(item: item, now: now).padding(18) }.buttonStyle(.plain)
                                }
                            }.background(.white, in: RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    VStack(spacing: 0) {
                        NavigationLink { BenefitsComparisonView() } label: {
                            homeLink("혜택 비교", subtitle: "쓰고 있는 혜택을 살펴보세요", icon: "square.grid.2x2")
                        }
                    }.buttonStyle(.plain).background(.white, in: RoundedRectangle(cornerRadius: 20))
                    Text("환산 비용은 현재 요금 기준이며, 결제 예정액은 이번 달 일정의 합계예요. 실제 지출과 다를 수 있어요.")
                        .font(.caption).foregroundStyle(.secondary).lineSpacing(4).padding(.horizontal, 4)
                }.padding(.horizontal, 22).padding(.bottom, 28)
            }
            .background(Color.membershipBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("알림 설정", systemImage: "bell") { showingSettings = true } }
            }
            .disabled(store.storageUnavailable)
            .sheet(isPresented: $showingReceiptImport, onDismiss: { route(notifications.targetID) }) { NavigationStack { ReceiptImportView(onSave: store.save) } }
            .sheet(isPresented: $showingAdd, onDismiss: { route(notifications.targetID) }) { NavigationStack { ServicePickerView(onSave: store.save) } }
            .sheet(isPresented: $showingSettings, onDismiss: { route(notifications.targetID) }) { NavigationStack { NotificationSettingsView() } }
            .sheet(item: Binding(get: { selectedID.map(SubscriptionSelection.init) }, set: { selectedID = $0?.id })) { selection in
                NavigationStack { SubscriptionDetailView(id: selection.id, now: now).id(selection.id).toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { selectedID = nil } } } }
            }
            .onChange(of: notifications.targetID) { _, value in route(value) }
            .onReceive(dayTimer) { date in if !Calendar.current.isDate(now, inSameDayAs: date) { now = date; store.refreshNotifications() } }
            .onChange(of: scenePhase) { _, phase in if phase == .active { now = Date(); store.refreshNotifications(); route(notifications.targetID) } }
            .task { seedIfRequested(); store.refreshNotifications(); route(notifications.targetID) }
            .alert("확인이 필요해요", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("확인") { store.error = nil }
            } message: { Text(store.error ?? "") }
        }.environmentObject(store)
    }
    private func homeLink(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 19)).foregroundStyle(Color.membershipInk).frame(width: 38, height: 38).background(Color.membershipLime, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }.padding(18)
    }
    private func route(_ id: UUID?) {
        guard let id else { return }
        if showingReceiptImport { showingReceiptImport = false; return }
        if showingAdd { showingAdd = false; return }
        if showingSettings { showingSettings = false; return }
        if store.items.contains(where: { $0.id == id }) { selectedID = id }
        else { store.error = "삭제된 구독이거나 더 이상 열 수 없는 항목이에요." }
        notifications.targetID = nil
    }
    private func seedIfRequested() {
        if ProcessInfo.processInfo.arguments.contains("--uitesting"), ProcessInfo.processInfo.arguments.contains("--seed-membership-fixtures"), store.items.isEmpty {
            for (id, name, amount, yearly) in [("service-096", "쿠팡 와우 멤버십", 7890.0, false), ("service-097", "네이버플러스 멤버십", 46800.0, true), ("", "직접 입력 테스트 멤버십", 2100.0, false)] {
                var item = Subscription(name: name, amount: amount, yearly: yearly, billingDate: Date(), serviceID: id.isEmpty ? nil : id, channel: .web)
                if id.isEmpty { item.customBenefits = [.init(id: "custom.test", title: "매장 할인", category: .shopping, conditions: "사용자가 직접 입력한 조건")] }
                store.save(item)
            }
            return
        }
        guard ProcessInfo.processInfo.arguments.contains("--uitesting"), ProcessInfo.processInfo.arguments.contains("--seed-prd-fixtures"), store.items.isEmpty else { return }
        let cal = Calendar.current
        var item = Subscription(name: "PRD 테스트 넷플릭스", amount: 13500, yearly: false, billingDate: cal.date(byAdding: .day, value: 10, to: Date())!, planName: "스탠다드", serviceID: "service-002")
        item.purpose = "드라마 시청"; item.channel = .web
        store.save(item)
    }
}
private struct SubscriptionSelection: Identifiable { let id: UUID }

struct UpcomingPaymentRow: View {
    let item: Subscription
    let now: Date
    var body: some View {
        if let payment = item.upcomingPayment(on: now) {
            HStack(spacing: 12) {
                ServiceLogo(serviceID: item.serviceID, name: item.name, size: 42)
                VStack(alignment: .leading, spacing: 7) {
                    Text(payment.date, format: .dateTime.year().month().day()).font(.subheadline.weight(.bold)).foregroundStyle(Color.membershipAccent)
                    Text(item.name).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 7) {
                    Text(payment.amount, format: .currency(code: item.currencyCode)).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: payment.date)).day ?? 0
                    Text(days == 0 ? "오늘 예정" : days == 1 ? "내일 예정" : "\(days)일 후")
                        .font(.caption.weight(.medium)).foregroundStyle(Color.membershipInk)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(days <= 7 ? Color.membershipYellowLight : Color.membershipLime.opacity(0.65), in: Capsule())
                }
            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }
    }
}

struct SubscriptionRow: View {
    let item: Subscription
    let now: Date
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ServiceLogo(serviceID: item.serviceID, name: item.name, size: 42)
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                if let payment = item.upcomingPayment(on: now) {
                    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: payment.date).day ?? 0
                    Text("\(payment.date.formatted(.dateTime.month().day())) · \(days == 0 ? "오늘 예정" : "D-\(days)")").font(.caption).foregroundStyle(.secondary)
                } else { Text("예정 일정 없음").font(.caption).foregroundStyle(.secondary) }
                if item.currentStatus != .active { Text(item.currentStatus.title).font(.caption).foregroundStyle(Color.membershipAccent) }
                if item.isEffective(on: now) && item.isFree(on: now) { Text("무료체험 중").font(.caption).foregroundStyle(Color.membershipAccent) }
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 5) {
                Text(item.recurringPrice(on: now), format: .currency(code: item.currencyCode)).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(item.yearly ? "연간" : "월간").font(.caption).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
    }
}
struct ServicePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var category = "전체"
    let onSave: (Subscription) -> Bool
    private var results: [CatalogService] {
        CatalogService.all.filter { (category == "전체" || $0.category == category) && $0.matches(query) }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("서비스 이름 검색", text: $query)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityIdentifier("serviceSearch")
                if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.accessibilityLabel("검색 지우기") }
            }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 14)).padding(.horizontal, 20).padding(.top, 12)
            HStack {
                Text("카테고리").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Picker("카테고리", selection: $category) {
                    Text("전체").tag("전체")
                    ForEach(CatalogService.categories, id: \.self) { Text($0).tag($0) }
                }.pickerStyle(.menu)
            }.padding(.horizontal, 24).padding(.vertical, 8)
            List {
                if results.isEmpty {
                    Section {
                        Text("일치하는 서비스가 없어요").foregroundStyle(.secondary)
                        NavigationLink { SubscriptionEditor(existing: nil, service: nil, onSave: finish) }
                            label: { Label("목록에 없는 서비스 직접 입력", systemImage: "square.and.pencil") }
                    }
                } else {
                    Section("\(results.count)개 서비스") {
                        ForEach(results) { service in
                            NavigationLink { SubscriptionEditor(existing: nil, service: service, onSave: finish) } label: {
                                HStack(spacing: 12) {
                                    ServiceLogo(serviceID: service.id, name: service.displayName, size: 40)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(service.displayName).font(.subheadline.weight(.medium))
                                        Text(service.category).font(.caption).foregroundStyle(.secondary)
                                    }
                                }.padding(.vertical, 4)
                            }
                        }
                    }
                    Section {
                        NavigationLink { SubscriptionEditor(existing: nil, service: nil, onSave: finish) }
                            label: { Label("목록에 없는 서비스 직접 입력", systemImage: "square.and.pencil") }
                    }
                }
            }.scrollContentBackground(.hidden).scrollDismissesKeyboard(.interactively)
        }.background(Color.membershipBackground)
        .navigationTitle("구독 추가").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
    }
    private func finish(_ item: Subscription) -> Bool { guard onSave(item) else { return false }; dismiss(); return true }
}


extension Color {
    static let membershipAccent = Color(red: 0.35, green: 0.45, blue: 0.08)
    static let membershipYellow = Color(red: 1.0, green: 0.84, blue: 0.16)
    static let membershipLime = Color(red: 0.85, green: 0.94, blue: 0.57)
    static let membershipInk = Color(red: 0.18, green: 0.22, blue: 0.08)
    static let membershipYellowLight = Color(red: 1.0, green: 0.93, blue: 0.53)
    static let membershipYellowDeep = Color(red: 1.0, green: 0.84, blue: 0.16)
    static let membershipBackground = Color(red: 1.0, green: 0.995, blue: 0.96)
}

struct ServiceLogo: View {
    let serviceID: String?
    let name: String
    var size: CGFloat = 44
    private var asset: String? {
        if let serviceID, UIImage(named: serviceID) != nil { return serviceID }
        if let service = CatalogService.all.first(where: { ([$0.name, $0.displayName] + $0.aliases).contains { $0.localizedCaseInsensitiveCompare(name) == .orderedSame } }), UIImage(named: service.id) != nil { return service.id }
        return nil
    }
    var body: some View {
        Group {
            if let asset { Image(asset).resizable().scaledToFit().padding(5) }
            else { Image(systemName: "creditcard.fill").resizable().scaledToFit().padding(size * 0.25).foregroundStyle(Color.membershipAccent) }
        }.frame(width: size, height: size).background(.white, in: RoundedRectangle(cornerRadius: size * 0.25))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
            .overlay(RoundedRectangle(cornerRadius: size * 0.25).stroke(Color.black.opacity(0.05), lineWidth: 1))
            .accessibilityHidden(true)
    }
}
