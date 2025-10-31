import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Settings Content
            Form {
                Section("OpenAI Configuration") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.headline)

                        HStack {
                            if viewModel.showAPIKey {
                                TextField("sk-...", text: $viewModel.apiKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("sk-...", text: $viewModel.apiKey)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button(action: { viewModel.showAPIKey.toggle() }) {
                                Image(systemName: viewModel.showAPIKey ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                            .help(viewModel.showAPIKey ? "Hide API Key" : "Show API Key")
                        }

                        Text("Get your API key from platform.openai.com")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        if viewModel.apiKeySaved {
                            Label("API Key saved securely", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Model")
                            .font(.headline)

                        Picker("", selection: $viewModel.selectedModel) {
                            ForEach(viewModel.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)

                        Text("GPT-4 is recommended for best results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Temperature")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.1f", viewModel.temperature))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $viewModel.temperature, in: 0.0...1.0, step: 0.1)

                        HStack {
                            Text("More focused")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("More creative")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max Tokens")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.maxTokens)")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: Binding(
                            get: { Double(viewModel.maxTokens) },
                            set: { viewModel.maxTokens = Int($0) }
                        ), in: 500...4000, step: 100)

                        Text("Higher values allow longer responses but cost more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .padding()

            Divider()

            // Action Buttons
            HStack {
                Button("Clear All") {
                    viewModel.clearAllSettings()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    viewModel.saveSettings()
                    if viewModel.errorMessage.isEmpty {
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.hasChanges)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 550)
        .onAppear {
            viewModel.loadSettings()
        }
    }
}

// MARK: - View Model

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var showAPIKey: Bool = false
    @Published var selectedModel: String = "gpt-4"
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 1500
    @Published var errorMessage: String = ""
    @Published var apiKeySaved: Bool = false
    @Published var hasChanges: Bool = false

    let availableModels = ["gpt-4", "gpt-4-turbo", "gpt-3.5-turbo"]

    private let settingsManager: SettingsManager
    private var originalAPIKey: String = ""
    private var originalModel: String = ""
    private var originalTemperature: Double = 0.7
    private var originalMaxTokens: Int = 1500

    init(settingsManager: SettingsManager = .shared) {
        self.settingsManager = settingsManager
    }

    func loadSettings() {
        // Load API key (show masked if it exists)
        if let key = try? settingsManager.getAPIKey() {
            originalAPIKey = key
            apiKey = key
            apiKeySaved = true
        }

        // Load other settings
        originalModel = settingsManager.openAIModel
        selectedModel = originalModel

        originalTemperature = settingsManager.openAITemperature
        temperature = originalTemperature

        originalMaxTokens = settingsManager.openAIMaxTokens
        maxTokens = originalMaxTokens

        // Set up change tracking
        setupChangeTracking()
    }

    private func setupChangeTracking() {
        // Track changes to enable/disable save button
        $apiKey
            .combineLatest($selectedModel, $temperature, $maxTokens)
            .map { [weak self] apiKey, model, temp, tokens in
                guard let self = self else { return false }
                return apiKey != self.originalAPIKey ||
                       model != self.originalModel ||
                       abs(temp - self.originalTemperature) > 0.01 ||
                       tokens != self.originalMaxTokens
            }
            .assign(to: &$hasChanges)
    }

    func saveSettings() {
        errorMessage = ""
        apiKeySaved = false

        // Validate API key format
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty && !trimmedKey.hasPrefix("sk-") {
            errorMessage = "API key should start with 'sk-'"
            return
        }

        // Save API key
        if !trimmedKey.isEmpty {
            do {
                try settingsManager.saveAPIKey(trimmedKey)
                originalAPIKey = trimmedKey
                apiKeySaved = true
            } catch {
                errorMessage = "Failed to save API key: \(error.localizedDescription)"
                return
            }
        } else if !originalAPIKey.isEmpty {
            // Clear API key if empty
            do {
                try settingsManager.clearAPIKey()
                originalAPIKey = ""
            } catch {
                errorMessage = "Failed to clear API key: \(error.localizedDescription)"
                return
            }
        }

        // Save other settings
        settingsManager.openAIModel = selectedModel
        originalModel = selectedModel

        settingsManager.openAITemperature = temperature
        originalTemperature = temperature

        settingsManager.openAIMaxTokens = maxTokens
        originalMaxTokens = maxTokens

        hasChanges = false
    }

    func clearAllSettings() {
        settingsManager.clearAll()
        apiKey = ""
        selectedModel = "gpt-4"
        temperature = 0.7
        maxTokens = 1500
        originalAPIKey = ""
        originalModel = "gpt-4"
        originalTemperature = 0.7
        originalMaxTokens = 1500
        errorMessage = ""
        apiKeySaved = false
        hasChanges = false
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
