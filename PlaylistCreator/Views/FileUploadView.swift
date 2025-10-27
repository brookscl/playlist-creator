import SwiftUI
import UniformTypeIdentifiers

struct FileUploadView: View {
    @StateObject private var viewModel = FileUploadViewModel()
    @State private var isDragOver = false
    @State private var showingFilePicker = false
    @State private var urlInputText = ""
    @State private var showURLInput = false

    var body: some View {
        VStack(spacing: 20) {
            // Toggle between file and URL input
            if !viewModel.isProcessing && !viewModel.hasProcessedFile {
                Picker("Input Method", selection: $showURLInput) {
                    Text("File Upload").tag(false)
                    Text("URL Input").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            if viewModel.isProcessing {
                processingView
            } else if viewModel.hasProcessedFile {
                successView
            } else if showURLInput {
                urlInputAreaView
            } else {
                uploadAreaView
            }

            if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: allowedFileTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private var uploadAreaView: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 48))
                .foregroundColor(isDragOver ? .accentColor : .secondary)
            
            Text("Drop audio or video files here")
                .font(.headline)
                .foregroundColor(isDragOver ? .accentColor : .primary)
            
            Text("Supports MP3, MP4, WAV, M4A, MOV, and more")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Choose Files") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
        )
        .onDrop(of: allowedFileTypes, isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        .animation(.easeInOut(duration: 0.2), value: isDragOver)
    }

    private var urlInputAreaView: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.circle")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Enter URL")
                .font(.headline)

            Text("YouTube, Podcast, or Direct Audio/Video Link")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("https://youtube.com/watch?v=...", text: $urlInputText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onSubmit {
                    processURL()
                }

            HStack(spacing: 12) {
                if !urlInputText.isEmpty {
                    Button("Clear") {
                        urlInputText = ""
                    }
                    .buttonStyle(.bordered)
                }

                Button("Process URL") {
                    processURL()
                }
                .buttonStyle(.borderedProminent)
                .disabled(urlInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !urlInputText.isEmpty {
                urlValidationIndicator
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var urlValidationIndicator: some View {
        HStack(spacing: 8) {
            let validator = URLValidator()
            let isValid = validator.isValidURLString(urlInputText)

            Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isValid ? .green : .orange)

            Text(isValid ? urlTypeDescription : "Invalid URL format")
                .font(.caption)
                .foregroundColor(isValid ? .green : .orange)
        }
        .padding(.top, 4)
    }

    private var urlTypeDescription: String {
        let validator = URLValidator()
        guard let url = URL(string: validator.normalizeURLString(urlInputText)) else {
            return "Invalid URL"
        }

        let urlType = validator.validateURL(url)
        switch urlType {
        case .youtube:
            return "YouTube video detected"
        case .podcast:
            return "Podcast/RSS feed detected"
        case .directAudio:
            return "Direct audio link detected"
        case .directVideo:
            return "Direct video link detected"
        case .unsupported:
            return "Unsupported URL type"
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(1.2)
            
            Text(viewModel.statusMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if let fileName = viewModel.currentFileName {
                Text(fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("File processed successfully!")
                .font(.headline)
            
            if let fileName = viewModel.processedFileName {
                Text(fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Button("Process Another") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                
                Button("Continue") {
                    // TODO: Navigate to next step
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Try Again") {
                viewModel.clearError()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - File Handling
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            processFile(url)
        case .failure(let error):
            viewModel.setError("File selection failed: \(error.localizedDescription)")
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            DispatchQueue.main.async {
                if let error = error {
                    viewModel.setError("Drop failed: \(error.localizedDescription)")
                    return
                }
                
                guard let url = url else {
                    viewModel.setError("Invalid file dropped")
                    return
                }
                
                processFile(url)
            }
        }
        
        return true
    }
    
    private func processFile(_ url: URL) {
        Task {
            await viewModel.processFile(url)
        }
    }

    private func processURL() {
        let validator = URLValidator()
        let normalizedString = validator.normalizeURLString(urlInputText)

        guard let url = URL(string: normalizedString) else {
            viewModel.setError("Invalid URL format")
            return
        }

        guard validator.isValidURLString(normalizedString) else {
            viewModel.setError("Invalid or unsupported URL")
            return
        }

        Task {
            await viewModel.processURL(url)
        }
    }

    // MARK: - Configuration
    
    private var allowedFileTypes: [UTType] {
        [
            .audio,
            .movie,
            .mpeg4Movie,
            .quickTimeMovie,
            .mp3,
            .wav,
            UTType(filenameExtension: "m4a") ?? .audio,
            UTType(filenameExtension: "aac") ?? .audio
        ]
    }
}

// MARK: - Preview

struct FileUploadView_Previews: PreviewProvider {
    static var previews: some View {
        FileUploadView()
            .frame(width: 400, height: 300)
    }
}
