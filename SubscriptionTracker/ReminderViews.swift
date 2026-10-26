import SwiftUI
import UserNotifications

struct ReminderFields: View {
    @Binding var value: ReminderPreferences
    var yearly: Bool
    private var time: Binding<Date> {
        Binding(get: { Calendar.current.date(from: DateComponents(hour: value.hour, minute: value.minute)) ?? Date() }, set: {
            value.hour = Calendar.current.component(.hour, from: $0); value.minute = Calendar.current.component(.minute, from: $0)
        })
    }
    var body: some View {
        ForEach(yearly ? [0,1,3,7,30] : [0,1,3,7], id: \.self) { lead in
            Toggle(lead == 0 ? "결제 당일" : "\(lead)일 전", isOn: Binding(get: { value.days.contains(lead) }, set: { enabled in
                if enabled { value.days = Array(Set(value.days + [lead])).sorted() } else { value.days.removeAll { $0 == lead } }
            }))
        }
        DatePicker("알림 시간", selection: time, displayedComponents: .hourAndMinute)
        if value.validDays.isEmpty { Text("선택한 결제 전 알림이 없어요.").font(.caption).foregroundStyle(.secondary) }
    }
}
struct NotificationPermissionNote: View {
    @ObservedObject private var notifications = NotificationService.shared
    var body: some View {
        if notifications.authorization == .denied {
            Text("알림 권한이 꺼져 있어요. 설정에서 허용해야 알림을 받을 수 있어요.").font(.caption).foregroundStyle(.orange)
            if let url = URL(string: UIApplication.openSettingsURLString) { Link("앱 설정 열기", destination: url) }
        } else if !notifications.allowed {
            Button("알림 권한 요청") { Task { _ = await notifications.requestPermission() } }
        }
    }
}
struct NotificationSettingsView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notifications = NotificationService.shared
    @State private var draft = ReminderPreferences()
    @State private var requests: [UNNotificationRequest] = []
    var body: some View {
        Form {
            Section("전체 기본 설정") {
                Toggle("기본 결제 알림", isOn: Binding(get: { draft.enabled }, set: { enabled in
                    if enabled { Task { draft.enabled = await notifications.requestPermission() } } else { draft.enabled = false }
                }))
                Text("추천: 3일 전 오전 9시. 개별 설정이 없는 구독에 적용돼요. 구독별 설정과 재검토 알림은 상세 화면에서 따로 관리해요.")
                    .font(.caption).foregroundStyle(.secondary)
                if draft.enabled { ReminderFields(value: $draft, yearly: true) }
                Text("30일 전은 연간 구독에만 적용돼요.").font(.caption).foregroundStyle(.secondary)
                NotificationPermissionNote()
            }
            Section("예약 상태") {
                Text("예약된 알림 \(notifications.scheduledCount)개 · 반복 \(notifications.repeatingCount)개")
                if let through = notifications.limitedThrough { Text("일부 알림은 \(through.formatted(date: .abbreviated, time: .omitted)) 무렵까지만 예약되어 있어요. 그 전에 앱을 열어 갱신해 주세요.").font(.caption).foregroundStyle(.orange) }
                if let error = notifications.schedulingError { Text(error).foregroundStyle(.orange) }
                Text("날짜와 금액이 일정한 구독은 반복 알림을 사용해요. 월말·무료체험·할인 등 조건이 있는 구독은 가까운 일정부터 예약하며 앱을 열 때 갱신돼요.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section { Button("설정 저장") { if store.savePreferences(draft) { dismiss() } }.disabled(draft.enabled && draft.validDays.isEmpty) }
            if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                Section("검증용 예약 확인") {
                    Button("예약 목록 새로 읽기") { Task { requests = await UNUserNotificationCenter.current().pendingNotificationRequests() } }
                    Text("실제 예약 \(requests.count)개")
                    ForEach(requests.sorted { $0.identifier < $1.identifier }, id: \.identifier) { request in Text(request.content.title).font(.caption) }
                }
            }
        }
        .scrollContentBackground(.hidden).background(Color.membershipBackground)
        .navigationTitle("알림 설정")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        .onAppear { draft = store.preferences }
        .task { await notifications.refresh() }
    }
}

struct SubscriptionPaymentReminderView: View {
    @EnvironmentObject private var store: SubscriptionStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notifications = NotificationService.shared
    @State private var draft = ReminderPreferences()
    let id: UUID
    private var item: Subscription? { store.items.first { $0.id == id } }
    var body: some View {
        Form {
            if let item {
                Section {
                    Toggle("결제 전 알림받기", isOn: Binding(get: { draft.enabled }, set: { enabled in
                        if enabled { Task { draft.enabled = await notifications.requestPermission() } }
                        else { draft.enabled = false }
                    }))
                    if draft.enabled { ReminderFields(value: $draft, yearly: item.yearly) }
                } footer: { Text("여러 날짜를 선택할 수 있어요. 이 구독에만 적용돼요.") }
                Section {
                    Text(item.reminderOverride == nil ? "전체 기본 설정을 사용 중이에요." : "이 구독의 개별 설정을 사용 중이에요.").font(.caption)
                    Button("전체 기본 설정 사용") { var latest = item; latest.reminderOverride = nil; if store.save(latest) { dismiss() } }
                    NotificationPermissionNote()
                }
                if let error = notifications.schedulingError { Section { Text(error).font(.caption).foregroundStyle(.secondary) } }
            }
        }
        .scrollContentBackground(.hidden).background(Color.membershipBackground)
        .navigationTitle("결제 전 알림").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    guard var latest = item else { return }
                    if !latest.yearly { draft.days.removeAll { $0 == 30 } }
                    latest.reminderOverride = draft
                    if store.save(latest) { dismiss() }
                }.disabled(item == nil || (draft.enabled && draft.validDays.filter { item?.yearly == true || $0 != 30 }.isEmpty))
            }
        }
        .onAppear { draft = item?.reminderOverride ?? store.preferences }
        .task { await notifications.refresh() }
    }
}
