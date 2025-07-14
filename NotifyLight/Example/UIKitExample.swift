import UIKit
import NotifyLight

/// Example UIKit view controller demonstrating in-app message integration
class UIKitExampleViewController: UIViewController {
    
    // MARK: - UI Components
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    // MARK: - Properties
    
    private var currentMessages: [InAppMessage] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifyLight()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "UIKit In-App Messages"
        view.backgroundColor = .systemBackground
        
        // Title label
        titleLabel.text = "NotifyLight UIKit Demo"
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.textAlignment = .center
        
        // Status label
        statusLabel.text = "Ready"
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        
        // Create demo buttons
        createDemoButtons()
    }
    
    private func createDemoButtons() {
        // Basic Alert Button
        let alertButton = createButton(title: "Show Alert", backgroundColor: .systemBlue) { [weak self] in
            self?.showBasicAlert()
        }
        stackView.addArrangedSubview(alertButton)
        
        // Card Message Button
        let cardButton = createButton(title: "Show Card Message", backgroundColor: .systemGreen) { [weak self] in
            self?.showCardMessage()
        }
        stackView.addArrangedSubview(cardButton)
        
        // Custom Message Button
        let customButton = createButton(title: "Show Custom Message", backgroundColor: .systemOrange) { [weak self] in
            self?.showCustomMessage()
        }
        stackView.addArrangedSubview(customButton)
        
        // Survey Message Button
        let surveyButton = createButton(title: "Show Survey", backgroundColor: .systemPurple) { [weak self] in
            self?.showSurveyMessage()
        }
        stackView.addArrangedSubview(surveyButton)
        
        // Fetch Server Messages Button
        let fetchButton = createButton(title: "Fetch Server Messages", backgroundColor: .systemTeal) { [weak self] in
            self?.fetchServerMessages()
        }
        stackView.addArrangedSubview(fetchButton)
        
        // Minimal Style Button
        let minimalButton = createButton(title: "Show Minimal Message", backgroundColor: .systemIndigo) { [weak self] in
            self?.showMinimalMessage()
        }
        stackView.addArrangedSubview(minimalButton)
    }
    
    private func createButton(title: String, backgroundColor: UIColor, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        
        return button
    }
    
    private func setupNotifyLight() {
        // Handle message events
        NotifyLight.shared.onMessage { [weak self] message in
            DispatchQueue.main.async {
                self?.handleMessageReceived(message)
            }
        }
        
        // Check for messages periodically
        NotifyLight.shared.enableAutoMessageCheck(interval: 60)
    }
    
    // MARK: - Message Examples
    
    private func showBasicAlert() {
        NotifyLight.shared.showAlert(
            title: "Welcome!",
            message: "Welcome to NotifyLight UIKit integration. This is a basic alert-style message.",
            completion: { [weak self] in
                self?.updateStatus("Basic alert dismissed")
            }
        )
    }
    
    private func showCardMessage() {
        let actions = [
            MessageAction(id: "learn", title: "Learn More", style: .primary),
            MessageAction(id: "dismiss", title: "Maybe Later", style: .secondary)
        ]
        
        NotifyLight.shared.showCard(
            title: "New Feature Available",
            message: "We've added exciting new features to enhance your experience. Would you like to learn more?",
            actions: actions,
            completion: { [weak self] in
                self?.updateStatus("Card message dismissed")
            }
        )
    }
    
    private func showCustomMessage() {
        let message = InAppMessage(
            id: "custom-demo",
            title: "Custom Styled Message",
            message: "This message uses custom styling with a unique appearance and behavior.",
            actions: [
                MessageAction(id: "awesome", title: "Awesome!", style: .primary),
                MessageAction(id: "ok", title: "OK", style: .secondary)
            ]
        )
        
        // Custom styling
        var customization = InAppMessageCustomization.default
        customization.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        customization.titleColor = .systemPurple
        customization.primaryActionColor = .systemPurple
        customization.cornerRadius = 24
        customization.enableHapticFeedback = true
        customization.animationDuration = 0.6
        
        NotifyLight.shared.presentMessage(
            message,
            customization: customization,
            completion: { [weak self] in
                self?.updateStatus("Custom message dismissed")
            }
        )
    }
    
    private func showSurveyMessage() {
        let surveyMessage = InAppMessage(
            id: "survey-demo",
            title: "Quick Survey",
            message: "How would you rate your experience with NotifyLight?",
            actions: [
                MessageAction(id: "excellent", title: "Excellent", style: .primary),
                MessageAction(id: "good", title: "Good", style: .secondary),
                MessageAction(id: "average", title: "Average", style: .secondary),
                MessageAction(id: "poor", title: "Poor", style: .destructive)
            ]
        )
        
        NotifyLight.shared.presentMessage(
            surveyMessage,
            completion: { [weak self] in
                self?.updateStatus("Survey completed")
            }
        )
    }
    
    private func showMinimalMessage() {
        let message = InAppMessage(
            id: "minimal-demo",
            title: "Minimal Design",
            message: "This message uses minimal styling for a clean, simple appearance.",
            actions: [
                MessageAction(id: "got-it", title: "Got it", style: .primary)
            ]
        )
        
        NotifyLight.shared.presentMessage(
            message,
            customization: .minimal,
            completion: { [weak self] in
                self?.updateStatus("Minimal message dismissed")
            }
        )
    }
    
    private func fetchServerMessages() {
        updateStatus("Fetching messages...")
        
        Task {
            do {
                let messages = try await NotifyLight.shared.fetchMessages()
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
    
    // MARK: - Event Handling
    
    private func handleMessageReceived(_ message: InAppMessage) {
        updateStatus("Message received: \(message.title)")
        
        // Automatically present server messages
        if !currentMessages.contains(where: { $0.id == message.id }) {
            currentMessages.append(message)
        }
    }
    
    private func updateStatus(_ text: String) {
        statusLabel.text = text
        print("🔔 \(text)")
    }
}

// MARK: - Storyboard Integration

extension UIKitExampleViewController {
    
    /// Example of integrating with storyboard-based apps
    static func instantiateFromStoryboard() -> UIKitExampleViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "UIKitExampleViewController") as! UIKitExampleViewController
    }
}

