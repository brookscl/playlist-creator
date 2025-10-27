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
    }
}