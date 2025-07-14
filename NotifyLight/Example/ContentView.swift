import SwiftUI
import NotifyLight
import UserNotifications

struct ContentView: View {
    @StateObject private var notifyLight = NotifyLight.shared
    @State private var statusMessage = "Initializing..."
    @State private var messages: [InAppMessage] = []
    @State private var notifications: [NotifyLightNotification] = []
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                StatusView(
                    isInitialized: notifyLight.isInitialized,
                    token: notifyLight.currentToken,
                    authStatus: notifyLight.authorizationStatus,
                    statusMessage: statusMessage
                )
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Request Permissions") {
                        Task { await requestPermissions() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!notifyLight.isInitialized)
                    
                    Button("Fetch Messages") {
                        Task { await fetchMessages() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!notifyLight.isInitialized)
                    
                    Button("Test Notification") {
                        Task { await sendTestNotification() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!notifyLight.isInitialized)
                    
                    Button("Check Server Health") {
                        Task { await checkServerHealth() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!notifyLight.isInitialized)
                }
                
                // Messages List
                if !messages.isEmpty {
                    MessagesList(messages: messages)
                }
                
                // Recent Notifications
                if !notifications.isEmpty {
                    NotificationsList(notifications: notifications)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("NotifyLight Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Settings") {
                    showingSettings = true
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear {
            setupEventHandlers()
        }
    }
    
    // MARK: - Actions
    
    private func requestPermissions() async {
        do {
            let status = try await notifyLight.requestPushAuthorization()
            await MainActor.run {
                statusMessage = "Authorization: \(authStatusText(status))"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Permission request failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchMessages() async {
        do {
            let fetchedMessages = try await notifyLight.fetchMessages()
            await MainActor.run {
                messages = fetchedMessages
                statusMessage = "Fetched \(fetchedMessages.count) messages"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Failed to fetch messages: \(error.localizedDescription)"
            }
        }
    }
    
    private func sendTestNotification() async {
        do {
            try await notifyLight.scheduleTestNotification(
                title: "Test Notification",
                body: "This is a test notification from NotifyLight iOS SDK",
                delay: 2
            )
            await MainActor.run {
                statusMessage = "Test notification scheduled"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Failed to schedule test notification: \(error.localizedDescription)"
            }
        }
    }
    
    private func checkServerHealth() async {
        do {
            let isHealthy = try await notifyLight.checkServerHealth()
            await MainActor.run {
                statusMessage = isHealthy ? "Server is healthy ✅" : "Server unhealthy ❌"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Server health check failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Event Handling
    
    private func setupEventHandlers() {
        notifyLight.onNotification { event in
            DispatchQueue.main.async {
                switch event {
                case .received(let notification):
                    notifications.insert(notification, at: 0)
                    statusMessage = "Notification received: \(notification.title)"
                    
                case .opened(let notification):
                    notifications.insert(notification, at: 0)
                    statusMessage = "Notification opened: \(notification.title)"
                    
                case .tokenReceived(let token):
                    statusMessage = "Token received: \(token.prefix(20))..."
                    
                case .tokenRefresh(let token):
                    statusMessage = "Token refreshed: \(token.prefix(20))..."
                    
                case .registrationError(let error):
                    statusMessage = "Registration error: \(error.localizedDescription)"
                }
            }
        }
        
        notifyLight.onMessage { message in
            DispatchQueue.main.async {
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.insert(message, at: 0)
                }
                statusMessage = "In-app message: \(message.title)"
            }
        }
    }
    
    // MARK: - Helpers
    
    private func authStatusText(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Subviews

struct StatusView: View {
    let isInitialized: Bool
    let token: String?
    let authStatus: UNAuthorizationStatus
    let statusMessage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
            
            Label(isInitialized ? "Initialized" : "Not Initialized", 
                  systemImage: isInitialized ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isInitialized ? .green : .red)
            
            if let token = token {
                Label("Token: \(token.prefix(20))...", systemImage: "key.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Label("Auth: \(authStatusText(authStatus))", systemImage: "bell.fill")
                .foregroundColor(authStatus == .authorized ? .green : .orange)
            
            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func authStatusText(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}

struct MessagesList: View {
    let messages: [InAppMessage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("In-App Messages (\(messages.count))")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(messages, id: \.id) { message in
                    MessageRowView(message: message)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MessageRowView: View {
    let message: InAppMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(message.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !message.actions.isEmpty {
                HStack {
                    ForEach(message.actions, id: \.id) { action in
                        Button(action.title) {
                            // Handle action
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(8)
    }
}

struct NotificationsList: View {
    let notifications: [NotifyLightNotification]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Notifications (\(notifications.count))")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(notifications, id: \.id) { notification in
                    NotificationRowView(notification: notification)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NotificationRowView: View {
    let notification: NotifyLightNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(notification.title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(notification.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(notification.receivedAt, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(8)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("NotifyLight Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration")
                        .font(.headline)
                    
                    Text("• API URL: Configure in AppDelegate")
                    Text("• API Key: Set your server API key")
                    Text("• User ID: Identify the current user")
                    Text("• Auto-registration: Enabled")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Text("See AppDelegate.swift for configuration options")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}