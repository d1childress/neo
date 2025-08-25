import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Button {
                withAnimation(DesignTokens.Animation.adaptiveFast) {
                    configuration.isOn.toggle()
                }
            } label: {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(
                        configuration.isOn 
                        ? DesignTokens.Colors.accent 
                        : DesignTokens.Colors.textSecondary
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(configuration.isOn ? 1.1 : 1.0)
            .animation(DesignTokens.Animation.adaptiveBounce, value: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(DesignTokens.Animation.adaptiveFast) {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - Enhanced Toggle Style with Better Visual Feedback
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        configuration.isOn 
                        ? DesignTokens.Colors.accent 
                        : DesignTokens.Colors.surfaceSecondary
                    )
                    .frame(width: 44, height: 24)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .offset(x: configuration.isOn ? 8 : -8)
            }
            .animation(DesignTokens.Animation.adaptiveFast, value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
} 