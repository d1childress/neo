import SwiftUI
import Network
import SystemConfiguration

struct NetworkInfoView: View {
    @State private var selectedInterface: String = "en0"
    @State private var availableInterfaces: [String] = []
    @State private var networkInfo: NetworkInterfaceInfo?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Select a network interface for information.")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Refresh") {
                        refreshNetworkInfo()
                    }
                    .foregroundColor(.white)
                }
                
                Picker("", selection: $selectedInterface) {
                    ForEach(availableInterfaces, id: \.self) { iface in
                        Text(getInterfaceDisplayName(iface))
                            .foregroundColor(.primary)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 300, alignment: .leading)
                .onChange(of: selectedInterface) { _, _ in
                    refreshNetworkInfo()
                }
                
                if isLoading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Loading network information...")
                            .foregroundColor(.white)
                    }
                } else {
                    HStack(alignment: .top, spacing: 40) {
                        // Interface Information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interface Information").font(.headline).foregroundColor(.white)
                            GroupBox {
                                VStack(alignment: .leading, spacing: 8) {
                                    if let info = networkInfo {
                                        Text("Interface: \(selectedInterface)")
                                        Text("Hardware Address: \(info.macAddress)")
                                        Text("IP Address: \(info.ipAddress)")
                                        Text("Subnet Mask: \(info.subnetMask)")
                                        Text("Status: \(info.status)")
                                        if !info.gateway.isEmpty {
                                            Text("Gateway: \(info.gateway)")
                                        }
                                        if !info.dnsServers.isEmpty {
                                            Text("DNS Servers: \(info.dnsServers.joined(separator: ", "))")
                                        }
                                    } else {
                                        Text("No information available")
                                    }
                                }
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color(.gray).opacity(0.2))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                        // Transfer Statistics
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transfer Statistics").font(.headline).foregroundColor(.white)
                            GroupBox {
                                VStack(alignment: .leading, spacing: 8) {
                                    if let info = networkInfo {
                                        Text("Bytes Sent: \(formatBytes(info.bytesSent))")
                                        Text("Bytes Received: \(formatBytes(info.bytesReceived))")
                                        Text("Packets Sent: \(info.packetsSent)")
                                        Text("Packets Received: \(info.packetsReceived)")
                                        Text("Send Errors: \(info.sendErrors)")
                                        Text("Receive Errors: \(info.receiveErrors)")
                                    } else {
                                        Text("No statistics available")
                                    }
                                }
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color(.gray).opacity(0.2))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.top, 10)
                }
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadAvailableInterfaces()
            refreshNetworkInfo()
        }
    }
    
    private func loadAvailableInterfaces() {
        availableInterfaces = getNetworkInterfaces()
        if !availableInterfaces.isEmpty && selectedInterface.isEmpty {
            selectedInterface = availableInterfaces.first ?? "en0"
        }
    }
    
    private func refreshNetworkInfo() {
        guard !selectedInterface.isEmpty else { return }
        isLoading = true
        
        Task {
            let info = await getNetworkInterfaceInfo(for: selectedInterface)
            await MainActor.run {
                self.networkInfo = info
                self.isLoading = false
            }
        }
    }
    
    private func getInterfaceDisplayName(_ interface: String) -> String {
        let commonNames: [String: String] = [
            "en0": "Wi-Fi",
            "en1": "Ethernet",
            "en2": "Thunderbolt",
            "en3": "USB Ethernet",
            "lo0": "Loopback"
        ]
        
        if let displayName = commonNames[interface] {
            return "\(displayName) (\(interface))"
        }
        return interface
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Network Interface Info
struct NetworkInterfaceInfo {
    let macAddress: String
    let ipAddress: String
    let subnetMask: String
    let status: String
    let gateway: String
    let dnsServers: [String]
    let bytesSent: UInt64
    let bytesReceived: UInt64
    let packetsSent: UInt64
    let packetsReceived: UInt64
    let sendErrors: UInt64
    let receiveErrors: UInt64
}

// MARK: - Network Interface Functions
func getNetworkInterfaces() -> [String] {
    var interfaces: [String] = []
    var ifaddrs: UnsafeMutablePointer<ifaddrs>?
    
    guard getifaddrs(&ifaddrs) == 0 else { return [] }
    defer { freeifaddrs(ifaddrs) }
    
    var ptr = ifaddrs
    while ptr != nil {
        let interface = ptr!.pointee
        let name = String(cString: interface.ifa_name)
        
        if !interfaces.contains(name) && !name.hasPrefix("utun") && !name.hasPrefix("awdl") {
            interfaces.append(name)
        }
        
        ptr = interface.ifa_next
    }
    
    return interfaces.sorted()
}

func getNetworkInterfaceInfo(for interfaceName: String) async -> NetworkInterfaceInfo? {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            var ifaddrs: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifaddrs) == 0 else {
                continuation.resume(returning: nil)
                return
            }
            defer { freeifaddrs(ifaddrs) }
            
            var macAddress = "N/A"
            var ipAddress = "N/A"
            var subnetMask = "N/A"
            var isUp = false
            
            var ptr = ifaddrs
            while ptr != nil {
                let interface = ptr!.pointee
                let name = String(cString: interface.ifa_name)
                
                if name == interfaceName {
                    // Check if interface is up
                    if (interface.ifa_flags & UInt32(IFF_UP)) != 0 {
                        isUp = true
                    }
                    
                    // Get IP address and subnet mask
                    if let addr = interface.ifa_addr {
                        let family = addr.pointee.sa_family
                        if family == UInt8(AF_INET) {
                            let addr4 = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                            ipAddress = String(cString: inet_ntoa(addr4.sin_addr))
                            
                            if let netmask = interface.ifa_netmask {
                                let mask4 = netmask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                                subnetMask = String(cString: inet_ntoa(mask4.sin_addr))
                            }
                        }
                    }
                }
                
                ptr = interface.ifa_next
            }
            
            // Get MAC address
            macAddress = getMACAddress(for: interfaceName) ?? "N/A"
            
            // Get statistics
            let stats = getInterfaceStatistics(for: interfaceName)
            
            // Get gateway and DNS
            let gateway = getDefaultGateway() ?? ""
            let dnsServers = getDNSServers()
            
            let info = NetworkInterfaceInfo(
                macAddress: macAddress,
                ipAddress: ipAddress,
                subnetMask: subnetMask,
                status: isUp ? "Active" : "Inactive",
                gateway: gateway,
                dnsServers: dnsServers,
                bytesSent: stats.bytesSent,
                bytesReceived: stats.bytesReceived,
                packetsSent: stats.packetsSent,
                packetsReceived: stats.packetsReceived,
                sendErrors: stats.sendErrors,
                receiveErrors: stats.receiveErrors
            )
            
            continuation.resume(returning: info)
        }
    }
}

