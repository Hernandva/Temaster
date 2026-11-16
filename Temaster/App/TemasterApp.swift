import SwiftUI

@main
struct TemasterApp: App {
    /// Gives the external display its own scene (see `ExternalDisplaySceneDelegate`).
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
