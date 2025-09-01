import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Playlist Creator")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Create Apple Music playlists from audio content")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            FileUploadView()
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
    }
}

#Preview {
    ContentView()
}