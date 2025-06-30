import SwiftUI

struct TraceView: View {
    @State private var host: String = ""
    @State private var output: String = ""
    @State private var isTracing = false
    @State private var enableIPv6: Bool = false
    @State private var currentTask: Process?

    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Enter the network address to trace an internet route to.")
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("Enable IPv6", isOn: $enableIPv6)
                        .foregroundColor(.white)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    TextField("", text: $host)
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    Text("(ex. 10.0.2.1 or www.example.com)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
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
                        Button(isTracing ? "Stop" : "Trace") {
                            if isTracing {
                                stopTrace()
                            } else {
                                traceHost()
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

    func stopTrace() {
        currentTask?.terminate()
        isTracing = false
        output += "\n\n--- Trace stopped by user. ---\n"
    }
    
    func traceHost() {
        output = ""
        isTracing = true
        let task = Process()
        currentTask = task
        
        task.launchPath = "/usr/bin/env"
        task.arguments = [enableIPv6 ? "traceroute6" : "traceroute", host]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.isTracing = false
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
            output = "Failed to start trace: \(error)"
            isTracing = false
        }
    }
}

#if DEBUG
struct TraceView_Previews: PreviewProvider {
    static var previews: some View {
        TraceView()
    }
}
#endif 