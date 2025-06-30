import SwiftUI

struct NetstatView: View {
    @State private var output: String = ""
    @State private var isFetching = false
    @State private var currentTask: Process?
    
    enum NetstatOption: String, CaseIterable, Identifiable {
        case routingTable = "Display routing table information"
        case allSockets = "Display the state of all sockets"
        case protocolStats = "Display statistics for all protocols"
        case multicastInfo = "Display multicast information"

        var id: String { self.rawValue }

        var command: (String, [String]) {
            switch self {
            case .routingTable:
                return ("/usr/sbin/netstat", ["-r"])
            case .allSockets:
                return ("/usr/sbin/netstat", ["-a"])
            case .protocolStats:
                return ("/usr/sbin/netstat", ["-s"])
            case .multicastInfo:
                return ("/usr/sbin/netstat", ["-g"])
            }
        }
    }

    @State private var selectedOption: NetstatOption = .routingTable

    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 15) {
                Picker("Select information to display:", selection: $selectedOption) {
                    ForEach(NetstatOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(MenuPickerStyle())
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
                        Button(isFetching ? "Stop" : "Run Netstat") {
                            if isFetching {
                                currentTask?.terminate()
                                isFetching = false
                            } else {
                                runNetstat()
                            }
                        }
                        .foregroundColor(.white)
                        Button(action: copyToClipboard) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
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

    func runNetstat() {
        output = ""
        isFetching = true
        let task = Process()
        currentTask = task
        
        let command = selectedOption.command
        task.launchPath = command.0
        task.arguments = command.1
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.isFetching = false
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
            output = "Failed to start netstat: \(error.localizedDescription)"
            isFetching = false
        }
    }
}

#if DEBUG
struct NetstatView_Previews: PreviewProvider {
    static var previews: some View {
        NetstatView()
    }
}
#endif 