import SwiftUI
import NotifyLight
import UserNotifications

struct ContentView: View {
    @StateObject private var notifyLight = NotifyLight.shared
    @StateObject private var testManager = TestManager()
    
    @State private var showingSettings = false
    @State private var showingLogs = false
    @State private var showingInAppMessage = false
    @State private var currentInAppMessage: InAppMessage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Status indicators
                    statusSection
                    
                    // Device information
                    deviceInfoSection
                    
                    // Test controls
                    testControlsSection
                    
                    // Recent activity
                    if !testManager.notifications.isEmpty {
                        recentNotificationsSection
                    }
                    
                    if !testManager.messages.isEmpty {
                        recentMessagesSection
                    }
                    
                    // Utilities
                    utilitiesSection
                }
                .padding()
            }
            .navigationTitle("NotifyLight Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Logs") {
                        showingLogs = true
                    }
                    
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingLogs) {
                LogsView(logs: testManager.logs)
            }
            .inAppMessage(
                isPresented: $showingInAppMessage,
                message: currentInAppMessage ?? defaultMessage,
                customization: .default,
                onAction: handleMessageAction
            )
            .onAppear {
                setupEventHandlers()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("NotifyLight iOS Test")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Native iOS SDK Testing")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
            
            HStack {
                StatusIndicator(
                    label: "SDK",
                    status: notifyLight.isInitialized ? .connected : .disconnected
                )
                
                Spacer()
                
                StatusIndicator(
                    label: "Token",
                    status: notifyLight.currentToken != nil ? .connected : .disconnected
                )
                
                Spacer()
                
                StatusIndicator(
                    label: "Auth",
                    status: authorizationStatus
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var deviceInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device Information")
                .font(.headline)
            
            InfoRow(label: "Platform", value: "iOS \(UIDevice.current.systemVersion)")
            InfoRow(label: "Model", value: UIDevice.current.model)
            InfoRow(label: "User ID", value: testManager.config.userId)
            
            if let token = notifyLight.currentToken {
                HStack {
                    InfoRow(label: "Token", value: String(token.prefix(20)) + "...")
                    
                    Button("Copy") {
                        UIPasteboard.general.string = token
                        testManager.addLog("Token copied to clipboard")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var testControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SDK Tests")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                TestButton(
                    title: "Request Permissions",
                    status: testManager.testResults["permissions"],
                    action: testPermissions
                )
                
                TestButton(
                    title: "Get Token",
                    status: testManager.testResults["token"],
                    action: testTokenRetrieval
                )
                
                TestButton(
                    title: "Check Messages",
                    status: testManager.testResults["messages"],
                    action: testInAppMessages
                )
                
                TestButton(
                    title: "Show Test Message",
                    status: testManager.testResults["customMessage"],
                    action: testCustomMessage
                )
                
                TestButton(
                    title: "Test Network",
                    status: testManager.testResults["network"],
                    action: testNetworkConnectivity
                )
                
                TestButton(
                    title: "Badge Test",
                    status: testManager.testResults["badge"],
                    action: testBadgeManagement
                )
            }
            
            Button("🧪 Run All Tests") {
                Task {
                    await runAllTests()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recentNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Notifications (\(testManager.notifications.count))")
                .font(.headline)
            
            ForEach(testManager.notifications.prefix(5), id: \.id) { notification in
                NotificationRowView(notification: notification)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recentMessagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("In-App Messages (\(testManager.messages.count))")
                .font(.headline)
            
            ForEach(testManager.messages.prefix(3), id: \.id) { message in
                MessageRowView(message: message) {
                    showInAppMessage(message)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var utilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Utilities")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button("Clear Data") {
                    testManager.clearAll()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Reset App") {
                    Task {
                        await testManager.resetApp()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    
    private var authorizationStatus: ConnectionStatus {
        switch notifyLight.authorizationStatus {
        case .authorized:
            return .connected
        case .denied:
            return .error
        default:
            return .disconnected
        }
    }
    
    private var defaultMessage: InAppMessage {
        InAppMessage(
            id: "default",
            title: "Default Message",
            message: "This is a default message",
            actions: [
                MessageAction(id: "ok", title: "OK", style: .primary)
            ]
        )
    }
    
    // MARK: - Event Handling
    
    private func setupEventHandlers() {
        // Listen for NotifyLight events
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NotifyLightNotificationReceived"),
            object: nil,
            queue: .main
        ) { notification in
            if let notif = notification.object as? NotifyLightNotification {
                handleNotificationReceived(notif)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NotifyLightTokenReceived"),
            object: nil,
            queue: .main
        ) { notification in
            if let token = notification.object as? String {
                testManager.addLog("🔑 Token received: \(token.prefix(20))...")
                testManager.testResults["token"] = .passed
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NotifyLightInAppMessage"),
            object: nil,
            queue: .main
        ) { notification in
            if let message = notification.object as? InAppMessage {
                handleInAppMessageReceived(message)
            }
        }
    }
    
    private func handleNotificationReceived(_ notification: NotifyLightNotification) {
        testManager.addNotification(notification)
        testManager.addLog("📱 Notification: \(notification.title)")
        testManager.testResults["pushReceived"] = .passed
    }
    
    private func handleInAppMessageReceived(_ message: InAppMessage) {
        testManager.addMessage(message)
        currentInAppMessage = message
        showingInAppMessage = true
        testManager.addLog("💬 Message: \(message.title)")
    }
    
    private func handleMessageAction(_ action: MessageAction) {
        testManager.addLog("🔘 Action: \(action.title)")
    }
    
    private func showInAppMessage(_ message: InAppMessage) {
        currentInAppMessage = message
        showingInAppMessage = true
    }
    
    // MARK: - Test Functions
    
    private func testPermissions() {
        Task {
            do {
                let status = try await notifyLight.requestPushAuthorization()
                await MainActor.run {
                    testManager.testResults["permissions"] = status == .authorized ? .passed : .failed
                    testManager.addLog("Permissions: \(status)")
                }
            } catch {
                await MainActor.run {
                    testManager.testResults["permissions"] = .failed
                    testManager.addLog("❌ Permission test failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testTokenRetrieval() {
        if let token = notifyLight.getDeviceToken() {
            testManager.testResults["token"] = .passed
            testManager.addLog("✅ Token: \(token.prefix(20))...")
        } else {
            testManager.testResults["token"] = .failed
            testManager.addLog("❌ No token available")
        }
    }
    
    private func testInAppMessages() {
        Task {
            do {
                let messages = try await notifyLight.fetchMessages()
                await MainActor.run {
                    testManager.testResults["messages"] = .passed
                    testManager.addLog("✅ Fetched \(messages.count) messages")
                    testManager.messages = messages
                }
            } catch {
                await MainActor.run {
                    testManager.testResults["messages"] = .failed
                    testManager.addLog("❌ Message fetch failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testCustomMessage() {
        let message = InAppMessage(
            id: "test-\(Date().timeIntervalSince1970)",
            title: "Test Message",
            message: "This is a test message from the iOS test app.",
            actions: [
                MessageAction(id: "ok", title: "OK", style: .primary),
                MessageAction(id: "cancel", title: "Cancel", style: .secondary)
            ]
        )
        
        currentInAppMessage = message
        showingInAppMessage = true
        testManager.testResults["customMessage"] = .passed
        testManager.addLog("✅ Custom message displayed")
    }
    
    private func testNetworkConnectivity() {
        Task {
            do {
                let isHealthy = try await notifyLight.checkServerHealth()
                await MainActor.run {
                    testManager.testResults["network"] = isHealthy ? .passed : .failed
                    testManager.addLog(isHealthy ? "✅ Server healthy" : "❌ Server unhealthy")
                }
            } catch {
                await MainActor.run {
                    testManager.testResults["network"] = .failed
                    testManager.addLog("❌ Network test failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testBadgeManagement() {
        Task {
            // Test setting badge
            await notifyLight.updateBadgeCount(5)
            
            // Wait a moment then clear
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await notifyLight.clearBadge()
            
            await MainActor.run {
                testManager.testResults["badge"] = .passed
                testManager.addLog("✅ Badge management test completed")
            }
        }
    }
    
    private func runAllTests() async {
        testManager.addLog("🧪 Running all tests...")
        testManager.testResults.removeAll()
        
        // Test permissions
        testPermissions()
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test token
        testTokenRetrieval()
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test network
        await testNetworkConnectivity()
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test messages
        await testInAppMessages()
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test custom message
        testCustomMessage()
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Test badge
        await testBadgeManagement()
        
        await MainActor.run {
            testManager.addLog("🏁 All tests completed")
        }
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let label: String
    let status: ConnectionStatus
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

struct TestButton: View {
    let title: String
    let status: TestResult?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let status = status {
                    Image(systemName: status.icon)
                        .foregroundColor(status.color)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
    }
}

struct NotificationRowView: View {
    let notification: NotifyLightNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(notification.title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(notification.message)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(notification.receivedAt, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
}

struct MessageRowView: View {
    let message: InAppMessage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(message.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !message.actions.isEmpty {
                    Text("Actions: \(message.actions.map(\.title).joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

enum ConnectionStatus {
    case connected, disconnected, error
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .orange
        case .error: return .red
        }
    }
}

enum TestResult {
    case passed, failed
    
    var color: Color {
        switch self {
        case .passed: return .green
        case .failed: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

#Preview {
    ContentView()
}