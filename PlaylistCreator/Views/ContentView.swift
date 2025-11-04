import SwiftUI

struct ContentView: View {
    @StateObject private var workflowViewModel = WorkflowViewModel()
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

            // Show different views based on workflow phase
            workflowContent
        }
        .frame(minWidth: 600, minHeight: 500)
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showingSettings = true
        }
    }

    @ViewBuilder
    private var workflowContent: some View {
        switch workflowViewModel.currentPhase {
        case .fileInput, .transcription:
            FileUploadView(workflowViewModel: workflowViewModel)

        case .musicExtraction, .musicSearch:
            processingView

        case .matchSelection:
            if !workflowViewModel.matchedSongs.isEmpty {
                MatchSelectionView(
                    matches: workflowViewModel.matchedSongs,
                    onComplete: {
                        Task {
                            await workflowViewModel.completeMatchSelection()
                        }
                    }
                )
            }

        case .playlistCreation:
            processingView

        case .complete:
            completionView

        case .error(let message):
            errorView(message: message)
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: workflowViewModel.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(1.2)

            Text(workflowViewModel.statusMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Playlist Created!")
                .font(.title)
                .fontWeight(.bold)

            if let playlist = workflowViewModel.createdPlaylist {
                VStack(spacing: 12) {
                    Text(playlist.name)
                        .font(.title2)
                        .multilineTextAlignment(.center)

                    Text("\(playlist.songCount) song\(playlist.songCount == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if let url = playlist.url {
                        Button(action: {
                            NSWorkspace.shared.open(url)
                        }) {
                            Label("Open in Apple Music", systemImage: "music.note")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text(workflowViewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button("Create Another Playlist") {
                workflowViewModel.reset()
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Start Over") {
                workflowViewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}