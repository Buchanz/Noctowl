import SwiftUI

struct LifeListView: View {
    private let items: [BirdEntry] = (1...10).map { i in
        BirdEntry(
            name: "Placeholder Species \(i)",
            location: "Sample Location | CA-BC",
            dateString: "October \(10 + (i % 20)), 2025"
        )
    }
    @State private var showSearch: Bool = false
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    @Namespace private var searchMorph
    @State private var lastScrollOffset: CGFloat = 0
    private let searchMorphAnimation = Animation.interactiveSpring(response: 0.25, dampingFraction: 0.85, blendDuration: 0.2)

    private var filteredItems: [BirdEntry] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter { entry in
            entry.name.lowercased().contains(q) ||
            entry.location.lowercased().contains(q) ||
            entry.dateString.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Text("Life List")
                        .font(.system(size: 32, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        ProfileButton(symbolName: "magnifyingglass", postsSettings: false) {
                            let newValue = !showSearch
                            withAnimation(searchMorphAnimation) {
                                showSearch = newValue
                            }
                            if newValue {
                                DispatchQueue.main.async { isSearchFocused = true }
                            } else {
                                isSearchFocused = false
                            }
                        }
                        .matchedGeometryEffect(id: "searchMorph", in: searchMorph)
                        ProfileButton { }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if showSearch {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.tint)
                        TextField("Search", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.primary)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        {
                            let shape = RoundedRectangle(cornerRadius: 999, style: .continuous)
                            return AnyView(
                                Rectangle()
                                    .fill(.clear)
                                    .background(.ultraThinMaterial, in: shape)
                                    .glassEffect(.regular.tint(.clear).interactive(), in: shape)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                        }()
                    )
                    .matchedGeometryEffect(id: "searchMorph", in: searchMorph)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Scrollable list of rows
                ScrollView {
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("LifeListScroll")).minY)
                    }
                    .frame(height: 0)
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems) { item in
                            LifeListRow(item: item)
                                .padding(.horizontal)

                            Divider()
                                .padding(.leading, 116) // offset so divider aligns under text, not the image
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .coordinateSpace(name: "LifeListScroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    let delta = value - lastScrollOffset
                    if showSearch && abs(delta) > 24 { collapseSearch() }
                    lastScrollOffset = value
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 6)
                        .onEnded { value in
                            if showSearch && abs(value.translation.height) > 30 { collapseSearch() }
                        }
                )
            }
            .onChange(of: showSearch) { val in
                if val {
                    DispatchQueue.main.async { isSearchFocused = true }
                }
            }
        }
    }

    private func collapseSearch() {
        withAnimation(searchMorphAnimation) {
            showSearch = false
        }
        isSearchFocused = false
    }
}

private struct BirdEntry: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let dateString: String
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct LifeListRow: View {
    let item: BirdEntry

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Square thumbnail on the left (placeholder)
            ZStack {
                let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
                Rectangle()
                    .fill(.clear)
                    .background(.bar, in: shape)
                    .glassEffect(.regular.tint(.clear).interactive(), in: shape)
                    .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
                Image(systemName: "photo")
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, height: 100) // square image
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)

            // Text content left-aligned beside the image
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(item.location)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(item.dateString)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 100, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }
}

private struct GlassIconButton: View {
    let systemName: String
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                action()
            }
        }) {
            Image(systemName: systemName)
                .imageScale(.medium)
                .foregroundStyle(scheme == .dark ? Color.white : Color.black)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .background(
            {
                let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
                return AnyView(
                    Rectangle()
                        .fill(.clear)
                        .background(.ultraThinMaterial, in: shape)
                        .glassEffect(.regular.tint(.clear).interactive(), in: shape)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
            }()
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .transition(.opacity.combined(with: .scale))
    }
}

struct LifeListView_Previews: PreviewProvider {
    static var previews: some View {
        LifeListView()
    }
}
