import SwiftUI

struct ContentView: View {
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 20) {
            // Header with settings button
            HStack {
                Text("Playlist Creator")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .help("Settings")
            }
            .padding(.top)

            Text("Create Apple Music playlists from audio content")
                .font(.subheadline)
                .foregroundColor(.secondary)

            FileUploadView()
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showingSettings = true
        }
    }
}

#Preview {
    ContentView()
}