import UIKit

/// UIKit-based in-app message view controller with native iOS design
public final class InAppMessageViewController: UIViewController {
    
    // MARK: - Properties
    
    private let message: InAppMessage
    private let customization: InAppMessageCustomization
    private let onAction: ((MessageAction) -> Void)?
    private let onDismiss: (() -> Void)?
    
    // UI Components
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let containerView = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionStackView = UIStackView()
    private let dismissButton = UIButton(type: .system)
    
    // Gesture recognizers
    private let tapGestureRecognizer = UITapGestureRecognizer()
    private let swipeGestureRecognizer = UISwipeGestureRecognizer()
    
    // Animation properties
    private var containerCenterYConstraint: NSLayoutConstraint!
    private var containerBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    
    public init(
        message: InAppMessage,
        customization: InAppMessageCustomization = .default,
        onAction: ((MessageAction) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.customization = customization
        self.onAction = onAction
        self.onDismiss = onDismiss
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        setupAccessibility()
        configureContent()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animatePresentation()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCornerRadius()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        // Background blur effect
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.alpha = 0
        view.addSubview(backgroundView)
        
        // Container view
        containerView.backgroundColor = customization.backgroundColor
        containerView.layer.cornerRadius = customization.cornerRadius
        containerView.layer.masksToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Scroll view for content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        containerView.addSubview(scrollView)
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title label
        titleLabel.font = customization.titleFont
        titleLabel.textColor = customization.titleColor
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Message label
        messageLabel.font = customization.messageFont
        messageLabel.textColor = customization.messageColor
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel)
        
        // Action stack view
        actionStackView.axis = .vertical
        actionStackView.spacing = customization.actionSpacing
        actionStackView.alignment = .fill
        actionStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionStackView)
        
