import SwiftUI
import Foundation

struct SSHView: View {
    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var useKeyAuth: Bool = true
    @State private var privateKeyPath: String = "~/.ssh/id_rsa"
    @State private var output: String = ""
    @State private var isConnected = false
    @State private var commandInput: String = ""
    @State private var currentTask: Process?
    @State private var inputPipe: Pipe?
    @State private var outputPipe: Pipe?
    @State private var showPasswordWarning = false
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 15) {
                // Connection Settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("SSH Connection Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Host:")
                                .foregroundColor(.gray)
                            TextField("hostname or IP", text: $host)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .disabled(isConnected)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading) {
                            Text("Port:")
                                .foregroundColor(.gray)
                            TextField("22", text: $port)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .disabled(isConnected)
                        }
                        .frame(width: 80)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Username:")
                                .foregroundColor(.gray)
                            TextField("username", text: $username)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .disabled(isConnected)
                        }
                        
                        Toggle("Use SSH Key", isOn: $useKeyAuth)
                            .foregroundColor(.white)
                            .disabled(isConnected)
                    }
                    
                    if !useKeyAuth {
                        VStack(alignment: .leading) {
                            Text("Password:")
                                .foregroundColor(.gray)
                            SecureField("password", text: $password)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .disabled(isConnected)
                            Text("Note: Password authentication requires manual entry in terminal")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Private Key Path:")
                                .foregroundColor(.gray)
                            TextField("~/.ssh/id_rsa", text: $privateKeyPath)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .disabled(isConnected)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
                
                // Terminal Output
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(output)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(8)
                                .id("bottom")
                                .onChange(of: output) { _ in
                                    withAnimation {
                                        proxy.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                        }
                        .frame(maxHeight: .infinity)
                        .background(Color.black)
                        .cornerRadius(8, corners: [.topLeft, .topRight])
                    }
                    
                    // Command Input
                    if isConnected {
                        HStack {
                            Text("$")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.leading, 8)
                            
                            TextField("Enter command...", text: $commandInput)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .onSubmit {
                                    sendCommand()
                                }
                            
                            Button("Send") {
                                sendCommand()
                            }
                            .foregroundColor(.white)
                            .padding(.trailing, 8)
                        }
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                    }
                }
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                
                // Action Buttons
                HStack {
                    Button(isConnected ? "Disconnect" : "Connect") {
                        if isConnected {
                            disconnect()
                        } else {
                            connect()
                        }
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Clear") {
                        output = ""
                    }
                    .foregroundColor(.white)
                    .disabled(output.isEmpty)
                    
                    Button(action: copyToClipboard) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.white)
                    }
                    .disabled(output.isEmpty)
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
    
    func sendCommand() {
        guard isConnected, !commandInput.isEmpty else { return }
        
        if let inputPipe = inputPipe {
            let command = commandInput + "\n"
            if let data = command.data(using: .utf8) {
                inputPipe.fileHandleForWriting.write(data)
                output += "$ \(commandInput)\n"
                commandInput = ""
            }
        }
    }
    
    func connect() {
        // Validate inputs
        guard !host.isEmpty, !username.isEmpty else {
            output = "Error: Host and username are required\n"
            return
        }
        
        // Sanitize inputs
        let sanitizedHost = sanitizeInput(host)
        let sanitizedUsername = sanitizeInput(username)
        let sanitizedPort = sanitizeInput(port)
        
        output = "Connecting to \(sanitizedUsername)@\(sanitizedHost):\(sanitizedPort)...\n"
        
        let task = Process()
        currentTask = task
        
        task.launchPath = "/usr/bin/ssh"
        
        var arguments = [String]()
        arguments.append("-p")
        arguments.append(sanitizedPort)
        arguments.append("-o")
        arguments.append("StrictHostKeyChecking=no")
        arguments.append("-o")
        arguments.append("UserKnownHostsFile=/dev/null")
        arguments.append("-o")
        arguments.append("LogLevel=ERROR")
        
        if useKeyAuth {
            let expandedPath = NSString(string: privateKeyPath).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                arguments.append("-i")
                arguments.append(expandedPath)
            } else {
                output += "Warning: SSH key not found at \(expandedPath)\n"
                output += "Falling back to password authentication...\n"
            }
        } else {
            output += "Note: You will need to enter your password in the terminal below.\n"
            output += "For automated connections, consider using SSH key authentication.\n\n"
        }
        
        // Add pseudo-TTY allocation for interactive session
        arguments.append("-t")
        arguments.append("\(sanitizedUsername)@\(sanitizedHost)")
        
        task.arguments = arguments
        
        inputPipe = Pipe()
        outputPipe = Pipe()
        let errorPipe = Pipe()
        
        task.standardInput = inputPipe
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        // Set up environment for better terminal compatibility
        var environment = ProcessInfo.processInfo.environment
        environment["TERM"] = "xterm-256color"
        environment["LANG"] = "en_US.UTF-8"
        task.environment = environment
        
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.isConnected = false
                self.output += "\n\nConnection closed.\n"
            }
        }
        
        outputPipe?.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.output += str
                    
                    // Auto-respond to password prompt if password is provided
                    if !self.useKeyAuth && !self.password.isEmpty && str.lowercased().contains("password:") {
                        if let inputPipe = self.inputPipe {
                            let passwordData = (self.password + "\n").data(using: .utf8)!
                            inputPipe.fileHandleForWriting.write(passwordData)
                            self.password = "" // Clear password after use
                        }
                    }
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.output += str
                }
            }
        }
        
        do {
            try task.run()
            isConnected = true
        } catch {
            output += "Failed to start SSH: \(error.localizedDescription)\n"
            isConnected = false
        }
    }
    
    func disconnect() {
        currentTask?.terminate()
        isConnected = false
    }
    
    func sanitizeInput(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove any shell metacharacters
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_@")
        return String(trimmed.unicodeScalars.filter { allowedCharacters.contains($0) })
    }
}

// Helper extension for rounded corners that works with SwiftUI on macOS
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(UnevenRoundedRectangle(
            topLeadingRadius: corners.contains(.topLeft) ? radius : 0,
            bottomLeadingRadius: corners.contains(.bottomLeft) ? radius : 0,
            bottomTrailingRadius: corners.contains(.bottomRight) ? radius : 0,
            topTrailingRadius: corners.contains(.topRight) ? radius : 0
        ))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

#if DEBUG
struct SSHView_Previews: PreviewProvider {
    static var previews: some View {
        SSHView()
    }
}
#endif