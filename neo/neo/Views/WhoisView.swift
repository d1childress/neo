import SwiftUI

struct WhoisView: View {
    @State private var domain: String = "google.com"
    @State private var output: String = ""
    @State private var isLookingUp = false
    
    @State private var selectedServer: String = "whois.iana.org"
    let whoisServers = ["Automatic", "whois.iana.org", "whois.verisign-grs.com", "whois.pir.org", "whois.nic.uk"]
    @State private var recursiveSearch: Bool = false

    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 15) {
                Text("Enter a domain address to look up its \"whois\" information.")
                    .foregroundColor(.white)
                HStack(alignment: .firstTextBaseline) {
                    TextField("google.com", text: $domain)
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    Text("(ex. 10.0.2.1 or www.example.com)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text("Please select a whois server to search")
                    .padding(.top, 10)
                    .foregroundColor(.white)
                Picker("", selection: $selectedServer) {
                    ForEach(whoisServers, id: \.self) { server in
                        Text(server).tag(server)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                HStack {
                    Spacer()
                    Toggle("Recursive search", isOn: $recursiveSearch)
                        .disabled(true)
                        .foregroundColor(.white)
                }
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
                    Button("Whois") {
                        whoisDomain()
                    }
                    .disabled(isLookingUp)
                    .frame(width: 80)
                    .foregroundColor(.white)
                    Button(action: copyToClipboard) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.white)
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

    func whoisDomain() {
        output = ""
        isLookingUp = true
        let task = Process()
        
        task.launchPath = "/usr/bin/whois"
        var arguments = [String]()
        if selectedServer != "Automatic" {
            arguments.append("-h")
            arguments.append(selectedServer)
        }
        arguments.append(domain)
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.isLookingUp = false
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
            output = "Failed to start whois: \(error.localizedDescription)"
            isLookingUp = false
        }
    }
}

#if DEBUG
struct WhoisView_Previews: PreviewProvider {
    static var previews: some View {
        WhoisView()
    }
}
#endif 