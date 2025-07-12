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

// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension NSBezierPath {
    convenience init(roundedRect rect: CGRect, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) {
        self.init()
        
        let topLeft = corners.contains(.topLeft) ? cornerRadii.width : 0
        let topRight = corners.contains(.topRight) ? cornerRadii.width : 0
        let bottomLeft = corners.contains(.bottomLeft) ? cornerRadii.width : 0
        let bottomRight = corners.contains(.bottomRight) ? cornerRadii.width : 0
        
        move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        line(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        if topRight > 0 {
            curve(to: CGPoint(x: rect.maxX, y: rect.minY + topRight),
                  controlPoint1: CGPoint(x: rect.maxX - topRight/2, y: rect.minY),
                  controlPoint2: CGPoint(x: rect.maxX, y: rect.minY + topRight/2))
        }
        line(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        if bottomRight > 0 {
            curve(to: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY),
                  controlPoint1: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight/2),
                  controlPoint2: CGPoint(x: rect.maxX - bottomRight/2, y: rect.maxY))
        }
        line(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        if bottomLeft > 0 {
            curve(to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft),
                  controlPoint1: CGPoint(x: rect.minX + bottomLeft/2, y: rect.maxY),
                  controlPoint2: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft/2))
        }
        line(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        if topLeft > 0 {
            curve(to: CGPoint(x: rect.minX + topLeft, y: rect.minY),
                  controlPoint1: CGPoint(x: rect.minX, y: rect.minY + topLeft/2),
                  controlPoint2: CGPoint(x: rect.minX + topLeft/2, y: rect.minY))
        }
        close()
    }
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        
        return path
    }
}

struct UIRectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = UIRectCorner(rawValue: 1 << 0)
    static let topRight = UIRectCorner(rawValue: 1 << 1)
    static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

#if DEBUG
struct SSHView_Previews: PreviewProvider {
    static var previews: some View {
        SSHView()
    }
}
#endif