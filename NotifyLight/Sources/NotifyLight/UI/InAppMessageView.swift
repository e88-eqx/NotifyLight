import SwiftUI

/// SwiftUI-based in-app message view with modern design
public struct InAppMessageView: View {
    
    // MARK: - Properties
    
    let message: InAppMessage
    let customization: InAppMessageSwiftUICustomization
    let onAction: ((MessageAction) -> Void)?
    let onDismiss: (() -> Void)?
    
    @State private var isPresented = false
    @State private var dragOffset: CGSize = .zero
    @State private var backgroundOpacity: Double = 0
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Initialization
    
    public init(
        message: InAppMessage,
        customization: InAppMessageSwiftUICustomization = .default,
        onAction: ((MessageAction) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.customization = customization
        self.onAction = onAction
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Message content
            messageContentView
                .offset(y: dragOffset.height)
                .scaleEffect(isPresented ? 1.0 : 0.9)
                .opacity(isPresented ? 1.0 : 0)
                .animation(
                    reduceMotion ? .none : customization.presentationAnimation,
                    value: isPresented
                )
                .animation(
                    reduceMotion ? .none : customization.dragAnimation,
                    value: dragOffset
                )
        }
        .onAppear {
            withAnimation {
                isPresented = true
                backgroundOpacity = 1
            }
            
            // Haptic feedback on presentation
            if customization.enableHapticFeedback {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("In-app message")
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        customization.backgroundMaterial
            .opacity(backgroundOpacity)
            .ignoresSafeArea()
            .onTapGesture {
                if customization.allowBackgroundDismiss {
                    dismiss()
                }
            }
    }
    
    // MARK: - Message Content View
    
    private var messageContentView: some View {
        VStack(spacing: 0) {
            // Dismiss button
            if customization.showDismissButton {
                dismissButtonView
            }
            
            // Content
            VStack(spacing: customization.contentSpacing) {
                // Title
                if !message.title.isEmpty {
                    titleView
                }
                
                // Message
                if !message.message.isEmpty {
                    messageView
                }
                
                // Actions
                if !message.actions.isEmpty {
                    actionButtonsView
                } else {
                    defaultActionView
                }
            }
            .padding(customization.contentPadding)
        }
        .background(customization.backgroundColor)
        .cornerRadius(customization.cornerRadius)
        .shadow(
            color: customization.shadowColor,
            radius: customization.shadowRadius,
            x: customization.shadowOffset.width,
            y: customization.shadowOffset.height
        )
        .padding(.horizontal, customization.horizontalMargin)
        .gesture(
            customization.allowSwipeToDismiss ? swipeGesture : nil
        )
    }
    
    // MARK: - Dismiss Button View
    
    private var dismissButtonView: some View {
        HStack {
            Spacer()
            
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(customization.dismissButtonColor)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Dismiss message")
            .accessibilityRole(.button)
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Title View
    
    private var titleView: some View {
        Text(message.title)
            .font(customization.titleFont)
            .foregroundColor(customization.titleColor)
            .multilineTextAlignment(.center)
            .lineLimit(customization.titleLineLimit)
            .dynamicTypeSize(customization.maxDynamicTypeSize)
            .accessibilityRole(.header)
    }
    
    // MARK: - Message View
    
    private var messageView: some View {
        Text(message.message)
            .font(customization.messageFont)
            .foregroundColor(customization.messageColor)
            .multilineTextAlignment(.center)
            .lineLimit(customization.messageLineLimit)
            .dynamicTypeSize(customization.maxDynamicTypeSize)
            .accessibilityRole(.text)
    }
    
    // MARK: - Action Buttons View
    
    private var actionButtonsView: some View {
        let arrangedActions = arrangeActions()
        
        return VStack(spacing: customization.actionSpacing) {
            ForEach(arrangedActions, id: \.0) { (index, actions) in
                HStack(spacing: customization.actionSpacing) {
                    ForEach(actions, id: \.id) { action in
                        actionButton(for: action)
                    }
                }
            }
        }
        .padding(.top, customization.actionTopPadding)
    }
    
    // MARK: - Default Action View
    
    private var defaultActionView: some View {
        let defaultAction = MessageAction(id: "dismiss", title: "OK", style: .primary)
        
        return VStack {
            actionButton(for: defaultAction)
        }
        .padding(.top, customization.actionTopPadding)
    }
    
    // MARK: - Action Button
    
    private func actionButton(for action: MessageAction) -> some View {
        Button(action: {
            handleAction(action)
        }) {
            Text(action.title)
                .font(customization.actionButtonFont)
                .foregroundColor(textColor(for: action.style))
                .frame(maxWidth: .infinity)
                .frame(height: customization.actionButtonHeight)
                .background(backgroundColor(for: action.style))
                .cornerRadius(customization.actionButtonCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: customization.actionButtonCornerRadius)
                        .stroke(borderColor(for: action.style), lineWidth: borderWidth(for: action.style))
                )
        }
        .buttonStyle(InAppMessageButtonStyle(
            style: action.style,
            customization: customization
        ))
        .accessibilityLabel(action.title)
        .accessibilityRole(.button)
        .dynamicTypeSize(customization.maxDynamicTypeSize)
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation
                if translation.y > 0 {
                    dragOffset = translation
                    backgroundOpacity = max(0.3, 1 - translation.y / 200)
                }
            }
            .onEnded { value in
                if value.translation.y > 100 {
                    dismiss()
                } else {
                    withAnimation(customization.dragAnimation) {
                        dragOffset = .zero
                        backgroundOpacity = 1
                    }
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func arrangeActions() -> [(Int, [MessageAction])] {
        let actions = message.actions
        var arranged: [(Int, [MessageAction])] = []
        
        // Group actions based on customization
        if customization.actionsLayout == .vertical {
            arranged = actions.enumerated().map { (index, action) in
                (index, [action])
            }
        } else {
            // Horizontal layout - group actions in pairs
            var currentRow: [MessageAction] = []
            var rowIndex = 0
            
            for action in actions {
                currentRow.append(action)
                
                if currentRow.count == 2 || action == actions.last {
                    arranged.append((rowIndex, currentRow))
                    currentRow = []
                    rowIndex += 1
                }
            }
        }
        
        return arranged
    }
    
    private func textColor(for style: ActionStyle) -> Color {
        switch style {
        case .primary:
            return customization.primaryActionTextColor
        case .secondary:
            return customization.secondaryActionTextColor
        case .destructive:
            return customization.destructiveActionTextColor
        }
    }
    
    private func backgroundColor(for style: ActionStyle) -> Color {
        switch style {
        case .primary:
            return customization.primaryActionBackgroundColor
        case .secondary:
            return customization.secondaryActionBackgroundColor
        case .destructive:
            return customization.destructiveActionBackgroundColor
        }
    }
    
    private func borderColor(for style: ActionStyle) -> Color {
        switch style {
        case .primary:
            return .clear
        case .secondary:
            return customization.secondaryActionBorderColor
        case .destructive:
            return .clear
        }
    }
    
    private func borderWidth(for style: ActionStyle) -> CGFloat {
        switch style {
        case .primary, .destructive:
            return 0
        case .secondary:
            return 1
        }
    }
    
    private func handleAction(_ action: MessageAction) {
        // Haptic feedback
        if customization.enableHapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        onAction?(action)
        dismiss()
    }
    
    private func dismiss() {
        withAnimation(customization.dismissAnimation) {
            isPresented = false
            backgroundOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + customization.dismissAnimation.duration) {
            onDismiss?()
        }
    }
}

// MARK: - SwiftUI Customization

/// Customization options for SwiftUI in-app message
public struct InAppMessageSwiftUICustomization {
    
    // MARK: - Colors
    
    public var backgroundColor: Color
    public var backgroundMaterial: Material
    public var titleColor: Color
    public var messageColor: Color
    public var dismissButtonColor: Color
    public var shadowColor: Color
    
    // Action colors
    public var primaryActionBackgroundColor: Color
    public var primaryActionTextColor: Color
    public var secondaryActionBackgroundColor: Color
    public var secondaryActionTextColor: Color
    public var secondaryActionBorderColor: Color
    public var destructiveActionBackgroundColor: Color
    public var destructiveActionTextColor: Color
    
    // MARK: - Typography
    
    public var titleFont: Font
    public var messageFont: Font
    public var actionButtonFont: Font
    public var maxDynamicTypeSize: DynamicTypeSize
    
    // MARK: - Layout
    
    public var cornerRadius: CGFloat
    public var horizontalMargin: CGFloat
    public var contentPadding: EdgeInsets
    public var contentSpacing: CGFloat
    public var actionTopPadding: CGFloat
    public var actionSpacing: CGFloat
    public var actionButtonHeight: CGFloat
    public var actionButtonCornerRadius: CGFloat
    public var actionsLayout: ActionsLayout
    
    // MARK: - Shadow
    
    public var shadowRadius: CGFloat
    public var shadowOffset: CGSize
    
    // MARK: - Behavior
    
    public var showDismissButton: Bool
    public var allowBackgroundDismiss: Bool
    public var allowSwipeToDismiss: Bool
    public var enableHapticFeedback: Bool
    public var titleLineLimit: Int?
    public var messageLineLimit: Int?
    
    // MARK: - Animations
    
    public var presentationAnimation: Animation
    public var dismissAnimation: Animation
    public var dragAnimation: Animation
    
    // MARK: - Initialization
    
    public init(
        backgroundColor: Color = Color(.systemBackground),
        backgroundMaterial: Material = .ultraThinMaterial,
        titleColor: Color = .primary,
        messageColor: Color = .secondary,
        dismissButtonColor: Color = .secondary,
        shadowColor: Color = Color.black.opacity(0.1),
        primaryActionBackgroundColor: Color = .blue,
        primaryActionTextColor: Color = .white,
        secondaryActionBackgroundColor: Color = Color(.systemGray6),
        secondaryActionTextColor: Color = .primary,
        secondaryActionBorderColor: Color = Color(.systemGray4),
        destructiveActionBackgroundColor: Color = .red,
        destructiveActionTextColor: Color = .white,
        titleFont: Font = .headline,
        messageFont: Font = .body,
        actionButtonFont: Font = .callout.weight(.medium),
        maxDynamicTypeSize: DynamicTypeSize = .accessibility1,
        cornerRadius: CGFloat = 16,
        horizontalMargin: CGFloat = 20,
        contentPadding: EdgeInsets = EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24),
        contentSpacing: CGFloat = 16,
        actionTopPadding: CGFloat = 8,
        actionSpacing: CGFloat = 12,
        actionButtonHeight: CGFloat = 48,
        actionButtonCornerRadius: CGFloat = 12,
        actionsLayout: ActionsLayout = .horizontal,
        shadowRadius: CGFloat = 20,
        shadowOffset: CGSize = CGSize(width: 0, height: 10),
        showDismissButton: Bool = true,
        allowBackgroundDismiss: Bool = true,
        allowSwipeToDismiss: Bool = true,
        enableHapticFeedback: Bool = true,
        titleLineLimit: Int? = 3,
        messageLineLimit: Int? = 6,
        presentationAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0),
        dismissAnimation: Animation = .easeInOut(duration: 0.3),
        dragAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
    ) {
        self.backgroundColor = backgroundColor
        self.backgroundMaterial = backgroundMaterial
        self.titleColor = titleColor
        self.messageColor = messageColor
        self.dismissButtonColor = dismissButtonColor
        self.shadowColor = shadowColor
        self.primaryActionBackgroundColor = primaryActionBackgroundColor
        self.primaryActionTextColor = primaryActionTextColor
        self.secondaryActionBackgroundColor = secondaryActionBackgroundColor
        self.secondaryActionTextColor = secondaryActionTextColor
        self.secondaryActionBorderColor = secondaryActionBorderColor
        self.destructiveActionBackgroundColor = destructiveActionBackgroundColor
        self.destructiveActionTextColor = destructiveActionTextColor
        self.titleFont = titleFont
        self.messageFont = messageFont
        self.actionButtonFont = actionButtonFont
        self.maxDynamicTypeSize = maxDynamicTypeSize
        self.cornerRadius = cornerRadius
        self.horizontalMargin = horizontalMargin
        self.contentPadding = contentPadding
        self.contentSpacing = contentSpacing
        self.actionTopPadding = actionTopPadding
        self.actionSpacing = actionSpacing
        self.actionButtonHeight = actionButtonHeight
        self.actionButtonCornerRadius = actionButtonCornerRadius
        self.actionsLayout = actionsLayout
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.showDismissButton = showDismissButton
        self.allowBackgroundDismiss = allowBackgroundDismiss
        self.allowSwipeToDismiss = allowSwipeToDismiss
        self.enableHapticFeedback = enableHapticFeedback
        self.titleLineLimit = titleLineLimit
        self.messageLineLimit = messageLineLimit
        self.presentationAnimation = presentationAnimation
        self.dismissAnimation = dismissAnimation
        self.dragAnimation = dragAnimation
    }
    
    // MARK: - Presets
    
    public static let `default` = InAppMessageSwiftUICustomization()
    
    public static let minimal = InAppMessageSwiftUICustomization(
        backgroundColor: Color(.systemBackground),
        backgroundMaterial: .thin,
        cornerRadius: 8,
        contentPadding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        showDismissButton: false,
        allowBackgroundDismiss: false,
        enableHapticFeedback: false,
        shadowRadius: 8
    )
    
    public static let card = InAppMessageSwiftUICustomization(
        backgroundColor: Color(.systemBackground),
        backgroundMaterial: .regular,
        cornerRadius: 20,
        horizontalMargin: 16,
        contentPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        shadowRadius: 24,
        allowSwipeToDismiss: false
    )
    
    public static let compact = InAppMessageSwiftUICustomization(
        backgroundColor: Color(.systemBackground),
        backgroundMaterial: .ultraThin,
        cornerRadius: 12,
        horizontalMargin: 24,
        contentPadding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        contentSpacing: 12,
        actionButtonHeight: 40,
        actionsLayout: .vertical,
        shadowRadius: 12
    )
}

// MARK: - Supporting Types

/// Layout options for action buttons
public enum ActionsLayout {
    case horizontal
    case vertical
}

/// Custom button style for in-app message actions
private struct InAppMessageButtonStyle: ButtonStyle {
    let style: ActionStyle
    let customization: InAppMessageSwiftUICustomization
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

extension View {
    /// Presents an in-app message as an overlay
    public func inAppMessage(
        isPresented: Binding<Bool>,
        message: InAppMessage,
        customization: InAppMessageSwiftUICustomization = .default,
        onAction: ((MessageAction) -> Void)? = nil
    ) -> some View {
        overlay(
            Group {
                if isPresented.wrappedValue {
                    InAppMessageView(
                        message: message,
                        customization: customization,
                        onAction: onAction,
                        onDismiss: {
                            isPresented.wrappedValue = false
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1000)
                }
            }
        )
    }
}

// MARK: - Animation Extensions

extension Animation {
    var duration: Double {
        switch self {
        case .easeInOut(let duration), .easeIn(let duration), .easeOut(let duration), .linear(let duration):
            return duration
        default:
            return 0.35 // Default duration
        }
    }
}