func getMACAddress(for interfaceName: String) -> String? {
    let task = Process()
    task.launchPath = "/sbin/ifconfig"
    task.arguments = [interfaceName]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        // Parse MAC address from ifconfig output
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("ether") {
                let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
                if components.count >= 2 {
                    return components[1]
                }
            }
        }
    } catch {
        return nil
    }
    
    return nil
}

func getInterfaceStatistics(for interfaceName: String) -> (bytesSent: UInt64, bytesReceived: UInt64, packetsSent: UInt64, packetsReceived: UInt64, sendErrors: UInt64, receiveErrors: UInt64) {
    let task = Process()
    task.launchPath = "/usr/sbin/netstat"
    task.arguments = ["-I", interfaceName, "-b"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains(interfaceName) && !line.contains("Name") {
                let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if components.count >= 10 {
                    return (
                        bytesSent: UInt64(components[6]) ?? 0,
                        bytesReceived: UInt64(components[9]) ?? 0,
                        packetsSent: UInt64(components[4]) ?? 0,
                        packetsReceived: UInt64(components[7]) ?? 0,
                        sendErrors: UInt64(components[5]) ?? 0,
                        receiveErrors: UInt64(components[8]) ?? 0
                    )
                }
                break
            }
        }
    } catch {
        // Fallback to default values
    }
    
    return (0, 0, 0, 0, 0, 0)
}

func getDefaultGateway() -> String? {
    let task = Process()
    task.launchPath = "/usr/sbin/netstat"
    task.arguments = ["-rn", "-f", "inet"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("default") {
                let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if components.count >= 2 {
                    return components[1]
                }
            }
        }
    } catch {
        return nil
    }
    
    return nil
}

func getDNSServers() -> [String] {
    let task = Process()
    task.launchPath = "/usr/sbin/scutil"
    task.arguments = ["--dns"]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    var servers: [String] = []
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("nameserver[") {
                let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: " : ")
                if components.count == 2 {
                    servers.append(components[1])
                }
            }
        }
    } catch {
        return []
    }
    
    return Array(Set(servers)) // Remove duplicates
}

#if DEBUG
struct NetworkInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkInfoView()
    }
}
#endif 