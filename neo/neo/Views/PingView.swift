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
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Enter the network address to ping.")
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("Enable IPv6", isOn: $enableIPv6)
                        .foregroundColor(.white)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    TextField("google.com", text: $host)
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    Text("(ex. 10.0.2.1 or www.example.com)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Picker("", selection: $pingCountOption) {
                    Text("Send an unlimited number of pings").tag(PingCountOption.unlimited)
                        .foregroundColor(.white)
                    HStack {
                        Text("Send only")
                            .foregroundColor(.white)
                        TextField("", text: $pingCountText)
                            .frame(width: 40)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                        Text("pings")
                            .foregroundColor(.white)
                    }.tag(PingCountOption.limited)
                }
                .pickerStyle(RadioGroupPickerStyle())

                HStack(alignment: .bottom) {
                    ScrollView {
                        Text(output)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }

                    VStack(spacing: 10) {
                        Button(isPinging ? "Stop" : "Ping") {
                            if isPinging {
                                stopPing()
                            } else {
                                pingHost()
                            }
                        }
                        .frame(width: 80)
                        .foregroundColor(.white)
                        
                        Button(action: copyToClipboard) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
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