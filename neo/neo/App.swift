import SwiftUI

@main
struct NeoApp: App {
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                NavigationSidebarView()
                    .environmentObject(navigationManager)
            } detail: {
                NavigationDetailView()
                    .environmentObject(navigationManager)
            }
            .frame(minWidth: 1000, minHeight: 600)
            .withDesignTokens()
            .onAppear {
                setupKeyboardHandlers()
            }
        }
    }
    
    private func setupKeyboardHandlers() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let navigationManager = navigationManager as NavigationManager? else { return event }
            
            if event.modifierFlags.contains(.command) {
                switch event.keyCode {
                case 125: // Down arrow
                    navigationManager.selectNext()
                    return nil
                case 126: // Up arrow
                    navigationManager.selectPrevious()
                    return nil
                default:
                    break
                }
            }
            
            return event
        }
    }
}

// MARK: - Navigation Sidebar
struct NavigationSidebarView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var hoveredItem: NavigationItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Image(systemName: "network")
                        .font(DesignTokens.Typography.headingLarge)
                        .foregroundColor(DesignTokens.Colors.accent)
                    
                    Text("Neo")
                        .font(DesignTokens.Typography.headingLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                }
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    TextField("Search tools...", text: $navigationManager.searchText)
                        .textFieldStyle(.plain)
                        .font(DesignTokens.Typography.bodyMedium)
                }
                .padding(DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.surfaceSecondary)
                .cornerRadius(DesignTokens.BorderRadius.sm)
            }
            .padding(DesignTokens.Spacing.md)
            
            Divider()
                .foregroundColor(DesignTokens.Colors.surfaceTertiary)
            
            // Navigation items
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.xs, pinnedViews: [.sectionHeaders]) {
                    ForEach(NavigationCategory.allCases, id: \.self) { category in
                        if let items = navigationManager.groupedItems[category], !items.isEmpty {
                            Section {
                                ForEach(items) { item in
                                    NavigationItemRow(
                                        item: item,
                                        isSelected: navigationManager.selectedItem == item,
                                        isHovered: hoveredItem == item
                                    )
                                    .onTapGesture {
                                        withAnimation(DesignTokens.Animation.fast) {
                                            navigationManager.selectedItem = item
                                        }
                                    }
                                    .onHover { isHovered in
                                        withAnimation(DesignTokens.Animation.fast) {
                                            hoveredItem = isHovered ? item : nil
                                        }
                                    }
                                }
                            } header: {
                                if !items.isEmpty {
                                    HStack {
                                        Image(systemName: category.icon)
                                            .font(DesignTokens.Typography.labelSmall)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                        
                                        Text(category.rawValue)
                                            .font(DesignTokens.Typography.labelSmall)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                            .textCase(.uppercase)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, DesignTokens.Spacing.md)
                                    .padding(.vertical, DesignTokens.Spacing.sm)
                                    .background(DesignTokens.Colors.surfacePrimary)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
            }
            
            Spacer()
        }
        .frame(minWidth: 280, maxWidth: 350)
        .background(DesignTokens.Colors.surfacePrimary)
    }
}

// MARK: - Navigation Item Row
struct NavigationItemRow: View {
    let item: NavigationItem
    let isSelected: Bool
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: item.icon)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(isSelected ? DesignTokens.Colors.accent : DesignTokens.Colors.textSecondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(item.title)
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(isSelected ? DesignTokens.Colors.accent : DesignTokens.Colors.textPrimary)
                
                Text(item.description)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.sm)
                .fill(
                    isSelected ? DesignTokens.Colors.accent.opacity(0.1) :
                    isHovered ? DesignTokens.Colors.surfaceSecondary : Color.clear
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.sm)
                .stroke(
                    isSelected ? DesignTokens.Colors.accent.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, DesignTokens.Spacing.sm)
    }
}

// MARK: - Navigation Detail View
struct NavigationDetailView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        Group {
            if let selectedItem = navigationManager.selectedItem {
                selectedItem.view
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignTokens.Colors.background)
            } else {
                EmptyStateView(
                    icon: "network",
                    title: "Welcome to Neo",
                    message: "Select a network tool from the sidebar to get started",
                    actionTitle: "Get Started",
                    action: {
                        navigationManager.selectedItem = navigationManager.navigationItems.first
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignTokens.Colors.background)
            }
        }
        .navigationTitle(navigationManager.selectedItem?.title ?? "Neo")
    }
} 