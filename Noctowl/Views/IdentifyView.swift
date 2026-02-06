import SwiftUI
import Combine
import UIKit

public struct IdentifyView: View {

    public init() {}
    @Environment(\.colorScheme) private var scheme

    // MARK: - Slider State
    @State private var currentIndex: Int = 0
    @State private var previousIndex: Int = 0
    @State private var showGallerySheet: Bool = false
    @State private var showRecordingsSheet: Bool = false
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    // Placeholder images — replace with your assets (names should exist in Assets)
    private let heroImages: [String] = [
        "Crane", "Eagle", "HummingBird", "Oystercatcher"
    ]

    // Robust loader: supports Assets.xcassets entries OR loose files with extensions,
    // and tolerates case differences in filenames.
    private func loadUIImage(named base: String) -> UIImage? {
        // 1) Try standard asset / named lookup (no extension)
        if let img = UIImage(named: base) { return img }
        // 2) Try common file extensions
        let exts = ["png", "jpg", "jpeg", "heic", "heif", "webp"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: base, withExtension: ext),
               let img = UIImage(contentsOfFile: url.path) {
                return img
            }
        }
        // 3) Case-insensitive search through bundle for any match by basename
        let fm = FileManager.default
        if let resourcePath = Bundle.main.resourcePath,
           let enumerator = fm.enumerator(atPath: resourcePath) {
            for case let path as String in enumerator {
                let url = URL(fileURLWithPath: path)
                let nameNoExt = url.deletingPathExtension().lastPathComponent
                if nameNoExt.compare(base, options: .caseInsensitive) == .orderedSame,
                   let img = UIImage(contentsOfFile: Bundle.main.resourceURL!.appendingPathComponent(path).path) {
                    return img
                }
            }
        }
        return nil
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Fullscreen image slider (programmatic; rotates into view)
                GeometryReader { geo in
                    let imageHeight = max(0, geo.size.height - 180)
                    let libraryHeight = max(0, geo.size.height - imageHeight)
                    let totalHeight = imageHeight + libraryHeight
                    ZStack(alignment: .top) {
                        // Image layer pinned to top
                        ForEach(heroImages.indices, id: \.self) { idx in
                            if idx == currentIndex, let ui = loadUIImage(named: heroImages[idx]) {
                                ZStack(alignment: .bottom) {
                                    // Base image
                                    Image(uiImage: ui)
                                        .resizable()
                                        .renderingMode(.original)
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: imageHeight, alignment: .top)
                                        .scaleEffect(1.08, anchor: .top) // push content lower while keeping top pinned
                                        .clipped()

                                    // Bottom blur fade (masked)
                                    Image(uiImage: ui)
                                        .resizable()
                                        .renderingMode(.original)
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: imageHeight, alignment: .top)
                                        .scaleEffect(1.08, anchor: .top)
                                        .clipped()
                                        .blur(radius: 10)
                                        .mask(
                                            LinearGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: .clear, location: 0.0),
                                                    .init(color: .clear, location: 0.55),
                                                    .init(color: .black.opacity(0.8), location: 0.85),
                                                    .init(color: .black, location: 1.0)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                                .frame(width: geo.size.width, height: imageHeight, alignment: .top)
                                .clipped()
                                .id(idx)
                                .ignoresSafeArea(edges: .top)
                                .transition(.opacity)
                            }
                        }

                        // Overlay controls pinned near bottom of the image area
                        VStack {
                            Spacer()
                            VStack(spacing: 0) {
                                // Headline
                                HStack(alignment: .center, spacing: 8) {
                                    Image(systemName: "bird.circle")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 18, weight: .regular))
                                    Text("Identify a bird")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                                .padding(.bottom, 6)

                                // Bottom controls row (glass buttons)
                                HStack(spacing: 16) {
                                    GlassCapsuleButton(systemName: "mic.fill", title: "Record") {
                                        // TODO: hook up microphone recording action
                                    }
                                    GlassCircleButton(systemName: "camera.fill") {
                                        // TODO: hook up camera action
                                    }
                                }
                                .padding(.horizontal, 20)

                                // Page indicators under controls
                                HStack(spacing: 8) {
                                    ForEach(heroImages.indices, id: \.self) { i in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.8)) {
                                                previousIndex = currentIndex
                                                currentIndex = i
                                            }
                                        }) {
                                            Circle()
                                                .fill(i == currentIndex ? Color.white : Color.white.opacity(0.35))
                                                .frame(width: i == currentIndex ? 9 : 6, height: i == currentIndex ? 9 : 6)
                                        }
                                        .buttonStyle(.plain)
                                        .contentShape(Rectangle())
                                        .frame(width: 16, height: 16)
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .padding(.bottom, 20)
                        }
                        .frame(height: imageHeight, alignment: .bottom)
                        .allowsHitTesting(true)

                        // Library section below the image
                        VStack(alignment: .leading, spacing: 6) {
                            Spacer()
                                .frame(height: imageHeight + 1)

                            Text("Library")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                                .padding(.vertical, 0)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Button(action: { showGallerySheet = true }) {
                                        LibraryTile(title: "Gallery")
                                            .frame(width: 280, height: 170)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                    Button(action: { showRecordingsSheet = true }) {
                                        LibraryTile(title: "Recordings")
                                            .frame(width: 280, height: 170)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                            }
                            .frame(height: 200)
                            .scrollClipDisabled()
                        }
                        .frame(height: totalHeight, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(edges: .top)
                }
                .background(scheme == .dark ? Color.black : Color.white)

                .onReceive(timer) { _ in
                    withAnimation(.easeInOut(duration: 0.8)) {
                        previousIndex = currentIndex
                        currentIndex = (currentIndex + 1) % max(heroImages.count, 1)
                    }
                }

                // Overlay content
                VStack(spacing: 0) {
                    // Top bar (title aligned left, profile button right)
                    HStack(alignment: .center) {
                        Text("Identify")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ProfileButton { }
                            .environment(\.colorScheme, .dark)
                            .tint(.white)
                            .symbolRenderingMode(.monochrome)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .sheet(isPresented: $showGallerySheet) {
            GallerySheetView()
        }
        .sheet(isPresented: $showRecordingsSheet) {
            RecordingsSheetView()
        }
    }
}

// MARK: - Library Tile
private struct LibraryTile: View {
    let title: String

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        ZStack(alignment: .bottomLeading) {
            shape
                .fill(Color.clear)
                .background(.bar, in: shape)
                .glassEffect(in: shape)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(12)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}

// MARK: - Gallery Sheet
private struct GallerySheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFilterMenu: Bool = false
    @State private var selectedScope: GalleryScope = .all
    @Namespace private var filterMorph
    private let topButtonSize: CGFloat = 44
    private let topSymbolSize: CGFloat = 18

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(0..<30, id: \.self) { _ in
                            Rectangle()
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .aspectRatio(1, contentMode: .fill)
                        }
                    }
                    .padding(.horizontal, 2)

                    Spacer(minLength: 120)
                }
            }
        }
        .background(Color.black.opacity(0.02).ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gallery")
                        .font(.system(size: 34, weight: .bold))
                    Text(todayLabel)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85, blendDuration: 0.2)) {
                            showFilterMenu.toggle()
                        }
                    }) {
                        GlassCircleIcon(systemName: "line.3.horizontal.decrease", size: topSymbolSize, frame: topButtonSize)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .topTrailing) {
                        if showFilterMenu {
                            FilterMenu(selectedScope: $selectedScope)
                                .matchedGeometryEffect(id: "filterMenu", in: filterMorph)
                                .transition(.scale.combined(with: .opacity))
                                .offset(y: 54)
                                .zIndex(2)
                        }
                    }

                    Button(action: { dismiss() }) {
                        GlassCircleIcon(systemName: "xmark", size: topSymbolSize, frame: topButtonSize)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color.black.opacity(0.001)) // keeps taps from falling through
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                GlassCircleIcon(systemName: "photo.on.rectangle.angled", size: topSymbolSize, frame: topButtonSize)

                GalleryScopePicker(selected: $selectedScope)

                GlassCircleIcon(systemName: "magnifyingglass", size: topSymbolSize, frame: topButtonSize)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .presentationDetents([.fraction(1.0)])
        .presentationDragIndicator(.visible)
    }

    private var todayLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: Date())
    }
}

