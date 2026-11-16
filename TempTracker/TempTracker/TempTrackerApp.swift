import SwiftUI

@main
struct TempTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var store = CycleStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
