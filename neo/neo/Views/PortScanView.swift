import SwiftUI
import Network

struct PortScanView: View {
    @State private var host: String = ""
    @State private var startPort: String = "1"
    @State private var endPort: String = "1024"
    @State private var output: String = ""
    @State private var isScanning = false
    @State private var verboseOutput = false
    @State private var limitPortRange = true
    @State private var scanProgress: Double = 0.0
    @State private var scannedPorts: Int = 0
    @State private var totalPorts: Int = 0
    
    // Performance optimization: limit concurrent connections
    private let maxConcurrentConnections = 50
    private let connectionTimeout: TimeInterval = 2.0
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("Enter an internet or IP address to scan for open ports.")
                    .foregroundColor(.white)
                TextField("e.g. 10.0.2.1 or www.example.com", text: $host)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                Toggle(isOn: $verboseOutput) {
                    Text("Verbose output")
                        .foregroundColor(.white)
                }
                .toggleStyle(CheckboxToggleStyle())
                Toggle(isOn: $limitPortRange) {
                    HStack(spacing: 4) {
                        Text("Only test ports between")
                            .foregroundColor(.white)
                        TextField("", text: $startPort)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .frame(width: 60)
                            .disabled(!limitPortRange)
                            .foregroundColor(.white)
                        Text("and")
                            .foregroundColor(.white)
                        TextField("", text: $endPort)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                            .frame(width: 60)
                            .disabled(!limitPortRange)
                            .foregroundColor(.white)
                        Text("(1-65535)")
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(CheckboxToggleStyle())
                
                // Progress indicator
                if isScanning {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Scanning progress: \(scannedPorts)/\(totalPorts)")
                                .foregroundColor(.white)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(scanProgress * 100))%")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        ProgressView(value: scanProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                HStack {
                    Spacer()
                    Button(action: isScanning ? stopScan : scanPorts) {
                        if isScanning {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Stop")
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text("Scan")
                                .foregroundColor(.white)
                        }
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
                    .background(Color(.black).opacity(0.7))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    Button(action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(self.output, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.white)
                    }
                    .padding(8)
                }
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
    
    @State private var scanTask: Task<Void, Never>?
    
    func stopScan() {
        scanTask?.cancel()
        isScanning = false
        DispatchQueue.main.async {
            self.output += "\n\n--- Scan stopped by user ---\n"
        }
    }
    
    func scanPorts() {
        output = ""
        isScanning = true
        scanProgress = 0.0
        scannedPorts = 0
        
        let start: Int
        let end: Int
        
        if limitPortRange {
            start = Int(startPort) ?? 1
            end = Int(endPort) ?? 1024
        } else {
            start = 1
            end = 65535
        }
        
        guard start > 0, end > 0, start <= end, end <= 65535 else {
            output = "Invalid port range."
            isScanning = false
            return
        }
        
        totalPorts = end - start + 1
        let ports = Array(start...end)
        
        DispatchQueue.main.async {
            self.output = "Starting scan of \(self.host) on ports \(start)-\(end)...\n\n"
        }
        
        scanTask = Task {
            await scanPortsOptimized(ports: ports)
        }
    }
    
    @MainActor
    private func scanPortsOptimized(ports: [Int]) async {
        var openPorts: [Int] = []
        
        // Process ports in chunks to limit concurrent connections
        let chunks = ports.chunked(into: maxConcurrentConnections)
        
        for chunk in chunks {
            guard !Task.isCancelled else { break }
            
            await withTaskGroup(of: (Int, Bool).self) { group in
                for port in chunk {
                    group.addTask {
                        let isOpen = await self.testPort(port: port)
                        return (port, isOpen)
                    }
                }
                
                for await (port, isOpen) in group {
                    scannedPorts += 1
                    scanProgress = Double(scannedPorts) / Double(totalPorts)
                    
                    if isOpen {
                        openPorts.append(port)
                        output += "Port \(port): Open\n"
                    } else if verboseOutput {
                        output += "Port \(port): Closed\n"
                    }
                }
            }
        }
        
        if !Task.isCancelled {
            var results = "\n--- Scan Complete ---\n"
            if openPorts.isEmpty {
                results += "No open ports found.\n"
            } else {
                results += "Found \(openPorts.count) open ports:\n"
                for port in openPorts.sorted() {
                    results += "\(port)\n"
                }
            }
            output += results
        }
        
        isScanning = false
    }
    
    private func testPort(port: Int) async -> Bool {
        return await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(self.host),
                port: NWEndpoint.Port(rawValue: UInt16(port))!,
                using: .tcp
            )
            
            var hasReturned = false
            
            // Set up timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + connectionTimeout) {
                if !hasReturned {
                    hasReturned = true
                    connection.cancel()
                    continuation.resume(returning: false)
                }
            }
            
            connection.stateUpdateHandler = { state in
                guard !hasReturned else { return }
                
                switch state {
                case .ready:
                    hasReturned = true
                    connection.cancel()
                    continuation.resume(returning: true)
                case .failed(_):
                    hasReturned = true
                    connection.cancel()
                    continuation.resume(returning: false)
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
        }
    }
}

// Helper extension for array chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#if DEBUG
struct PortScanView_Previews: PreviewProvider {
    static var previews: some View {
        PortScanView()
    }
}
#endif 
