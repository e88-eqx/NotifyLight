import SwiftUI
import NotifyLight

/// Example SwiftUI view demonstrating in-app message integration
struct SwiftUIExampleView: View {
    
    // MARK: - State Properties
    
    @StateObject private var notifyLight = NotifyLight.shared
    @State private var statusMessage = "Ready"
    @State private var currentMessages: [InAppMessage] = []
    @State private var showingCustomMessage = false
    @State private var customMessage: InAppMessage?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Status
                statusSection
                
                // Demo buttons
                demoButtonsSection
                
                // Messages list
                if !currentMessages.isEmpty {
                    messagesSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("SwiftUI In-App Messages")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupNotifyLight()
            }
            .inAppMessage(
                isPresented: $showingCustomMessage,
                message: customMessage ?? defaultMessage,
                customization: .default,
                onAction: handleMessageAction
            )
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("NotifyLight SwiftUI")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Demonstrate in-app message integration with SwiftUI")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 8) {
            Label("Status", systemImage: "info.circle")
                .font(.headline)
            
            Text(statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var demoButtonsSection: some View {
        VStack(spacing: 12) {
            Text("Demo Messages")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                // Basic Alert
                DemoButton(
                    title: "Alert",
                    color: .blue,
                    icon: "bell.fill"
                ) {
                    showBasicAlert()
                }
                
                // Card Message
                DemoButton(
                    title: "Card",
                    color: .green,
                    icon: "rectangle.fill"
                ) {
                    showCardMessage()
                }
                
                // Custom Message
                DemoButton(
                    title: "Custom",
                    color: .orange,
                    icon: "paintbrush.fill"
                ) {
                    showCustomSwiftUIMessage()
                }
                
                // Survey Message
                DemoButton(
                    title: "Survey",
                    color: .purple,
                    icon: "questionmark.circle.fill"
                ) {
                    showSurveyMessage()
                }
                
                // Minimal Message
                DemoButton(
                    title: "Minimal",
                    color: .indigo,
                    icon: "minus.circle.fill"
                ) {
                    showMinimalMessage()
                }
                
                // Fetch Server Messages
                DemoButton(
                    title: "Fetch",
                    color: .teal,
                    icon: "arrow.down.circle.fill"
                ) {
                    fetchServerMessages()
                }
            }
        }
    }
    
    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Messages (\(currentMessages.count))")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(currentMessages, id: \.id) { message in
                MessageRowView(message: message) {
                    showServerMessage(message)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
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
    
    // MARK: - Setup
    
    private func setupNotifyLight() {
        // Handle message events
        notifyLight.onMessage { message in
            DispatchQueue.main.async {
                handleMessageReceived(message)
            }
        }
        
        // Enable auto message checking
        notifyLight.enableAutoMessageCheck(interval: 60)
    }
    
    // MARK: - Message Examples
    
    private func showBasicAlert() {
        notifyLight.showAlert(
            title: "Welcome!",
            message: "Welcome to NotifyLight SwiftUI integration. This is a basic alert-style message.",
            completion: {
                updateStatus("Basic alert dismissed")
            }
        )
    }
    
    private func showCardMessage() {
        let actions = [
            MessageAction(id: "learn", title: "Learn More", style: .primary),
            MessageAction(id: "dismiss", title: "Maybe Later", style: .secondary)
        ]
        
        notifyLight.showCard(
            title: "New Feature Available",
            message: "We've added exciting new features to enhance your experience. Would you like to learn more?",
            actions: actions,
            completion: {
                updateStatus("Card message dismissed")
            }
        )
    }
    
    private func showCustomSwiftUIMessage() {
        let message = InAppMessage(
            id: "custom-swiftui",
            title: "SwiftUI Custom Message",
            message: "This message uses SwiftUI styling with modern design patterns and smooth animations.",
            actions: [
                MessageAction(id: "awesome", title: "Awesome!", style: .primary),
                MessageAction(id: "customize", title: "Customize", style: .secondary)
            ]
        )
        
        customMessage = message
        showingCustomMessage = true
    }
    
    private func showSurveyMessage() {
        let surveyMessage = InAppMessage(
            id: "survey-swiftui",
            title: "Quick Survey",
            message: "How would you rate your experience with NotifyLight SwiftUI integration?",
            actions: [
                MessageAction(id: "excellent", title: "Excellent", style: .primary),
                MessageAction(id: "good", title: "Good", style: .secondary),
                MessageAction(id: "average", title: "Average", style: .secondary),
                MessageAction(id: "poor", title: "Poor", style: .destructive)
            ]
        )
        
        let customization = InAppMessageSwiftUICustomization.default
        notifyLight.presentMessage(
            surveyMessage,
            swiftUICustomization: customization,
            completion: {
                updateStatus("Survey completed")
            }
        )
    }
    
    private func showMinimalMessage() {
        let message = InAppMessage(
            id: "minimal-swiftui",
            title: "Minimal Design",
            message: "This message uses minimal styling for a clean, simple appearance.",
            actions: [
                MessageAction(id: "got-it", title: "Got it", style: .primary)
            ]
        )
        
        notifyLight.presentMessage(
            message,
            swiftUICustomization: .minimal,
            completion: {
                updateStatus("Minimal message dismissed")
            }
        )
    }
    
    private func fetchServerMessages() {
        updateStatus("Fetching messages...")
        
        Task {
            do {
                let messages = try await notifyLight.fetchMessages()
                await MainActor.run {
                    self.updateStatus("Fetched \(messages.count) messages")
                    self.currentMessages = messages
                }
            } catch {
                await MainActor.run {
                    self.updateStatus("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showServerMessage(_ message: InAppMessage) {
        let customization = InAppMessageSwiftUICustomization.card
        notifyLight.presentMessage(
            message,
            swiftUICustomization: customization,
            completion: {
                updateStatus("Server message dismissed: \(message.title)")
            }
        )
    }
    
    // MARK: - Event Handling
    
    private func handleMessageReceived(_ message: InAppMessage) {
        updateStatus("Message received: \(message.title)")
        
        // Add to current messages if not already present
        if !currentMessages.contains(where: { $0.id == message.id }) {
            currentMessages.append(message)
        }
    }
    
    private func handleMessageAction(_ action: MessageAction) {
        switch action.id {
        case "learn":
            openLearnMore()
        case "customize":
            openCustomization()
        case "excellent", "good", "average", "poor":
            submitSurveyRating(action.id)
        default:
            updateStatus("Action: \(action.title)")
        }
    }
    
    private func updateStatus(_ text: String) {
        statusMessage = text
        print("🔔 \(text)")
    }
    
    // MARK: - Action Handlers
    
    private func openLearnMore() {
        updateStatus("Opening learn more...")
        // Navigate to learn more screen
    }
    
    private func openCustomization() {
        updateStatus("Opening customization...")
        // Navigate to customization screen
    }
    
    private func submitSurveyRating(_ rating: String) {
        updateStatus("Rating submitted: \(rating)")
        
        // Show thank you message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            notifyLight.showAlert(
                title: "Thank You!",
                message: "Thank you for your feedback. It helps us improve."
            )
        }
    }
}

// MARK: - Supporting Views

struct DemoButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MessageRowView: View {
    let message: InAppMessage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(message.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !message.actions.isEmpty {
                    HStack {
                        ForEach(message.actions, id: \.id) { action in
                            Text(action.title)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Advanced Examples

struct AdvancedSwiftUIExampleView: View {
    @State private var showingMessage = false
    @State private var selectedStyle: CustomStyle = .modern
    @State private var currentMessage: InAppMessage?
    
    enum CustomStyle: String, CaseIterable {
        case modern = "Modern"
        case minimal = "Minimal"
        case card = "Card"
        case compact = "Compact"
        
        var customization: InAppMessageSwiftUICustomization {
            switch self {
            case .modern:
                return .default
            case .minimal:
                return .minimal
            case .card:
                return .card
            case .compact:
                return .compact
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Advanced Customization")
                .font(.title)
                .fontWeight(.bold)
            
            // Style picker
            Picker("Style", selection: $selectedStyle) {
                ForEach(CustomStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Preview button
            Button("Preview Message") {
                showPreviewMessage()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
            
            Spacer()
        }
        .padding()
        .inAppMessage(
            isPresented: $showingMessage,
            message: currentMessage ?? defaultMessage,
            customization: selectedStyle.customization,
            onAction: { action in
                print("Action pressed: \(action.title)")
            }
        )
    }
    
    private var defaultMessage: InAppMessage {
        InAppMessage(
            id: "preview",
            title: "Preview Message",
            message: "This is a preview of the \(selectedStyle.rawValue) style message.",
            actions: [
                MessageAction(id: "like", title: "I Like It", style: .primary),
                MessageAction(id: "change", title: "Change Style", style: .secondary)
            ]
        )
    }
    
    private func showPreviewMessage() {
        currentMessage = defaultMessage
        showingMessage = true
    }
}

// MARK: - Preview

struct SwiftUIExampleView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIExampleView()
    }
}

struct AdvancedSwiftUIExampleView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSwiftUIExampleView()
    }
}