import SwiftUI

struct PingView: View {
    @State private var host: String = "google.com"
    @State private var output: String = ""
    @State private var isPinging = false
    
    enum PingCountOption {
        case unlimited, limited
    }
    @State private var pingCountOption: PingCountOption = .limited
    @State private var pingCountText: String = "10"
    @State private var enableIPv6: Bool = false
    @State private var currentTask: Process?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Header section
            SectionHeader(
                "Ping Test",
                subtitle: "Test network connectivity to hosts and measure latency"
            )
            
            // Configuration section
            VStack(spacing: DesignTokens.Spacing.md) {
                Card {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                                EnhancedTextField(
                                    "Target Host",
                                    text: $host,
                                    placeholder: "google.com",
                                    helpText: "Enter an IP address or domain name (e.g., 8.8.8.8 or www.google.com)",
                                    isValid: validateHost(host),
                                    errorMessage: validateHost(host) ? nil : "Invalid host format"
                                )
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.sm) {
                                Toggle("Enable IPv6", isOn: $enableIPv6)
                                    .font(DesignTokens.Typography.bodyMedium)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Ping Count")
                                .font(DesignTokens.Typography.labelMedium)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Picker("Ping Count", selection: $pingCountOption) {
                                Text("Send unlimited pings").tag(PingCountOption.unlimited)
                                HStack {
                                    Text("Send only")
                                    TextField("Count", text: $pingCountText)
                                        .frame(width: 60)
                                        .textFieldStyle(.roundedBorder)
                                    Text("pings")
                                }.tag(PingCountOption.limited)
                            }
                            .pickerStyle(RadioGroupPickerStyle())
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button(isPinging ? "Stop Ping" : "Start Ping") {
                        if isPinging {
                            stopPing()
                        } else {
                            pingHost()
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(!validateHost(host))
                    
                    if !output.isEmpty && !isPinging {
                        Button("Clear Output") {
                            output = ""
                        }
                        .secondaryButtonStyle()
                    }
                    
                    Spacer()
                    
                    if isPinging {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                            Text("Pinging...")
                                .font(DesignTokens.Typography.bodySmall)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                }
            }
            
            // Output terminal
            OutputTerminal(
                content: output,
                isLoading: isPinging,
                copyAction: copyToClipboard,
                clearAction: output.isEmpty ? nil : { output = "" }
            )
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.Colors.background)
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
    
    private func validateHost(_ host: String) -> Bool {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty else { return false }
        guard trimmedHost.count <= 253 else { return false }
        
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:")
        return trimmedHost.rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }

    func stopPing() {
        currentTask?.terminate()
        isPinging = false
        output += "\n\n--- Ping stopped by user. ---\n"
    }
    
    func pingHost() {
        output = ""
        
        // Validate and sanitize host input to prevent command injection
        let sanitizedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedHost.isEmpty else {
            output = "Error: Host cannot be empty"
            return
        }
        
        // Basic validation to prevent command injection
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:")
        guard sanitizedHost.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            output = "Error: Host contains invalid characters. Only alphanumeric characters, dots, hyphens, underscores, and colons are allowed."
            return
        }
        
        // Additional length check
        guard sanitizedHost.count <= 253 else { // RFC 1035 limit for domain names
            output = "Error: Host name is too long (max 253 characters)"
            return
        }
        
        isPinging = true
        let task = Process()
        currentTask = task
        
        task.launchPath = enableIPv6 ? "/sbin/ping6" : "/sbin/ping"
        
        var arguments = [String]()
        if pingCountOption == .limited {
            arguments.append("-c")
            arguments.append(pingCountText)
        }
        arguments.append(sanitizedHost)
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.isPinging = false
            }
        }
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            if let str = String(data: handle.availableData, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.output += str
                }
            }
        }
        
        do {
            try task.run()
        } catch {
            output = "Failed to start ping: \(error.localizedDescription)"
            isPinging = false
        }
    }
}

#if DEBUG
struct PingView_Previews: PreviewProvider {
    static var previews: some View {
        PingView()
    }
}
#endif 