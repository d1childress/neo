import SwiftUI

@main
struct NeoApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                VisualEffectView()
                TabView {
                    NetworkInfoView()
                        .tabItem {
                            Label("Info", systemImage: "info.circle")
                        }
                    NetstatView()
                        .tabItem {
                            Label("Netstat", systemImage: "network")
                        }
                    PingView()
                        .tabItem {
                            Label("Ping", systemImage: "waveform.path.ecg")
                        }
                    LookupView()
                        .tabItem {
                            Label("Lookup", systemImage: "magnifyingglass")
                        }
                    SpeedTestView()
                        .tabItem {
                            Label("Speed Test", systemImage: "speedometer")
                        }
                    TraceView()
                        .tabItem {
                            Label("Trace", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                        }
                    PortScanView()
                        .tabItem {
                            Label("Port Scan", systemImage: "rectangle.connected.to.line.below")
                        }
                    WhoisView()
                        .tabItem {
                            Label("Whois", systemImage: "person.text.rectangle")
                        }
                }
            }
            .frame(minWidth: 800, minHeight: 500)
            .preferredColorScheme(.dark)
            .font(.system(size: 14))
        }
    }
} 