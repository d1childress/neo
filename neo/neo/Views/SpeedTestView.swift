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
                                isTesting = false
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
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        guard let downloadURL = URL(string: "https://openspeedtest.com/downloading") else {
            self.output += "Download Error: Invalid URL\n"
            completion?()
            return
        }
        
        var request = URLRequest(url: downloadURL)
        request.timeoutInterval = 60 // 60 seconds timeout
        
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
                        self.output += String(format: "Downloaded %.2f MB in %.2f seconds.\nSpeed: %.2f MB/s\n", mb, duration, speed)
                        
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
        
        // Generate a 1MB payload of random data for the upload test
        let uploadData = Data(count: 1 * 1024 * 1024)
        
        let delegate = RelaxedURLSessionDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        guard let uploadURL = URL(string: "https://ptsv3.com/upload") else {
            self.output += "Upload Error: Invalid URL\n"
            completion?()
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 60 // 60 seconds timeout
        
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