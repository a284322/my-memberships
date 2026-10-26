import SwiftUI
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    @Published var authorization: UNAuthorizationStatus = .notDetermined
    @Published var scheduledCount = 0
    @Published var repeatingCount = 0
    @Published var limitedThrough: Date?
    @Published var schedulingError: String?
    @Published var targetID: UUID?
    private let center = UNUserNotificationCenter.current()
    private var queue: Task<Void, Never>?
    var allowed: Bool { authorization == .authorized || authorization == .provisional || authorization == .ephemeral }
    func refresh() async { authorization = await center.notificationSettings().authorizationStatus }
    func requestPermission() async -> Bool {
        do { _ = try await center.requestAuthorization(options: [.alert, .sound, .badge]); await refresh(); return allowed }
        catch { schedulingError = "알림 권한을 확인하지 못했어요. 설정 앱에서 확인해 주세요."; return false }
    }
    func rebuild(items: [Subscription], preferences: ReminderPreferences) {
        let previous = queue
        queue = Task {
            await previous?.value
            await refresh()
            let pending = await center.pendingNotificationRequests()
            center.removePendingNotificationRequests(withIdentifiers: pending.filter { $0.identifier.hasPrefix(ReminderPlanner.prefix) }.map(\.identifier))
            center.removeDeliveredNotifications(withIdentifiers: (await center.deliveredNotifications()).filter { $0.request.identifier.hasPrefix(ReminderPlanner.prefix) }.map { $0.request.identifier })
            scheduledCount = 0; repeatingCount = 0; limitedThrough = nil
            schedulingError = nil
            guard allowed else { return }
            let plan = ReminderReservationPlanner.plan(items: items, preferences: preferences, now: Date())
            limitedThrough = plan.limitedThrough
            for reservation in plan.reservations {
                let event = reservation.event
                let content = UNMutableNotificationContent()
                content.title = event.title; content.body = event.body; content.sound = .default
                content.userInfo = ["subscriptionID": event.subscriptionID.uuidString]
                let components = reservation.repeating ?? Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: event.fireDate)
                let request = UNNotificationRequest(identifier: event.id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: reservation.repeating != nil))
                do { try await center.add(request); scheduledCount += 1; if reservation.repeating != nil { repeatingCount += 1 } }
                catch { schedulingError = "일부 알림을 예약하지 못했어요. 앱을 다시 열어 확인해 주세요." }
            }
        }
    }
    func testNotification(for item: Subscription) async {
        guard ProcessInfo.processInfo.arguments.contains("--uitesting"), allowed else { return }
        let content = UNMutableNotificationContent()
        content.title = "테스트 알림 · \(item.name)"; content.body = "누르면 해당 구독 상세 화면으로 이동해요."
        content.userInfo = ["subscriptionID": item.id.uuidString]; content.sound = .default
        try? await center.add(UNNotificationRequest(identifier: "ui-test." + item.id.uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)))
    }
}

final class SubscriptionAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let raw = response.notification.request.content.userInfo["subscriptionID"] as? String, let id = UUID(uuidString: raw) {
            Task { @MainActor in NotificationService.shared.targetID = id }
        }
        completionHandler()
    }
}

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published var items: [Subscription] = []
    @Published var error: String?
    @Published var storageUnavailable = false
    @Published var preferences = ReminderPreferences()
    private let repository: SubscriptionRepository
    private let defaults: UserDefaults
    private let preferencesKey: String
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
        let membershipTesting = testing && ProcessInfo.processInfo.arguments.contains("--membership-testing")
        repository = SubscriptionRepository(defaults: defaults, key: membershipTesting ? "memberships.ui-tests.v1" : (testing ? "subscriptions.ui-tests.v2" : "subscriptions.v1"))
        preferencesKey = membershipTesting ? "memberships.reminders.ui-tests.v1" : (testing ? "reminders.ui-tests.v1" : "reminders.v1")
        if let data = defaults.data(forKey: preferencesKey) { preferences = (try? JSONDecoder().decode(ReminderPreferences.self, from: data)) ?? ReminderPreferences() }
        load()
    }
    func load() {
        do { items = try repository.load(); storageUnavailable = false }
        catch { storageUnavailable = true }
        if storageUnavailable { error = "저장 정보를 읽지 못했어요. 기존 데이터를 보호하기 위해 변경을 중지했어요." }
    }
    @discardableResult func save(_ item: Subscription) -> Bool {
        guard !storageUnavailable else { return false }
        var updated = items
        if let index = updated.firstIndex(where: { $0.id == item.id }) { updated[index] = item } else { updated.append(item) }
        return persist(updated)
    }
    @discardableResult func delete(_ item: Subscription) -> Bool { guard !storageUnavailable else { return false }; return persist(items.filter { $0.id != item.id }) }
    func saveBenefitChanges(_ item: Subscription) {
        guard !storageUnavailable, let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = items
        updated[index] = updated[index].applyingBenefitChanges(from: item)
        persist(updated, refreshReminders: false)
    }
    @discardableResult private func persist(_ updated: [Subscription], refreshReminders: Bool = true) -> Bool {
        do { try repository.save(updated); items = updated; if refreshReminders { refreshNotifications() }; return true }
        catch { self.error = "변경 내용을 저장하지 못했어요. 다시 시도해 주세요."; return false }
    }
    @discardableResult func savePreferences(_ value: ReminderPreferences) -> Bool {
        do { let data = try JSONEncoder().encode(value); defaults.set(data, forKey: preferencesKey); preferences = value; refreshNotifications(); return true }
        catch { self.error = "알림 설정을 저장하지 못했어요."; return false }
    }
    func refreshNotifications() { guard !storageUnavailable else { return }; NotificationService.shared.rebuild(items: items, preferences: preferences) }
}
