import Foundation
import SwiftUI
import NotifyLight

@MainActor
class TestManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var config = TestConfiguration()
    @Published var logs: [LogEntry] = []
    @Published var notifications: [NotifyLightNotification] = []
    @Published var messages: [InAppMessage] = []
    @Published var testResults: [String: TestResult] = [:]
    
    // MARK: - Private Properties
    
    private let maxLogs = 100
    private let maxNotifications = 50
    private let maxMessages = 20
    
    init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration Management
    
    func loadConfiguration() {
        let userDefaults = UserDefaults.standard
        
        config.apiUrl = userDefaults.string(forKey: "NotifyLight.apiUrl") ?? config.apiUrl
        config.apiKey = userDefaults.string(forKey: "NotifyLight.apiKey") ?? config.apiKey
        config.userId = userDefaults.string(forKey: "NotifyLight.userId") ?? config.userId
        config.autoRegister = userDefaults.object(forKey: "NotifyLight.autoRegister") as? Bool ?? config.autoRegister
        config.enableDebugLogging = userDefaults.object(forKey: "NotifyLight.enableDebugLogging") as? Bool ?? config.enableDebugLogging
    }
    
    func saveConfiguration() {
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(config.apiUrl, forKey: "NotifyLight.apiUrl")
        userDefaults.set(config.apiKey, forKey: "NotifyLight.apiKey")
        userDefaults.set(config.userId, forKey: "NotifyLight.userId")
        userDefaults.set(config.autoRegister, forKey: "NotifyLight.autoRegister")
        userDefaults.set(config.enableDebugLogging, forKey: "NotifyLight.enableDebugLogging")
    }
    
    // MARK: - Logging
    
    func addLog(_ message: String, type: LogType = .info) {
        let entry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            message: message,
            type: type
        )
        
        logs.insert(entry, at: 0)
        
        // Limit log count
        if logs.count > maxLogs {
            logs = Array(logs.prefix(maxLogs))
        }
        
        // Print to console as well
        print("[\(entry.timestamp.formatted(.dateTime.hour().minute().second()))] [\(type.rawValue.uppercased())] \(message)")
    }
    
    // MARK: - Data Management
    
    func addNotification(_ notification: NotifyLightNotification) {
        notifications.insert(notification, at: 0)
        
        if notifications.count > maxNotifications {
            notifications = Array(notifications.prefix(maxNotifications))
        }
    }
    
    func addMessage(_ message: InAppMessage) {
        // Avoid duplicates
        if !messages.contains(where: { $0.id == message.id }) {
            messages.insert(message, at: 0)
            
            if messages.count > maxMessages {
                messages = Array(messages.prefix(maxMessages))
            }
        }
    }
    
    func clearAll() {
        logs.removeAll()
        notifications.removeAll()
        messages.removeAll()
        testResults.removeAll()
        
        addLog("All data cleared")
    }
    
    func resetApp() async {
        // Clear UserDefaults
        let userDefaults = UserDefaults.standard
        let keys = [
            "NotifyLight.apiUrl",
            "NotifyLight.apiKey", 
            "NotifyLight.userId",
            "NotifyLight.autoRegister",
            "NotifyLight.enableDebugLogging"
        ]
        
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
        
        // Reset configuration
        config = TestConfiguration()
        
        // Clear all data
        clearAll()
        
        addLog("App reset completed")
        
        // Reconfigure NotifyLight if needed
        do {
            let configuration = NotifyLight.Configuration(
                apiUrl: URL(string: config.apiUrl)!,
                apiKey: config.apiKey,
                userId: config.userId,
                autoRegisterForNotifications: config.autoRegister,
                enableDebugLogging: config.enableDebugLogging
            )
            
            try await NotifyLight.shared.configure(with: configuration)
            addLog("NotifyLight reconfigured")
        } catch {
            addLog("Failed to reconfigure NotifyLight: \(error.localizedDescription)", type: .error)
        }
    }
    
    // MARK: - Export Functions
    
    func exportLogs() -> String {
        let header = "NotifyLight iOS Test App - Debug Logs\n"
        let timestamp = "Generated: \(Date().formatted())\n"
        let deviceInfo = "Device: \(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)\n"
        let separator = String(repeating: "=", count: 50) + "\n\n"
        
        let logEntries = logs.map { log in
            "[\(log.timestamp.formatted(.dateTime.hour().minute().second()))] [\(log.type.rawValue.uppercased())] \(log.message)"
        }.joined(separator: "\n")
        
        return header + timestamp + deviceInfo + separator + logEntries
    }
    
    func exportTestResults() -> String {
        let header = "NotifyLight iOS Test Results\n"
        let timestamp = "Generated: \(Date().formatted())\n"
        let separator = String(repeating: "=", count: 30) + "\n\n"
        
        let results = testResults.map { key, result in
            "\(key): \(result == .passed ? "PASSED" : "FAILED")"
        }.joined(separator: "\n")
        
        let summary = """
        
        Summary:
        Total Tests: \(testResults.count)
        Passed: \(testResults.values.filter { $0 == .passed }.count)
        Failed: \(testResults.values.filter { $0 == .failed }.count)
        """
        
        return header + timestamp + separator + results + summary
    }
}

// MARK: - Supporting Types

struct TestConfiguration {
    var apiUrl: String = "http://localhost:3000"
    var apiKey: String = "test-api-key-123"
    var userId: String = "test-user-ios-\(UUID().uuidString.prefix(8))"
    var autoRegister: Bool = true
    var enableDebugLogging: Bool = true
}

struct LogEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let message: String
    let type: LogType
}

enum LogType: String, CaseIterable {
    case info = "info"
    case success = "success"
    case warning = "warning"
    case error = "error"
    
    var color: Color {
        switch self {
        case .info: return .primary
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}