private enum GalleryScope: String, CaseIterable, Identifiable {
    case years = "Years"
    case months = "Months"
    case all = "All"
    var id: String { rawValue }
}

private struct GalleryScopePicker: View {
    @Binding var selected: GalleryScope

    var body: some View {
        let shape = Capsule(style: .continuous)
        HStack(spacing: 0) {
            ForEach(GalleryScope.allCases) { scope in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = scope
                    }
                }) {
                    Text(scope.rawValue)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(
            Rectangle()
                .fill(.clear)
                .background(.bar, in: shape)
                .glassEffect(.regular.tint(.clear).interactive(), in: shape)
        )
        .overlay(shape.stroke(Color.white.opacity(0.22), lineWidth: 0.6))
        .overlay(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 72, height: 34)
                .offset(x: indicatorOffset)
                .animation(.easeInOut(duration: 0.2), value: selected)
        )
        .frame(height: 44)
        .frame(maxWidth: 220)
    }

    private var indicatorOffset: CGFloat {
        switch selected {
        case .years: return -72
        case .months: return 0
        case .all: return 72
        }
    }
}

private struct FilterMenu: View {
    @Binding var selectedScope: GalleryScope

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(GalleryScope.allCases) { scope in
                Button(action: { selectedScope = scope }) {
                    HStack(spacing: 8) {
                        Text(scope.rawValue)
                            .font(.callout.weight(.semibold))
                        if selectedScope == scope {
                            Image(systemName: "checkmark")
                                .font(.footnote.weight(.bold))
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.bar)
                .glassEffect(.regular.tint(.clear).interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Recordings Sheet
private struct RecordingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showRecordSheet: Bool = false
    @State private var expandedID: UUID? = nil
    @State private var showSearch: Bool = false
    @State private var searchText: String = ""
    @FocusState private var searchFocused: Bool
    @State private var recordings: [RecordingItem] = [
        .init(title: "Forest Edge", date: "Mar 12, 2026", duration: "5:58"),
        .init(title: "Dawn Chorus", date: "Mar 10, 2026", duration: "0:57"),
        .init(title: "Wetland Loop", date: "Feb 28, 2026", duration: "0:28"),
        .init(title: "Canyon Pass", date: "Feb 21, 2026", duration: "0:25"),
        .init(title: "Night Walk", date: "Jan 30, 2026", duration: "15:12")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Text("Recordings")
                            .font(.system(size: 34, weight: .bold))
                        Spacer()
                        HStack(spacing: 10) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showSearch.toggle()
                                }
                                if showSearch {
                                    DispatchQueue.main.async { searchFocused = true }
                                } else {
                                    searchFocused = false
                                }
                            }) {
                                GlassCircleIcon(systemName: "magnifyingglass", size: 18, frame: 44)
                            }
                            .buttonStyle(.plain)
                            Button(action: { dismiss() }) {
                                GlassCircleIcon(systemName: "xmark", size: 18, frame: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    ForEach(recordings) { item in
                        Group {
                            if expandedID == item.id {
                                ExpandedRecordingRow(item: item, onDelete: {
                                    recordings.removeAll { $0.id == item.id }
                                    if expandedID == item.id { expandedID = nil }
                                })
                            } else {
                                CompactRecordingRow(item: item)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedID = (expandedID == item.id) ? nil : item.id
                            }
                        }
                        Divider()
                            .padding(.leading)
                    }

                    Spacer(minLength: 120)
                }
            }

            Button(action: { showRecordSheet = true }) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if showSearch {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search recordings", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($searchFocused)
                        .submitLabel(.search)
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.bar)
                        .glassEffect(.regular.tint(.clear).interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 70)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .presentationDetents([.fraction(1.0)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showRecordSheet) {
            RecordCaptureSheet()
                .presentationDetents([.fraction(0.25)])
        }
    }
}

private struct RecordingItem: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let duration: String
}

private struct ExpandedRecordingRow: View {
    let item: RecordingItem
    let onDelete: () -> Void
    @State private var showMenu: Bool = false
    @Namespace private var menuMorph

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 8) {
                        Text(item.date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "text.bubble")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: {
                    withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.85, blendDuration: 0.2)) {
                        showMenu.toggle()
                    }
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .topTrailing) {
                    if showMenu {
                        RecordingMenu()
                            .matchedGeometryEffect(id: "recordingMenu", in: menuMorph)
                            .transition(.scale.combined(with: .opacity))
                            .offset(y: 28)
                            .zIndex(2)
                    }
                }
            }

            Capsule()
                .fill(Color(.systemGray5))
                .frame(height: 6)
                .overlay(
                    Capsule()
                        .fill(Color(.systemGray2))
                        .frame(width: 80)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )

            HStack {
                Text("0:00")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("-\(item.duration)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Spacer()
                HStack(spacing: 28) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

private struct RecordingMenu: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            menuRow("Rename")
            menuRow("Share")
            menuRow("Favorite")
            menuRow("Copy")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.bar)
                .glassEffect(.regular.tint(.clear).interactive(), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        )
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    private func menuRow(_ title: String) -> some View {
        Button(action: {}) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private struct CompactRecordingRow: View {
    let item: RecordingItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(item.date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "text.bubble")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(item.duration)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

private struct RecordCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Record")
                .font(.title2.weight(.bold))
            Text("Voice recording will be connected later.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.fraction(0.25)])
    }
}
// MARK: - Local Glass Circle Icon (Gallery sheet buttons)
private struct GlassCircleIcon: View {
    @Environment(\.colorScheme) private var scheme
    let systemName: String
    let size: CGFloat
    let frame: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .background(.bar, in: Circle())
                .glassEffect(.regular.tint(.clear).interactive(), in: .circle)
                .contentShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(scheme == .dark ? Color.white : Color.black)
        }
        .frame(width: frame, height: frame)
        .compositingGroup()
    }
}

// MARK: - Glass Buttons
private struct GlassCapsuleButton: View {
    let systemName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                    .foregroundStyle(.tint)
                    .font(.system(size: 18, weight: .regular))
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .fixedSize()
        }
        .buttonStyle(.plain)
        .background(
            {
                let shape = Capsule(style: .continuous)
                return AnyView(
                    Rectangle()
                        .fill(.clear)
                        .background(.ultraThinMaterial, in: shape)
                        .glassEffect(.regular.tint(.clear).interactive(), in: shape)
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                )
            }()
        )
        .tint(.white)
    }
}

private struct GlassCircleButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundStyle(.tint)
                .font(.system(size: 18, weight: .regular))
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .background(
            {
                let shape = Circle()
                return AnyView(
                    Rectangle()
                        .fill(.clear)
                        .background(.ultraThinMaterial, in: shape)
                        .glassEffect(.regular.tint(.clear).interactive(), in: shape)
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                )
            }()
        )
        .tint(.white)
    }
}
