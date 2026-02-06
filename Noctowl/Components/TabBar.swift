import SwiftUI

// MARK: - Tabs
enum Tabs: String {
    case community, map, identify, lifeList, search
}

// MARK: - TabBar
struct TabBar: View {
    // Backwards-compat so any old references to NavBar still compile
    // (typealias can be placed here since top-level).
    // Selection
    @State var selectedTab: Tabs = .identify
    
    // Search state
    @State private var searchString: String = ""
    @State private var isSearchPresented: Bool = false
    @Environment(\.dismissSearch) private var dismissSearch
    
    // Search origin tracking (which tab opened search)
    @State private var previousTab: Tabs = .community
    @State private var lastNonSearchTab: Tabs = .community
    @State private var searchOrigin: Tabs? = nil
    @State private var isSearchBusy: Bool = false
    @State private var isInChatView: Bool = false
    @State private var searchInstanceID = UUID()
    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = "light"
    @AppStorage("appAccent") private var appAccentRaw: String = "system"
    @State private var contactsInstanceID = UUID()
    @State private var showingSettings = false
    
var body: some View {
    GeometryReader { proxy in
                TabView(selection: $selectedTab) {
                    Tab("Identify", systemImage: "bird", value: .identify) {
                        IdentifyView()
                    }
                    
                    Tab("Map", systemImage: "map", value: .map) {
                        MapView()
                    }
                    
                    Tab("Community", systemImage: "globe", value: .community) {
                        CommunityView()
                    }
                    
                    Tab("Life List", systemImage: "list.bullet", value: .lifeList) {
                        LifeListView()
                            .id(contactsInstanceID)
                    }
                    
                    Tab(value: .search, role: .search) {
                        searchTabView()
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 3)
                        .onChanged { value in
                            guard !isInChatView else { return }
                            guard selectedTab != .search else { return } // don't auto-present search while sliding
                            let barHeight: CGFloat = 100
                            let y = value.location.y
                            if y >= proxy.size.height - barHeight {
                                let order: [Tabs] = [.community, .map, .identify, .lifeList, .search]
                                let segment = proxy.size.width / CGFloat(order.count)
                                let idx = max(0, min(order.count - 1, Int(value.location.x / max(1, segment))))
                                let hovered = order[idx]
                                if hovered != .search && hovered != selectedTab {
                                    withAnimation(nil) { selectedTab = hovered }
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: isInChatView ? 24 : 10_000)
                        .onChanged { value in
                            guard isInChatView else { return }
                            // Only engage for horizontal drags; taps and vertical scrolls pass through.
                            if abs(value.translation.width) > abs(value.translation.height) {
                                // no-op: existence of this gesture prevents TabView paging
                            }
                        }
                        .onEnded { _ in }
                )
                .preferredColorScheme(appColorSchemeRaw == "dark" ? .dark : .light)
                .tint(resolvedAccent())
                .toolbarBackground(
                    selectedTab == .search ? Color.black.opacity(0.08) : Color.clear,
                    for: .tabBar
                )
                .toolbarBackground(selectedTab == .search ? .visible : .automatic, for: .tabBar)
                .animation(nil, value: selectedTab)
                .animation(nil, value: showingSettings)
                .transaction { $0.animation = nil }
                // MARK: – Lifecycle/state wiring
                .onAppear {
                    withAnimation(nil) {}
                    lastNonSearchTab = selectedTab
                    previousTab = selectedTab
                    searchOrigin = nil
                }
                .onChange(of: selectedTab) { newValue in
                    // Capture the tab we are leaving before we mutate state
                    let leavingTab = previousTab
                    withAnimation(nil) {}
                    withAnimation(nil) { showingSettings = false }
                    // If we are leaving Life List, reset its instance so next visit is fresh
                    if leavingTab == .lifeList && newValue != .lifeList {
                        contactsInstanceID = UUID()
                    }
                    
                    if newValue == .search {
                        // Do not auto-present the search field; just remember where we came from
                        searchOrigin = leavingTab
                        isSearchPresented = false
                        searchInstanceID = UUID()
                        isSearchBusy = false
                    } else {
                        // Leaving Search: ensure the search field is not presented next time
                        isSearchPresented = false
                        // Track last non-search tab for prompts and future entries
                        lastNonSearchTab = newValue
                        // If we just left Search, clear the origin lock
                        if leavingTab == .search { searchOrigin = nil }
                    }
                    
                    // Update previous for next transition
                    previousTab = newValue
                }
                .onChange(of: isSearchPresented) { presented in
                    withAnimation(nil) {
                        if presented {
                            // Search is now visible; ensure origin is locked
                            if searchOrigin == nil { searchOrigin = previousTab }
                        }
                        // When search is dismissed, remain on the Search tab; no navigation
                        isSearchBusy = false
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ChatViewDidAppear"))) { _ in
                    isInChatView = true
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ChatViewDidDisappear"))) { _ in
                    isInChatView = false
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RequestSearchFocus"))) { _ in
                    if selectedTab == .search { isSearchPresented = true }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DismissSearchFocus"))) { _ in
                    if selectedTab == .search { isSearchPresented = false }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RequestPushSettings"))) { _ in
                    // If invoked from Search, jump back to last content tab first
                    if selectedTab == .search {
                        withAnimation(nil) { selectedTab = lastNonSearchTab }
                    }
                    showingSettings = true
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                        .navigationBarBackButtonHidden(true)
                        .toolbar(.hidden, for: .navigationBar)
                }
        } // end GeometryReader
    } // end body

    private func iconName(for tab: Tabs) -> String {
            switch tab {
            case .community: return "globe"
            case .map: return "map"
            case .identify: return "bird"
            case .lifeList: return "list.bullet"
            case .search: return "magnifyingglass"
            }
        }
        
        private func searchPrompt(for tab: Tabs) -> Text {
            switch tab {
            case .community: return Text("Search Community")
            case .map: return Text("Search Map")
            case .identify: return Text("Search Identify")
            case .lifeList: return Text("Search Life List")
            case .search: return Text("Search")
            }
        }
        
        @ViewBuilder
        private func searchContent(for tab: Tabs) -> some View {
            List {
                switch tab {
                case .community:
                    Section("Community") {
                        if searchString.isEmpty {
                            Label("Try trending posts", systemImage: "sparkles")
                            Label("Explore local sightings", systemImage: "binoculars")
                        } else {
                            Label("Results for \(searchString)", systemImage: "magnifyingglass")
                        }
                    }
                case .map:
                    Section("Map") {
                        if searchString.isEmpty {
                            Label("Nearby hotspots", systemImage: "mappin.and.ellipse")
                            Label("Recent pins", systemImage: "clock")
                        } else {
                            Label("Search locations: \(searchString)", systemImage: "map")
                        }
                    }
                case .identify:
                    Section("Identify") {
                        if searchString.isEmpty {
                            Label("Try a species name", systemImage: "leaf")
                            Label("Use camera from Identify tab", systemImage: "camera")
                        } else {
                            Label("Search species: \(searchString)", systemImage: "bird")
                        }
                    }
                case .lifeList:
                    Section("Life List") {
                        if searchString.isEmpty {
                            Label("Your most seen species", systemImage: "star")
                            Label("Recent additions", systemImage: "clock")
                        } else {
                            Label("Search life list: \(searchString)", systemImage: "list.bullet")
                        }
                    }
                case .search:
                    Section("All") {
                        if searchString.isEmpty {
                            Label("Type to search across the app", systemImage: "magnifyingglass")
                        } else {
                            Label("Results for \(searchString)", systemImage: "magnifyingglass")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        
        private func resolvedAccent() -> Color {
            switch appAccentRaw {
            case "green": return .green
            case "yellow": return .yellow
            case "orange": return .orange
            case "red": return .red
            case "pink": return .pink
            case "purple": return .purple
            case "indigo": return .indigo
            case "blue": return .blue
            default:
                return appColorSchemeRaw == "dark" ? .pink : .blue
            }
        }

        @ViewBuilder
        private func searchTabView() -> some View {
            NavigationStack {
                SearchView(origin: searchOrigin ?? lastNonSearchTab)
            }
            .id(searchInstanceID)
            .searchable(
                text: $searchString,
                isPresented: $isSearchPresented,
                prompt: searchPrompt(for: searchOrigin ?? lastNonSearchTab)
            )
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
}

typealias NavBar = TabBar

// Temporary local SearchView so TabBar compiles.
// Replace with your real SearchView implementation when ready.
private struct SearchView: View {
    let origin: Tabs

    var body: some View {
        VStack(spacing: 12) {
            Text("Search")
                .font(.title2).bold()
            Text("Opened from: \(originTitle(origin))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private func originTitle(_ tab: Tabs) -> String {
        switch tab {
        case .community: return "Community"
        case .map: return "Map"
        case .identify: return "Identify"
        case .lifeList: return "Life List"
        case .search: return "Search"
        }
    }
}

#Preview {
    TabBar()
}
