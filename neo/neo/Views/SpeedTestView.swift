import SwiftUI

struct SpeedTestView: View {
    @State private var output: String = ""
    @State private var isTesting = false
    
    enum TestType { case downlink, uplink, both }
    @State private var testType: TestType = .both
    @State private var showAdvancedDiagnostics: Bool = false
    @State private var runSequentially: Bool = true
    @State private var usePrivateRelay: Bool = false
    
    // Performance optimization: configure session for better performance
    private lazy var optimizedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.httpMaximumConnectionsPerHost = 1
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil // Disable caching for speed tests
        return URLSession(configuration: config, delegate: RelaxedURLSessionDelegate(), delegateQueue: nil)
    }()

    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Benchmark basic metrics of your internet connection.")
                            .foregroundColor(.white)
                        Toggle("Show advanced diagnostics data", isOn: $showAdvancedDiagnostics)
                            .foregroundColor(.white)
                        Toggle("Run test sequentially instead of parallel", isOn: $runSequentially)
                            .disabled(testType != .both)
                            .foregroundColor(.white)
                        Toggle("Use iCloud Private Relay", isOn: $usePrivateRelay)
                            .disabled(true)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Picker("", selection: $testType) {
                        Text("Downlink").tag(TestType.downlink)
                            .foregroundColor(.white)
                        Text("Uplink").tag(TestType.uplink)
                            .foregroundColor(.white)
                        Text("Both").tag(TestType.both)
                            .foregroundColor(.white)
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                    .horizontalRadioGroupLayout()
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
                        Button(isTesting ? "Stop" : "Speed Test") {
                            if isTesting {
                                stopTest()
                            } else {
                                startSpeedTest()
                            }
                        }
                        .frame(width: 80)
                        .foregroundColor(.white)
                    }
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
    
    @State private var testTask: Task<Void, Never>?
    
    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
    
    func stopTest() {
        testTask?.cancel()
        isTesting = false
        DispatchQueue.main.async {
            self.output += "\n\n--- Test stopped by user ---\n"
        }
    }
    
    func startSpeedTest() {
        output = ""
        isTesting = true
        
        let runDownload = testType == .downlink || testType == .both
        let runUpload = testType == .uplink || testType == .both

        testTask = Task {
            if runSequentially {
                if runDownload {
                    await runDownloadTest()
                }
                if runUpload && !Task.isCancelled {
                    await runUploadTest()
                }
            } else {
                async let downloadTask: Void? = runDownload ? runDownloadTest() : nil
                async let uploadTask: Void? = runUpload ? runUploadTest() : nil
                
                _ = await (downloadTask, uploadTask)
            }
            
            await MainActor.run {
                self.isTesting = false
            }
        }
    }
    
    @MainActor
    private func appendOutput(_ text: String) {
        output += text
    }
    
    func runDownloadTest() async {
        await appendOutput("Starting download test...\n")
        
        let startTime = Date()
        
        guard let downloadURL = URL(string: "https://openspeedtest.com/downloading") else {
            await appendOutput("Download Error: Invalid URL\n")
            return
        }
        
        var request = URLRequest(url: downloadURL)
        request.timeoutInterval = 60
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        do {
            let (tempURL, response) = try await optimizedSession.download(for: request)
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            guard !Task.isCancelled else { return }
            
            let data = try Data(contentsOf: tempURL)
            let mb = Double(data.count) / 1024.0 / 1024.0
            let speed = mb / duration
            
            await appendOutput(String(format: "Downloaded %.2f MB in %.2f seconds.\nSpeed: %.2f MB/s\n", mb, duration, speed))
            
            if showAdvancedDiagnostics, let httpResponse = response as? HTTPURLResponse {
                await appendOutput("\n--- Advanced Diagnostics ---\n")
                await appendOutput("Status Code: \(httpResponse.statusCode)\n")
                for (key, value) in httpResponse.allHeaderFields {
                    await appendOutput("\(key): \(value)\n")
                }
                await appendOutput("--------------------------\n")
            }
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            await appendOutput("Download Error: \(error.localizedDescription)\n")
        }
    }
    
    func runUploadTest() async {
        await appendOutput("\nStarting upload test...\n")
        
        guard let uploadURL = URL(string: "https://ptsv3.com/upload") else {
            await appendOutput("Upload Error: Invalid URL\n")
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // Performance optimization: Use streaming data instead of large memory allocation
        let uploadSize = 1 * 1024 * 1024 // 1MB
        let chunkSize = 64 * 1024 // 64KB chunks
        
        let startTime = Date()
        
        do {
            // Create a temporary file for streaming upload
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let fileHandle = try FileHandle(forWritingTo: tempURL)
            defer {
                try? fileHandle.close()
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            // Generate upload data in chunks to avoid large memory allocation
            var totalWritten = 0
            while totalWritten < uploadSize {
                let remainingBytes = uploadSize - totalWritten
                let currentChunkSize = min(chunkSize, remainingBytes)
                let chunk = Data(count: currentChunkSize)
                try fileHandle.write(contentsOf: chunk)
                totalWritten += currentChunkSize
            }
            
            try fileHandle.close()
            
            let uploadData = try Data(contentsOf: tempURL)
            let (_, response) = try await optimizedSession.upload(for: request, from: uploadData)
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            guard !Task.isCancelled else { return }
            
            let mb = Double(uploadData.count) / 1024.0 / 1024.0
            let speed = mb / duration
            await appendOutput(String(format: "Uploaded %.2f MB in %.2f seconds.\nSpeed: %.2f MB/s\n", mb, duration, speed))
            
            if showAdvancedDiagnostics, let httpResponse = response as? HTTPURLResponse {
                await appendOutput("\n--- Advanced Upload Diagnostics ---\n")
                await appendOutput("Status Code: \(httpResponse.statusCode)\n")
                for (key, value) in httpResponse.allHeaderFields {
                    await appendOutput("\(key): \(value)\n")
                }
                await appendOutput("--------------------------------\n")
            }
            
        } catch {
            await appendOutput("Upload Error: \(error.localizedDescription)\n")
        }
    }
}

#if DEBUG
struct SpeedTestView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedTestView()
    }
}
#endif 