import SwiftUI

@main
struct SubscriptionTrackerApp: App {
    @UIApplicationDelegateAdaptor(SubscriptionAppDelegate.self) var appDelegate
    var body: some Scene { WindowGroup { ContentView().tint(.membershipAccent).preferredColorScheme(.light) } }
}
