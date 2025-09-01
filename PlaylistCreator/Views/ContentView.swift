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
            
            Spacer()
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}

#Preview {
    ContentView()
}