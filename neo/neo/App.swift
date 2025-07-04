import SwiftUI

@main
struct NeoApp: App {
    @State private var selectedTab = 0
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                VisualEffectView()
                TabView(selection: $selectedTab) {
                    Group {
                        if selectedTab == 0 {
                            NetworkInfoView()
                        } else {
                            Color.clear
                        }
                    }
                    .tabItem {
                        Label("Info", systemImage: "info.circle")
                    }
                    .tag(0)
                    
                    Group {
                        if selectedTab == 1 {
                            NetstatView()
                        } else {
                            Color.clear
                        }
                    }
                    .tabItem {
                        Label("Netstat", systemImage: "network")
                    }
                    .tag(1)
                    
                    Group {
                        if selectedTab == 2 {
                            PingView()
                        } else {
                            Color.clear
                        }
                    }
                    .tabItem {
                        Label("Ping", systemImage: "waveform.path.ecg")
                    }
                    .tag(2)
                    
                    Group {
                        if selectedTab == 3 {
                            LookupView()
                        } else {
                            Color.clear
                        }
                    }
                    .tabItem {
                        Label("Lookup", systemImage: "magnifyingglass")
                    }
                    .tag(3)
                    
                    Group {
                        if selectedTab == 4 {
                            SpeedTestView()
                        } else {
                            Color.clear
                        }
                    }
                    .tabItem {
                        Label("Speed Test", systemImage: "speedometer")
                    }
                    .tag(4)
                    
                    Group {
                        if selectedTab == 5 {
                            TraceView()
                        } else {
                            Color.clear
                        }
                    }
                    .tabItem {
                        Label("Trace", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    }
                    .tag(5)
                    
                    Group {
                        if selectedTab == 6 {
                            PortScanView()
                        } else {
                            Color.clear
                        }
                    }
                    .tabItem {
                        Label("Port Scan", systemImage: "rectangle.connected.to.line.below")
                    }
                    .tag(6)
                    
                    Group {
                        if selectedTab == 7 {
                            WhoisView()
                        } else {
                            Color.clear
                        }
                    }
                    .tabItem {
                        Label("Whois", systemImage: "person.text.rectangle")
                    }
                    .tag(7)
                }
            }
            .frame(minWidth: 800, minHeight: 500)
            .preferredColorScheme(.dark)
            .font(.system(size: 14))
        }
    }
} 