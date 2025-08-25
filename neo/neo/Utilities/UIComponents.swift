import SwiftUI

// MARK: - Card Component
struct Card<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = DesignTokens.Spacing.md, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .cardStyle()
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        _ title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.headingSmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .secondaryButtonStyle()
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let label: String
    let value: String
    let isMonospace: Bool
    
    init(_ label: String, value: String, isMonospace: Bool = true) {
        self.label = label
        self.value = value
        self.isMonospace = isMonospace
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .frame(minWidth: 120, alignment: .leading)
            
            Text(value)
                .font(isMonospace ? DesignTokens.Typography.codeMedium : DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, DesignTokens.Spacing.xxs)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let status: Status
    
    enum Status {
        case active, inactive, success, warning, error, info
        
        var color: Color {
            switch self {
            case .active, .success: return DesignTokens.Colors.success
            case .inactive: return DesignTokens.Colors.textSecondary
            case .warning: return DesignTokens.Colors.warning
            case .error: return DesignTokens.Colors.error
            case .info: return DesignTokens.Colors.info
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xxs)
            .background(status.color)
            .cornerRadius(DesignTokens.BorderRadius.full)
    }
}

// MARK: - Enhanced Text Field
struct EnhancedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let helpText: String?
    let isValid: Bool
    let errorMessage: String?
    
    init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        helpText: String? = nil,
        isValid: Bool = true,
        errorMessage: String? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.helpText = helpText
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.surfaceSecondary)
                .cornerRadius(DesignTokens.BorderRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.sm)
                        .stroke(
                            isValid ? Color.clear : DesignTokens.Colors.error,
                            lineWidth: isValid ? 0 : 1
                        )
                )
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            if let helpText = helpText, isValid {
                Text(helpText)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
            
            if let errorMessage = errorMessage, !isValid {
                Text(errorMessage)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.error)
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    let showProgress: Bool
    let progress: Double?
    
    init(
        message: String = "Loading...",
        showProgress: Bool = false,
        progress: Double? = nil
    ) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if showProgress, let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
            }
            
            Text(message)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.xl)
        .cardStyle()
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.textTertiary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.headingMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(message)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .primaryButtonStyle()
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: 400)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(
        title: String = "Something went wrong",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.error)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.headingMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(message)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .primaryButtonStyle()
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .cardStyle()
    }
}

// MARK: - Output Terminal View
struct OutputTerminal: View {
    let content: String
    let isLoading: Bool
    let copyAction: (() -> Void)?
    let clearAction: (() -> Void)?
    
    init(
        content: String,
        isLoading: Bool = false,
        copyAction: (() -> Void)? = nil,
        clearAction: (() -> Void)? = nil
    ) {
        self.content = content
        self.isLoading = isLoading
        self.copyAction = copyAction
        self.clearAction = clearAction
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal header
            HStack {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Circle()
                        .fill(DesignTokens.Colors.error)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(DesignTokens.Colors.warning)
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(DesignTokens.Colors.success)
                        .frame(width: 12, height: 12)
                }
                
                Spacer()
                
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if let copyAction = copyAction {
                        Button(action: copyAction) {
                            Image(systemName: "doc.on.doc")
                                .font(DesignTokens.Typography.labelMedium)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .help("Copy to clipboard")
                    }
                    
                    if let clearAction = clearAction {
                        Button(action: clearAction) {
                            Image(systemName: "trash")
                                .font(DesignTokens.Typography.labelMedium)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .help("Clear output")
                    }
                }
            }
            .padding(DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.surfaceTertiary)
            
            // Terminal content
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 0) {
                        if content.isEmpty && !isLoading {
                            EmptyStateView(
                                icon: "terminal",
                                title: "No output yet",
                                message: "Command output will appear here"
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            Text(content)
                                .font(DesignTokens.Typography.codeMedium)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .id("bottom")
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Text("Running...")
                                    .font(DesignTokens.Typography.bodySmall)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                Spacer()
                            }
                            .padding(DesignTokens.Spacing.sm)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .onChange(of: content) {
                        withAnimation(DesignTokens.Animation.fast) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color.black.opacity(0.8))
        }
        .cornerRadius(DesignTokens.BorderRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                .stroke(DesignTokens.Colors.surfaceTertiary, lineWidth: 1)
        )
    }
}