// MARK: - UINavigationController Integration

extension UIKitExampleViewController {
    
    /// Example of showing messages in navigation controller context
    func showNavigationMessage() {
        let message = InAppMessage(
            id: "nav-demo",
            title: "Navigation Message",
            message: "This message is presented within a navigation controller context.",
            actions: [
                MessageAction(id: "settings", title: "Settings", style: .primary),
                MessageAction(id: "close", title: "Close", style: .secondary)
            ]
        )
        
        // Custom styling for navigation context
        var customization = InAppMessageCustomization.default
        customization.horizontalPadding = 16
        customization.allowSwipeToDismiss = true
        
        NotifyLight.shared.presentMessage(message, customization: customization) { [weak self] in
            self?.updateStatus("Navigation message dismissed")
        }
    }
}

// MARK: - UITabBarController Integration

extension UIKitExampleViewController {
    
    /// Example of showing messages in tab bar controller context
    func showTabBarMessage() {
        let message = InAppMessage(
            id: "tab-demo",
            title: "Tab Bar Message",
            message: "This message appears over the tab bar interface.",
            actions: [
                MessageAction(id: "switch-tab", title: "Switch Tab", style: .primary),
                MessageAction(id: "stay", title: "Stay Here", style: .secondary)
            ]
        )
        
        NotifyLight.shared.presentMessage(message) { [weak self] in
            self?.updateStatus("Tab bar message dismissed")
        }
    }
}

// MARK: - Custom Action Handling

extension UIKitExampleViewController {
    
    /// Example of custom action handling
    func handleCustomAction(_ action: MessageAction, message: InAppMessage) {
        switch action.id {
        case "learn":
            openLearnMore()
        case "settings":
            openSettings()
        case "switch-tab":
            switchToTab(1)
        case "excellent", "good", "average", "poor":
            submitSurveyRating(action.id)
        default:
            updateStatus("Action: \(action.title)")
        }
    }
    
    private func openLearnMore() {
        // Open learn more screen
        updateStatus("Opening learn more...")
    }
    
    private func openSettings() {
        // Open settings screen
        updateStatus("Opening settings...")
    }
    
    private func switchToTab(_ index: Int) {
        // Switch to specific tab
        if let tabBarController = tabBarController {
            tabBarController.selectedIndex = index
        }
        updateStatus("Switched to tab \(index)")
    }
    
    private func submitSurveyRating(_ rating: String) {
        // Submit survey rating
        updateStatus("Rating submitted: \(rating)")
        
        // Show thank you message
        NotifyLight.shared.showAlert(
            title: "Thank You!",
            message: "Thank you for your feedback. It helps us improve."
        )
    }
}