import SwiftUI

// MARK: - Design Tokens
struct DesignTokens {
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.cyan
        static let accent = Color.green
        
        // Background colors
        static let background = Color(.controlBackgroundColor)
        static let surfacePrimary = Color(.windowBackgroundColor)
        static let surfaceSecondary = Color(.controlBackgroundColor)
        static let surfaceTertiary = Color(.separatorColor).opacity(0.1)
        
        // Text colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabelColor)
        static let textInverse = Color.white
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Interactive colors
        static let interactive = Color.accentColor
        static let interactiveHover = Color.accentColor.opacity(0.8)
        static let interactivePressed = Color.accentColor.opacity(0.6)
        static let interactiveDisabled = Color.gray.opacity(0.4)
    }
    
    // MARK: - Typography
    struct Typography {
        // Display text
        static let displayLarge = Font.system(size: 32, weight: .bold, design: .default)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
        static let displaySmall = Font.system(size: 24, weight: .bold, design: .default)
        
        // Headings
        static let headingLarge = Font.system(size: 20, weight: .semibold, design: .default)
        static let headingMedium = Font.system(size: 18, weight: .semibold, design: .default)
        static let headingSmall = Font.system(size: 16, weight: .semibold, design: .default)
        
        // Body text
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Labels and captions
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
        
        // Code and monospace
        static let codeLarge = Font.system(size: 14, weight: .regular, design: .monospaced)
        static let codeMedium = Font.system(size: 12, weight: .regular, design: .monospaced)
        static let codeSmall = Font.system(size: 10, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Border Radius
    struct BorderRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let xs = (color: Color.black.opacity(0.1), radius: CGFloat(1), x: CGFloat(0), y: CGFloat(1))
        static let sm = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let md = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let lg = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let xl = (color: Color.black.opacity(0.15), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(8))
    }
    
    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let bounce = SwiftUI.Animation.interpolatingSpring(stiffness: 300, damping: 15)
    }
}

// MARK: - Design Token Extensions
extension View {
    func withDesignTokens() -> some View {
        self.preferredColorScheme(.dark)
    }
    
    func cardStyle() -> some View {
        self
            .background(DesignTokens.Colors.surfaceSecondary)
            .cornerRadius(DesignTokens.BorderRadius.lg)
            .shadow(
                color: DesignTokens.Shadow.md.color,
                radius: DesignTokens.Shadow.md.radius,
                x: DesignTokens.Shadow.md.x,
                y: DesignTokens.Shadow.md.y
            )
    }
    
    func primaryButtonStyle() -> some View {
        self
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.interactive)
            .foregroundColor(DesignTokens.Colors.textInverse)
            .cornerRadius(DesignTokens.BorderRadius.sm)
            .font(DesignTokens.Typography.labelMedium)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.surfaceSecondary)
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.sm)
                    .stroke(DesignTokens.Colors.interactive, lineWidth: 1)
            )
            .cornerRadius(DesignTokens.BorderRadius.sm)
            .font(DesignTokens.Typography.labelMedium)
    }
}