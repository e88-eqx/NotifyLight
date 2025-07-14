import SwiftUI
import NotifyLight

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var testManager = TestManager()
    
    @State private var config: TestConfiguration
    @State private var showingResetAlert = false
    
    init() {
        let manager = TestManager()
        _config = State(initialValue: manager.config)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Server Configuration
                Section("Server Configuration") {
                    TextField("API URL", text: $config.apiUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    TextField("API Key", text: $config.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("User ID", text: $config.userId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                // SDK Configuration
                Section("SDK Configuration") {
                    Toggle("Auto Register for Notifications", isOn: $config.autoRegister)
                    Toggle("Enable Debug Logging", isOn: $config.enableDebugLogging)
                }
                
                // Information
                Section("Information") {
                    InfoRow(label: "App Version", value: appVersion)
                    InfoRow(label: "Build Number", value: buildNumber)
                    InfoRow(label: "SDK Version", value: "1.0.0") // Would come from NotifyLight SDK
                    InfoRow(label: "Device Model", value: UIDevice.current.model)
                    InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                }
                
                // Server Testing
                Section("Server Testing") {
                    Button("Test Server Connection") {
                        testServerConnection()
                    }
                    
                    Button("Validate API Key") {
                        validateAPIKey()
                    }
                }
                
                // Data Management
                Section("Data Management") {
                    Button("Export Logs") {
                        exportLogs()
                    }
                    
                    Button("Export Test Results") {
                        exportTestResults()
                    }
                    
                    Button("Clear All Data") {
                        testManager.clearAll()
                    }
                    
                    Button("Reset App", role: .destructive) {
                        showingResetAlert = true
                    }
                }
                
                // Quick Setup
                Section("Quick Setup") {
                    Button("Use Local Server (localhost:3000)") {
                        config.apiUrl = "http://localhost:3000"
                        config.apiKey = "test-api-key-123"
                    }
                    
                    Button("Use Demo Server") {
                        config.apiUrl = "https://demo.notifylight.com"
                        config.apiKey = "demo-api-key"
                    }
                    
                    Button("Generate New User ID") {
                        config.userId = "test-user-ios-\(UUID().uuidString.prefix(8))"
                    }
                }
                
                // Help
                Section("Help") {
                    Link("Documentation", destination: URL(string: "https://docs.notifylight.com")!)
                    Link("GitHub Repository", destination: URL(string: "https://github.com/notifylight/notifylight")!)
                    Link("Report Issue", destination: URL(string: "https://github.com/notifylight/notifylight/issues")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Reset App", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task {
                        await testManager.resetApp()
                        dismiss()
                    }
                }
            } message: {
                Text("This will clear all settings and data. The app will restart with default configuration.")
            }
        }
        .onAppear {
            testManager.loadConfiguration()
            config = testManager.config
        }
    }
    
    // MARK: - Helper Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Actions
    
    private func saveSettings() {
        testManager.config = config
        testManager.saveConfiguration()
        
        // Reconfigure NotifyLight with new settings
        Task {
            do {
                let configuration = NotifyLight.Configuration(
                    apiUrl: URL(string: config.apiUrl)!,
                    apiKey: config.apiKey,
                    userId: config.userId,
                    autoRegisterForNotifications: config.autoRegister,
                    enableDebugLogging: config.enableDebugLogging
                )
                
                try await NotifyLight.shared.configure(with: configuration)
                await MainActor.run {
                    testManager.addLog("Settings saved and NotifyLight reconfigured", type: .success)
                }
            } catch {
                await MainActor.run {
                    testManager.addLog("Failed to reconfigure NotifyLight: \(error.localizedDescription)", type: .error)
                }
            }
        }
        
        dismiss()
    }
    
    private func testServerConnection() {
        Task {
            do {
                guard let url = URL(string: config.apiUrl) else {
                    testManager.addLog("Invalid API URL", type: .error)
                    return
                }
                
                let healthURL = url.appendingPathComponent("health")
                let (_, response) = try await URLSession.shared.data(from: healthURL)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        await MainActor.run {
                            testManager.addLog("✅ Server connection successful", type: .success)
                        }
                    } else {
                        await MainActor.run {
                            testManager.addLog("❌ Server responded with status \(httpResponse.statusCode)", type: .error)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    testManager.addLog("❌ Server connection failed: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }
    
    private func validateAPIKey() {
        Task {
            do {
                guard let url = URL(string: config.apiUrl) else {
                    testManager.addLog("Invalid API URL", type: .error)
                    return
                }
                
                let validateURL = url.appendingPathComponent("validate")
                var request = URLRequest(url: validateURL)
                request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        await MainActor.run {
                            testManager.addLog("✅ API key is valid", type: .success)
                        }
                    } else if httpResponse.statusCode == 401 {
                        await MainActor.run {
                            testManager.addLog("❌ API key is invalid", type: .error)
                        }
                    } else {
                        await MainActor.run {
                            testManager.addLog("❌ API validation failed with status \(httpResponse.statusCode)", type: .error)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    testManager.addLog("❌ API key validation failed: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }
    
    private func exportLogs() {
        let logsText = testManager.exportLogs()
        
        let activityVC = UIActivityViewController(
            activityItems: [logsText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // Present from the top-most view controller
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
    }
    
    private func exportTestResults() {
        let resultsText = testManager.exportTestResults()
        
        let activityVC = UIActivityViewController(
            activityItems: [resultsText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}