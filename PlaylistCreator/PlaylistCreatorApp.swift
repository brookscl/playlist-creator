import SwiftUI

@main
struct PlaylistCreatorApp: App {
    init() {
        // Configure service container for production use
        serviceContainer.configureProduction()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NSApplication.shared.sendAction(#selector(AppDelegate.showSettings), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

// MARK: - App Delegate for Settings

class AppDelegate: NSObject, NSApplicationDelegate {
    @objc func showSettings() {
        NotificationCenter.default.post(name: .showSettings, object: nil)
    }
}

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
}