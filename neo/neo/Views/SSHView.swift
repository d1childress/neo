import SwiftUI

struct SSHView: View {
    @State private var host: String = ""
    @State private var username: String = ""
    @State private var port: String = "22"
    @State private var output: String = ""
    @State private var isConnected = false
    @State private var currentTask: Process?
    @State private var commandInput: String = ""
    
    enum AuthMethod: String, CaseIterable, Identifiable {
        case password = "Password"
        case keyFile = "Key File"
        
        var id: String { self.rawValue }
    }
    
    @State private var selectedAuthMethod: AuthMethod = .password
    @State private var password: String = ""
    @State private var keyFilePath: String = ""
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 15) {
                Text("SSH Connection")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Connection details
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Host:")
                            .foregroundColor(.white)
                        TextField("hostname or IP", text: $host)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .disabled(isConnected)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username:")
                            .foregroundColor(.white)
                        TextField("username", text: $username)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .disabled(isConnected)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Port:")
                            .foregroundColor(.white)
                        TextField("22", text: $port)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .disabled(isConnected)
                            .frame(width: 80)
                    }
                }
                
                // Authentication method
                Picker("Authentication:", selection: $selectedAuthMethod) {
                    ForEach(AuthMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(isConnected)
                
                // Authentication details
                if selectedAuthMethod == .password {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password:")
                            .foregroundColor(.white)
                        SecureField("password", text: $password)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .disabled(isConnected)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key File Path:")
                            .foregroundColor(.white)
                        TextField("~/.ssh/id_rsa", text: $keyFilePath)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .disabled(isConnected)
                    }
                }
                
                // Terminal output and command input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Terminal:")
                            .foregroundColor(.white)
                        Spacer()
                        if isConnected {
                            Text("Connected")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            Text(output)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(8)
                        }
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 10) {
                            Button(isConnected ? "Disconnect" : "Connect") {
                                if isConnected {
                                    disconnectSSH()
                                } else {
                                    connectSSH()
                                }
                            }
                            .frame(width: 80)
                            .foregroundColor(.white)
                            
                            Button(action: copyToClipboard) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                    }
                    
                    // Command input (only shown when connected)
                    if isConnected {
                        HStack {
                            TextField("Enter command...", text: $commandInput)
                                .textFieldStyle(.plain)
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .onSubmit {
                                    sendCommand()
                                }
                            
                            Button("Send") {
                                sendCommand()
                            }
                            .foregroundColor(.white)
                        }
                    }
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
    
    func connectSSH() {
        output = ""
        
        // Validate input
        let sanitizedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedPort = port.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !sanitizedHost.isEmpty && !sanitizedUsername.isEmpty else {
            output = "Error: Host and username cannot be empty"
            return
        }
        
        guard Int(sanitizedPort) != nil else {
            output = "Error: Port must be a valid number"
            return
        }
        
        // Basic validation to prevent command injection
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_")
        guard sanitizedHost.rangeOfCharacter(from: allowedCharacters.inverted) == nil,
              sanitizedUsername.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            output = "Error: Host and username contain invalid characters"
            return
        }
        
        output += "Connecting to \(sanitizedUsername)@\(sanitizedHost):\(sanitizedPort)...\n"
        
        let task = Process()
        currentTask = task
        
        task.launchPath = "/usr/bin/ssh"
        
        var arguments = [String]()
        arguments.append("-p")
        arguments.append(sanitizedPort)
        arguments.append("-o")
        arguments.append("ConnectTimeout=10")
        arguments.append("-o")
        arguments.append("StrictHostKeyChecking=no")
        
        if selectedAuthMethod == .keyFile && !keyFilePath.isEmpty {
            arguments.append("-i")
            arguments.append(keyFilePath)
        }
        
        arguments.append("\(sanitizedUsername)@\(sanitizedHost)")
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.isConnected = false
                self.output += "\n\n--- SSH connection terminated ---\n"
            }
        }
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            if let str = String(data: handle.availableData, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.output += str
                    // Simple check for successful connection
                    if str.contains("$") || str.contains("#") || str.contains("Welcome") {
                        self.isConnected = true
                    }
                }
            }
        }
        
        do {
            try task.run()
            output += "SSH connection initiated...\n"
        } catch {
            output = "Failed to start SSH connection: \(error.localizedDescription)"
        }
    }
    
    func disconnectSSH() {
        currentTask?.terminate()
        isConnected = false
        output += "\n\n--- Disconnected by user ---\n"
    }
    
    func sendCommand() {
        guard !commandInput.isEmpty else { return }
        
        output += "\n$ \(commandInput)\n"
        
        // For demonstration purposes, we'll show the command being sent
        // In a real implementation, you'd need to properly handle stdin/stdout
        // with the SSH process, which is more complex
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "echo 'Command sent: \(commandInput)' && echo 'Note: Full SSH terminal interaction requires more complex implementation'"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
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
            output += "Error executing command: \(error.localizedDescription)\n"
        }
        
        commandInput = ""
    }
}

#if DEBUG
struct SSHView_Previews: PreviewProvider {
    static var previews: some View {
        SSHView()
    }
}
#endif