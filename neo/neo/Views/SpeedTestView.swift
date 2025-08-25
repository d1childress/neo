import SwiftUI

struct SpeedTestView: View {
    @State private var output: String = ""
    @State private var isTesting = false
    
    enum TestType { case downlink, uplink, both }
    @State private var testType: TestType = .both
    @State private var showAdvancedDiagnostics: Bool = false
    @State private var runSequentially: Bool = true
    @State private var usePrivateRelay: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            // Header section
            SectionHeader(
                "Internet Speed Test",
                subtitle: "Benchmark your internet connection performance"
            )
            
            // Configuration section
            Card {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                        // Settings section
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("Test Options")
                                .font(DesignTokens.Typography.labelMedium)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Toggle("Show advanced diagnostics", isOn: $showAdvancedDiagnostics)
                                    .font(DesignTokens.Typography.bodyMedium)
                                
                                Toggle("Run tests sequentially", isOn: $runSequentially)
                                    .disabled(testType != .both)
                                    .font(DesignTokens.Typography.bodyMedium)
                                
                                Toggle("Use iCloud Private Relay", isOn: $usePrivateRelay)
                                    .disabled(true)
                                    .font(DesignTokens.Typography.bodyMedium)
                                    .help("This feature is not yet available")
                            }
                        }
                        
                        Spacer()
                        
                        // Test type selection
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Test Type")
                                .font(DesignTokens.Typography.labelMedium)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Picker("Test Type", selection: $testType) {
                                Text("Download Only").tag(TestType.downlink)
                                Text("Upload Only").tag(TestType.uplink)
                                Text("Both Tests").tag(TestType.both)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 250)
                        }
                    }
                    
                    // Action button
                    HStack {
                        Button(isTesting ? "Stop Test" : "Start Speed Test") {
                            if isTesting {
                                isTesting = false
                            } else {
                                startSpeedTest()
                            }
                        }
                        .primaryButtonStyle()
                        
                        if isTesting {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Text("Running speed test...")
                                    .font(DesignTokens.Typography.bodySmall)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Output terminal
            OutputTerminal(
                content: output,
                isLoading: isTesting,
                copyAction: copyToClipboard,
                clearAction: output.isEmpty ? nil : { output = "" }
            )
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.Colors.background)
    }
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
    
    func startSpeedTest() {
        output = ""
        isTesting = true
        
        let runDownload = testType == .downlink || testType == .both
        let runUpload = testType == .uplink || testType == .both

        if runSequentially {
            if runDownload {
                runDownloadTest {
                    if runUpload {
                        self.runUploadTest { self.isTesting = false }
                    } else {
                        self.isTesting = false
                    }
                }
            } else if runUpload {
                runUploadTest { self.isTesting = false }
            }
        } else {
            let group = DispatchGroup()
            if runDownload {
                group.enter()
                runDownloadTest { group.leave() }
            }
            if runUpload {
                group.enter()
                runUploadTest { group.leave() }
            }
            group.notify(queue: .main) {
                self.isTesting = false
            }
        }
    }
    
    func runDownloadTest(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.output += "Starting download test...\n"
        }
        
        let startTime = Date()
        let delegate = RelaxedURLSessionDelegate()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        // Ensure session is properly cleaned up
        defer {
            session.invalidateAndCancel()
        }
        
        guard let downloadURL = URL(string: "https://openspeedtest.com/downloading") else {
            DispatchQueue.main.async {
                self.output += "Download Error: Invalid URL\n"
                completion?()
            }
            return
        }
        
        var request = URLRequest(url: downloadURL)
        request.timeoutInterval = 60
        
        let task = session.downloadTask(with: request) { tempURL, response, error in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                
                if let error = error {
                    self.output += "Download Error: \(error.localizedDescription)\n"
                } else if let tempURL = tempURL {
                    do {
                        let data = try Data(contentsOf: tempURL)
                        let mb = Double(data.count) / 1024.0 / 1024.0
                        let speed = mb / duration
                        self.output += String(
                            format: "Downloaded %.2f MB in %.2f seconds.\nSpeed: %.2f MB/s\n",
                            mb,
                            duration,
                            speed
                        )
                        
                        if self.showAdvancedDiagnostics, let httpResponse = response as? HTTPURLResponse {
                            self.output += "\n--- Advanced Diagnostics ---\n"
                            self.output += "Status Code: \(httpResponse.statusCode)\n"
                            httpResponse.allHeaderFields.forEach { self.output += "\($0): \($1)\n" }
                            self.output += "--------------------------\n"
                        }
                    } catch {
                        self.output += "Error reading downloaded file: \(error.localizedDescription)\n"
                    }
                }
                completion?()
            }
        }
        task.resume()
    }
    
    func runUploadTest(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.output += "\nStarting upload test...\n"
        }
        
        // Generate actual random data for the upload test (1MB)
        let dataSize = 1 * 1024 * 1024
        var uploadData = Data(capacity: dataSize)
        for _ in 0..<dataSize {
            uploadData.append(UInt8.random(in: 0...255))
        }
        
        let delegate = RelaxedURLSessionDelegate()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        // Ensure session is properly cleaned up
        defer {
            session.invalidateAndCancel()
        }
        
        guard let uploadURL = URL(string: "https://ptsv3.com/upload") else {
            DispatchQueue.main.async {
                self.output += "Upload Error: Invalid URL\n"
                completion?()
            }
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        
        let startTime = Date()
        let task = session.uploadTask(with: request, from: uploadData) { data, response, error in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                
                if let error = error {
                    self.output += "Upload Error: \(error.localizedDescription)\n"
                } else {
                    let mb = Double(uploadData.count) / 1024.0 / 1024.0
                    let speed = mb / duration
                    self.output += String(format: "Uploaded %.2f MB in %.2f seconds.\nSpeed: %.2f MB/s\n", mb, duration, speed)
                    
                    if self.showAdvancedDiagnostics, let httpResponse = response as? HTTPURLResponse {
                        self.output += "\n--- Advanced Upload Diagnostics ---\n"
                        self.output += "Status Code: \(httpResponse.statusCode)\n"
                        self.output += "-------------------------------\n"
                    }
                }
                completion?()
            }
        }
        task.resume()
    }
}

#if DEBUG
struct SpeedTestView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedTestView()
    }
}
#endif
