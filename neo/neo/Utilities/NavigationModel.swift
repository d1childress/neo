import SwiftUI

// MARK: - Navigation Item
struct NavigationItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let view: AnyView
    let description: String
    let category: NavigationCategory
    
    init<V: View>(
        title: String,
        icon: String,
        description: String,
        category: NavigationCategory,
        @ViewBuilder view: () -> V
    ) {
        self.title = title
        self.icon = icon
        self.description = description
        self.category = category
        self.view = AnyView(view())
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Navigation Category
enum NavigationCategory: String, CaseIterable {
    case monitoring = "Monitoring"
    case diagnostics = "Diagnostics"
    case utilities = "Utilities"
    case connectivity = "Connectivity"
    
    var icon: String {
        switch self {
        case .monitoring: return "chart.line.uptrend.xyaxis"
        case .diagnostics: return "stethoscope"
        case .utilities: return "wrench.and.screwdriver"
        case .connectivity: return "network"
        }
    }
}

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    @Published var selectedItem: NavigationItem?
    @Published var searchText: String = ""
    
    let navigationItems: [NavigationItem] = [
        NavigationItem(
            title: "Network Info",
            icon: "info.circle",
            description: "View network interface information and statistics",
            category: .monitoring
        ) {
            NetworkInfoView()
        },
        NavigationItem(
            title: "Network Status",
            icon: "network",
            description: "Monitor active network connections",
            category: .monitoring
        ) {
            NetstatView()
        },
        NavigationItem(
            title: "Ping Test",
            icon: "waveform.path.ecg",
            description: "Test network connectivity to hosts",
            category: .diagnostics
        ) {
            PingView()
        },
        NavigationItem(
            title: "DNS Lookup",
            icon: "magnifyingglass",
            description: "Resolve domain names and IP addresses",
            category: .diagnostics
        ) {
            LookupView()
        },
        NavigationItem(
            title: "Speed Test",
            icon: "speedometer",
            description: "Test internet connection speed",
            category: .diagnostics
        ) {
            SpeedTestView()
        },
        NavigationItem(
            title: "Route Trace",
            icon: "point.topleft.down.curvedto.point.bottomright.up",
            description: "Trace network route to destination",
            category: .diagnostics
        ) {
            TraceView()
        },
        NavigationItem(
            title: "Port Scan",
            icon: "rectangle.connected.to.line.below",
            description: "Scan for open ports on hosts",
            category: .utilities
        ) {
            PortScanView()
        },
        NavigationItem(
            title: "WHOIS Lookup",
            icon: "person.text.rectangle",
            description: "Get domain and IP ownership information",
            category: .utilities
        ) {
            WhoisView()
        },
        NavigationItem(
            title: "SSH Client",
            icon: "terminal",
            description: "Connect to remote servers via SSH",
            category: .connectivity
        ) {
            SSHView()
        }
    ]
    
    var filteredItems: [NavigationItem] {
        if searchText.isEmpty {
            return navigationItems
        } else {
            return navigationItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var groupedItems: [NavigationCategory: [NavigationItem]] {
        Dictionary(grouping: filteredItems, by: { $0.category })
    }
    
    init() {
        selectedItem = navigationItems.first
    }
}

// MARK: - Keyboard Navigation Support
extension NavigationManager {
    func selectNext() {
        guard let current = selectedItem,
              let currentIndex = filteredItems.firstIndex(of: current) else {
            selectedItem = filteredItems.first
            return
        }
        
        let nextIndex = (currentIndex + 1) % filteredItems.count
        selectedItem = filteredItems[nextIndex]
    }
    
    func selectPrevious() {
        guard let current = selectedItem,
              let currentIndex = filteredItems.firstIndex(of: current) else {
            selectedItem = filteredItems.last
            return
        }
        
        let previousIndex = currentIndex == 0 ? filteredItems.count - 1 : currentIndex - 1
        selectedItem = filteredItems[previousIndex]
    }
}