        // Dismiss button (if enabled)
        if customization.showDismissButton {
            dismissButton.setTitle("✕", for: .normal)
            dismissButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            dismissButton.tintColor = customization.dismissButtonColor
            dismissButton.translatesAutoresizingMaskIntoConstraints = false
            dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
            containerView.addSubview(dismissButton)
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Background view constraints
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Container view constraints
        containerCenterYConstraint = containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: view.bounds.height)
        containerBottomConstraint = containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: customization.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -customization.horizontalPadding),
            containerView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerCenterYConstraint,
            containerBottomConstraint
        ])
        
        // Scroll view constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: customization.contentPadding),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: customization.contentPadding),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -customization.contentPadding),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -customization.contentPadding)
        ])
        
        // Content view constraints
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Title label constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // Message label constraints
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: customization.titleMessageSpacing),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // Action stack view constraints
        NSLayoutConstraint.activate([
            actionStackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: customization.messageActionSpacing),
            actionStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actionStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Dismiss button constraints
        if customization.showDismissButton {
            NSLayoutConstraint.activate([
                dismissButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
                dismissButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
                dismissButton.widthAnchor.constraint(equalToConstant: 32),
                dismissButton.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }
    
    private func setupGestures() {
        // Tap to dismiss background
        if customization.allowBackgroundDismiss {
            tapGestureRecognizer.addTarget(self, action: #selector(backgroundTapped))
            backgroundView.addGestureRecognizer(tapGestureRecognizer)
        }
        
        // Swipe to dismiss
        if customization.allowSwipeToDismiss {
            swipeGestureRecognizer.direction = .down
            swipeGestureRecognizer.addTarget(self, action: #selector(swipeTodismiss))
            containerView.addGestureRecognizer(swipeGestureRecognizer)
        }
    }
    
    private func setupAccessibility() {
        // Container accessibility
        containerView.accessibilityTraits = .none
        containerView.accessibilityLabel = "In-app message"
        
        // Title accessibility
        titleLabel.accessibilityTraits = .header
        
        // Message accessibility
        messageLabel.accessibilityTraits = .staticText
        
        // Dismiss button accessibility
        if customization.showDismissButton {
            dismissButton.accessibilityLabel = "Dismiss message"
            dismissButton.accessibilityTraits = .button
        }
        
        // Post accessibility notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .screenChanged, argument: self.titleLabel)
        }
    }
    
    private func configureContent() {
        titleLabel.text = message.title
        messageLabel.text = message.message
        
        // Configure action buttons
        for action in message.actions {
            let button = createActionButton(for: action)
            actionStackView.addArrangedSubview(button)
        }
        
        // If no actions, add a default dismiss button
        if message.actions.isEmpty {
            let defaultAction = MessageAction(id: "dismiss", title: "OK", style: .primary)
            let button = createActionButton(for: defaultAction)
            actionStackView.addArrangedSubview(button)
        }
    }
    
    private func createActionButton(for action: MessageAction) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = customization.actionButtonFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = customization.actionButtonCornerRadius
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        
        // Configure button appearance based on action style
        switch action.style {
        case .primary:
            button.backgroundColor = customization.primaryActionColor
            button.setTitleColor(customization.primaryActionTextColor, for: .normal)
            button.titleLabel?.font = customization.actionButtonFont.withWeight(.semibold)
            
        case .secondary:
            button.backgroundColor = customization.secondaryActionColor
            button.setTitleColor(customization.secondaryActionTextColor, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = customization.secondaryActionBorderColor.cgColor
            
        case .destructive:
            button.backgroundColor = customization.destructiveActionColor
            button.setTitleColor(customization.destructiveActionTextColor, for: .normal)
        }
        
        // Add target
        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        button.tag = message.actions.firstIndex(where: { $0.id == action.id }) ?? 0
        
        // Accessibility
        button.accessibilityLabel = action.title
        button.accessibilityTraits = .button
        
        return button
    }
    
    private func updateCornerRadius() {
        if customization.adaptiveCornerRadius {
            let maxCornerRadius = min(containerView.bounds.width, containerView.bounds.height) * 0.1
            containerView.layer.cornerRadius = min(customization.cornerRadius, maxCornerRadius)
        }
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        let action = sender.tag < message.actions.count ? message.actions[sender.tag] : 
                     MessageAction(id: "dismiss", title: "OK", style: .primary)
        
        // Haptic feedback
        if customization.enableHapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        onAction?(action)
        dismiss()
    }
    
    @objc private func dismissButtonTapped() {
        dismiss()
    }
    
    @objc private func backgroundTapped() {
        dismiss()
    }
    
    @objc private func swipeTodismiss() {
        dismiss()
    }
    
    // MARK: - Animation
    
    private func animatePresentation() {
        // Initial state
        containerCenterYConstraint.constant = view.bounds.height
        view.layoutIfNeeded()
        
        // Animate to final state
        UIView.animate(
            withDuration: customization.animationDuration,
            delay: 0,
            usingSpringWithDamping: customization.animationSpringDamping,
            initialSpringVelocity: customization.animationSpringVelocity,
            options: [.allowUserInteraction, .curveEaseOut],
            animations: {
                self.backgroundView.alpha = 1
                self.containerCenterYConstraint.constant = 0
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                // Haptic feedback on presentation
                if self.customization.enableHapticFeedback {
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                }
            }
        )
    }
    
    private func dismiss() {
        // Animate dismissal
        UIView.animate(
            withDuration: customization.animationDuration * 0.8,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction, .curveEaseIn],
            animations: {
                self.backgroundView.alpha = 0
                self.containerCenterYConstraint.constant = self.view.bounds.height
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.onDismiss?()
                self.dismiss(animated: false)
            }
        )
    }
}

// MARK: - Customization

/// Customization options for in-app message presentation
public struct InAppMessageCustomization {
    
    // MARK: - Colors
    
    public var backgroundColor: UIColor
    public var titleColor: UIColor
    public var messageColor: UIColor
    public var dismissButtonColor: UIColor
    
    // Action button colors
    public var primaryActionColor: UIColor
    public var primaryActionTextColor: UIColor
    public var secondaryActionColor: UIColor
    public var secondaryActionTextColor: UIColor
    public var secondaryActionBorderColor: UIColor
    public var destructiveActionColor: UIColor
    public var destructiveActionTextColor: UIColor
    
    // MARK: - Typography
    
    public var titleFont: UIFont
    public var messageFont: UIFont
    public var actionButtonFont: UIFont
    
    // MARK: - Layout
    
    public var cornerRadius: CGFloat
    public var adaptiveCornerRadius: Bool
    public var horizontalPadding: CGFloat
    public var contentPadding: CGFloat
    public var titleMessageSpacing: CGFloat
    public var messageActionSpacing: CGFloat
    public var actionSpacing: CGFloat
    public var actionButtonCornerRadius: CGFloat
    
    // MARK: - Behavior
    
    public var showDismissButton: Bool
    public var allowBackgroundDismiss: Bool
    public var allowSwipeToDismiss: Bool
    public var enableHapticFeedback: Bool
    
    // MARK: - Animation
    
    public var animationDuration: TimeInterval
    public var animationSpringDamping: CGFloat
    public var animationSpringVelocity: CGFloat
    
    // MARK: - Initialization
    
    public init(
        backgroundColor: UIColor = .systemBackground,
        titleColor: UIColor = .label,
        messageColor: UIColor = .secondaryLabel,
        dismissButtonColor: UIColor = .systemGray,
        primaryActionColor: UIColor = .systemBlue,
        primaryActionTextColor: UIColor = .white,
        secondaryActionColor: UIColor = .systemGray6,
        secondaryActionTextColor: UIColor = .label,
        secondaryActionBorderColor: UIColor = .systemGray4,
        destructiveActionColor: UIColor = .systemRed,
        destructiveActionTextColor: UIColor = .white,
        titleFont: UIFont = .preferredFont(forTextStyle: .headline),
        messageFont: UIFont = .preferredFont(forTextStyle: .body),
        actionButtonFont: UIFont = .preferredFont(forTextStyle: .callout),
        cornerRadius: CGFloat = 16,
        adaptiveCornerRadius: Bool = true,
        horizontalPadding: CGFloat = 20,
        contentPadding: CGFloat = 24,
        titleMessageSpacing: CGFloat = 12,
        messageActionSpacing: CGFloat = 24,
        actionSpacing: CGFloat = 12,
        actionButtonCornerRadius: CGFloat = 12,
        showDismissButton: Bool = true,
        allowBackgroundDismiss: Bool = true,
        allowSwipeToDismiss: Bool = true,
        enableHapticFeedback: Bool = true,
        animationDuration: TimeInterval = 0.4,
        animationSpringDamping: CGFloat = 0.8,
        animationSpringVelocity: CGFloat = 0.5
    ) {
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.messageColor = messageColor
        self.dismissButtonColor = dismissButtonColor
        self.primaryActionColor = primaryActionColor
        self.primaryActionTextColor = primaryActionTextColor
        self.secondaryActionColor = secondaryActionColor
        self.secondaryActionTextColor = secondaryActionTextColor
        self.secondaryActionBorderColor = secondaryActionBorderColor
        self.destructiveActionColor = destructiveActionColor
        self.destructiveActionTextColor = destructiveActionTextColor
        self.titleFont = titleFont
        self.messageFont = messageFont
        self.actionButtonFont = actionButtonFont
        self.cornerRadius = cornerRadius
        self.adaptiveCornerRadius = adaptiveCornerRadius
        self.horizontalPadding = horizontalPadding
        self.contentPadding = contentPadding
        self.titleMessageSpacing = titleMessageSpacing
        self.messageActionSpacing = messageActionSpacing
        self.actionSpacing = actionSpacing
        self.actionButtonCornerRadius = actionButtonCornerRadius
        self.showDismissButton = showDismissButton
        self.allowBackgroundDismiss = allowBackgroundDismiss
        self.allowSwipeToDismiss = allowSwipeToDismiss
        self.enableHapticFeedback = enableHapticFeedback
        self.animationDuration = animationDuration
        self.animationSpringDamping = animationSpringDamping
        self.animationSpringVelocity = animationSpringVelocity
    }
    
    // MARK: - Presets
    
    public static let `default` = InAppMessageCustomization()
    
    public static let minimal = InAppMessageCustomization(
        backgroundColor: .systemBackground,
        cornerRadius: 8,
        showDismissButton: false,
        allowBackgroundDismiss: false,
        enableHapticFeedback: false
    )
    
    public static let card = InAppMessageCustomization(
        backgroundColor: .systemBackground,
        cornerRadius: 16,
        horizontalPadding: 16,
        contentPadding: 20,
        allowSwipeToDismiss: false
    )
    
    public static let alert = InAppMessageCustomization(
        backgroundColor: .systemBackground,
        cornerRadius: 14,
        horizontalPadding: 40,
        showDismissButton: false,
        allowBackgroundDismiss: false,
        allowSwipeToDismiss: false
    )
}

// MARK: - UIFont Extension

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}