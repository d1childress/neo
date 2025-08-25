import SwiftUI

// MARK: - Dynamic Type Extensions
extension DesignTokens.Typography {
    
    // Dynamic Type scale multipliers based on system font size
    private static var scaleMultiplier: CGFloat {
        #if os(macOS)
        // macOS doesn't have ContentSizeCategory like iOS, but we can provide basic scaling
        return 1.0  // For now, keep 1.0 scale on macOS
        #else
        return 1.0
        #endif
    }
    
    // Dynamic versions of typography that scale with system preferences
    struct Dynamic {
        static var displayLarge: Font {
            .system(size: 32 * scaleMultiplier, weight: .bold, design: .default)
        }
        
        static var displayMedium: Font {
            .system(size: 28 * scaleMultiplier, weight: .bold, design: .default)
        }
        
        static var displaySmall: Font {
            .system(size: 24 * scaleMultiplier, weight: .bold, design: .default)
        }
        
        static var headingLarge: Font {
            .system(size: 20 * scaleMultiplier, weight: .semibold, design: .default)
        }
        
        static var headingMedium: Font {
            .system(size: 18 * scaleMultiplier, weight: .semibold, design: .default)
        }
        
        static var headingSmall: Font {
            .system(size: 16 * scaleMultiplier, weight: .semibold, design: .default)
        }
        
        static var bodyLarge: Font {
            .system(size: 16 * scaleMultiplier, weight: .regular, design: .default)
        }
        
        static var bodyMedium: Font {
            .system(size: 14 * scaleMultiplier, weight: .regular, design: .default)
        }
        
        static var bodySmall: Font {
            .system(size: 12 * scaleMultiplier, weight: .regular, design: .default)
        }
        
        static var labelLarge: Font {
            .system(size: 14 * scaleMultiplier, weight: .medium, design: .default)
        }
        
        static var labelMedium: Font {
            .system(size: 12 * scaleMultiplier, weight: .medium, design: .default)
        }
        
        static var labelSmall: Font {
            .system(size: 10 * scaleMultiplier, weight: .medium, design: .default)
        }
        
        static var codeLarge: Font {
            .system(size: 14 * scaleMultiplier, weight: .regular, design: .monospaced)
        }
        
        static var codeMedium: Font {
            .system(size: 12 * scaleMultiplier, weight: .regular, design: .monospaced)
        }
        
        static var codeSmall: Font {
            .system(size: 10 * scaleMultiplier, weight: .regular, design: .monospaced)
        }
    }
}

// MARK: - Accessibility Support
extension View {
    /// Adds keyboard navigation support with custom focus handling
    func keyboardNavigable() -> some View {
        self
            .focusable()
    }
}

// MARK: - High Contrast Support
extension DesignTokens.Colors {
    struct HighContrast {
        static let textPrimary = Color.white
        static let textSecondary = Color(.controlAccentColor)
        static let background = Color.black
        static let surface = Color(.controlBackgroundColor)
        static let accent = Color(.controlAccentColor)
        static let success = Color.green.opacity(0.9)
        static let error = Color.red.opacity(0.9)
        static let warning = Color.orange.opacity(0.9)
    }
    
    static var isHighContrastEnabled: Bool {
        #if os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #else
        return false
        #endif
    }
    
    static var adaptiveTextPrimary: Color {
        isHighContrastEnabled ? HighContrast.textPrimary : textPrimary
    }
    
    static var adaptiveBackground: Color {
        isHighContrastEnabled ? HighContrast.background : background
    }
    
    static var adaptiveAccent: Color {
        isHighContrastEnabled ? HighContrast.accent : accent
    }
}

// MARK: - Motion Sensitivity Support
extension DesignTokens.Animation {
    static var isReduceMotionEnabled: Bool {
        #if os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #else
        return false
        #endif
    }
    
    static var adaptiveFast: SwiftUI.Animation {
        isReduceMotionEnabled ? SwiftUI.Animation.linear(duration: 0) : fast
    }
    
    static var adaptiveMedium: SwiftUI.Animation {
        isReduceMotionEnabled ? SwiftUI.Animation.linear(duration: 0) : medium
    }
    
    static var adaptiveSlow: SwiftUI.Animation {
        isReduceMotionEnabled ? SwiftUI.Animation.linear(duration: 0) : slow
    }
    
    static var adaptiveBounce: SwiftUI.Animation {
        isReduceMotionEnabled ? SwiftUI.Animation.linear(duration: 0) : bounce
    }
}