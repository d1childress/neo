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
                HStack {
                    Spacer()
                    Button(action: scanPorts) {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Scan")
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isScanning)
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
    
    func scanPorts() {
        output = ""
        isScanning = true
        
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

        DispatchQueue.global(qos: .userInitiated).async {
            var openPorts: [Int] = []
            let group = DispatchGroup()
            for port in start...end {
                group.enter()
                let connection = NWConnection(host: NWEndpoint.Host(self.host), port: NWEndpoint.Port(rawValue: UInt16(port))!, using: .tcp)
                let startTime = Date()
                
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        _ = Date().timeIntervalSince(startTime)
                        DispatchQueue.main.async {
                            openPorts.append(port)
                        }
                        connection.cancel()
                        group.leave()
                    case .failed(_):
                        if verboseOutput {
                            DispatchQueue.main.async {
                                self.output += "Port \\(port): Closed\n"
                            }
                        }
                        connection.cancel()
                        group.leave()
                    default:
                        break
                    }
                }
                connection.start(queue: .global())
            }
            
            group.notify(queue: .main) {
                var results = ""
                if openPorts.isEmpty {
                    results = "No open ports found."
                } else {
                    results = "Open ports on \(self.host):\n"
                    for port in openPorts.sorted() {
                        results += "\(port)\n"
                    }
                }
                self.output = results
                self.isScanning = false
            }
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
