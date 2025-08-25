import SwiftUI

struct LookupView: View {
    @State private var domain: String = ""
    @State private var output: String = ""
    @State private var isLookingUp = false
    
    enum Provider: String, CaseIterable {
        case dig = "Default (dig)"
        case nslookup = "Name Server Lookup (nslookup)"
        case dscache = "macOS Directory Service (dscacheutil)"
    }
    @State private var selectedProvider: Provider = .dig

    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 15) {
                Text("Enter an Internet address to lookup.")
                    .foregroundColor(.white)
                HStack(alignment: .firstTextBaseline) {
                    TextField("", text: $domain)
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    Text("(ex. 10.0.2.1 or www.example.com)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text("Please select an information provider")
                    .padding(.top, 10)
                    .foregroundColor(.white)
                Picker("", selection: $selectedProvider) {
                    ForEach(Provider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                HStack {
                    Spacer()
                    Button(action: lookupDomain) {
                        if isLookingUp {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Lookup")
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isLookingUp)
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
                    Button(action: copyToClipboard) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.white)
                    }
                    .padding(8)
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

    func lookupDomain() {
        output = ""
        isLookingUp = true
        
        // Input validation for domain
        let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDomain.isEmpty else {
            output = "Domain cannot be empty."
            isLookingUp = false
            return
        }
        
        // Basic input sanitization - allow alphanumeric characters, dots, hyphens, underscores, colons
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:")
        guard trimmedDomain.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            output = "Domain contains invalid characters."
            isLookingUp = false
            return
        }
        
        let task = Process()
        
        switch selectedProvider {
        case .dig:
            task.launchPath = "/usr/bin/dig"
            task.arguments = [trimmedDomain]
        case .nslookup:
            task.launchPath = "/usr/bin/nslookup"
            task.arguments = [trimmedDomain]
        case .dscache:
            task.launchPath = "/usr/bin/dscacheutil"
            task.arguments = ["-q", "host", "-a", "name", trimmedDomain]
        }
        
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
            output = "Failed to start lookup: \(error.localizedDescription)"
            isLookingUp = false
        }
    }
}

#if DEBUG
struct LookupView_Previews: PreviewProvider {
    static var previews: some View {
        LookupView()
    }
}
#endif 