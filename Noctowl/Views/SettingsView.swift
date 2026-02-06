import SwiftUI
import PhotosUI
import UIKit

// MARK: - Theme Sheet Helpers
private struct ThemeGlassGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal)
        .background(
            shape.fill(Color.clear)
                .background(.bar, in: shape)
                .glassEffect(in: shape)
        )
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Per-user persistence key namespacing
private func settings_currentUserNamespace() -> String {
    let uid = "anonymous"
    let trimmed = uid.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "anonymous" : trimmed
}

private func settings_nsKey(_ raw: String) -> String {
    "\(settings_currentUserNamespace())::\(raw)"
}

// MARK: - Notifications used across Settings
extension Notification.Name {
    static let ProfileDidChange = Notification.Name("ProfileDidChange")
}

// MARK: - Profile Icon Color (shared palette & helpers)
private struct ProjectSwatch: Identifiable, Equatable {
    let id: String
    let color: UIColor
}

private let kProjectSwatches: [ProjectSwatch] = [
    .init(id: "red", color: .systemRed),
    .init(id: "orange", color: .systemOrange),
    .init(id: "yellow", color: .systemYellow),
    .init(id: "green", color: .systemGreen),
    .init(id: "lightBlue", color: UIColor(red: 0.57, green: 0.76, blue: 1.00, alpha: 1.0)),
    .init(id: "blue", color: .systemBlue),
    .init(id: "indigo", color: .systemIndigo),
    .init(id: "pink", color: .systemPink),
    .init(id: "purple", color: .systemPurple),
    .init(id: "sand", color: UIColor(hue: 0.11, saturation: 0.28, brightness: 0.82, alpha: 1.0)),
    .init(id: "slate", color: .systemGray),
    .init(id: "peach", color: UIColor(red: 1.00, green: 0.76, blue: 0.76, alpha: 1.0))
]

private func swatch(for id: String) -> ProjectSwatch? {
    kProjectSwatches.first(where: { $0.id == id })
}

private func gradientForSwatchID(_ id: String) -> LinearGradient? {
    guard let s = swatch(for: id) else { return nil }
    let ui = s.color
    var hue: CGFloat = 0
    var sat: CGFloat = 0
    var bri: CGFloat = 0
    var alpha: CGFloat = 0
    ui.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
    let light = UIColor(hue: hue, saturation: max(sat * 0.55, 0.15), brightness: 1.0, alpha: 1.0)
    let dark = UIColor(hue: hue, saturation: min(sat * 1.05, 1.0), brightness: max(bri * 0.68, 0.38), alpha: 1.0)
    return LinearGradient(
        gradient: Gradient(colors: [Color(light), Color(dark)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private func colorForSwatchID(_ id: String) -> Color? {
    guard let s = swatch(for: id) else { return nil }
    return Color(s.color)
}

private var kProfileIconSwatchPrimaryKey: String { settings_nsKey("ProfileIconSwatchIDV1") }
private let kProfileIconSwatchFallbackKeys = ["ProfileIconColorIDV1", "ProfileIconSwatchID", "ProfileIconColorID"]

private func profileIcon_loadColorID() -> String? {
    if let s = UserDefaults.standard.string(forKey: kProfileIconSwatchPrimaryKey),
       !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return s
    }

    for key in kProfileIconSwatchFallbackKeys {
        if let s = UserDefaults.standard.string(forKey: settings_nsKey(key)),
           !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
        if let s = UserDefaults.standard.string(forKey: key),
           !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
    }
    return nil
}

private func profileIcon_saveColorID(_ id: String?) {
    if let id, !id.isEmpty {
        UserDefaults.standard.set(id, forKey: kProfileIconSwatchPrimaryKey)
    } else {
        UserDefaults.standard.removeObject(forKey: kProfileIconSwatchPrimaryKey)
    }
    NotificationCenter.default.post(name: .ProfileDidChange, object: nil)
}

private let defaultProfileColor = Color(.systemGray3)

private func settings_initials(from name: String) -> String? {
    let parts = name
        .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        .map { String($0) }
    let first = parts.first?.first
    let second = (parts.dropFirst().first?.first)
    let chars = [first, second].compactMap { $0 }
    guard !chars.isEmpty else { return nil }
    return String(chars).uppercased()
}

private let settingsProfileImageKeys = ["ProfileImageJPEGV1", "ProfileImageJPEG", "ProfileImagePNG", "ProfileImageDataV1", "ProfileImage"]
private let settingsProfileNameKeys = ["ProfileDisplayNameV1"]
private let settingsProfileEmailKeys = ["ProfileEmailV1"]

private func settings_loadProfileImage() -> UIImage? {
    for key in settingsProfileImageKeys {
        if let data = UserDefaults.standard.data(forKey: settings_nsKey(key)),
           let ui = UIImage(data: data) {
            return ui
        }
        if let data = UserDefaults.standard.data(forKey: key),
           let ui = UIImage(data: data) {
            return ui
        }
    }
    return nil
}

private func settings_loadProfileName() -> String? {
    for key in settingsProfileNameKeys {
        if let s = UserDefaults.standard.string(forKey: settings_nsKey(key)) {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        if let s = UserDefaults.standard.string(forKey: key) {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
    }
    return nil
}

private func settings_loadProfileEmail() -> String? {
    for key in settingsProfileEmailKeys {
        if let s = UserDefaults.standard.string(forKey: settings_nsKey(key)) {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        if let s = UserDefaults.standard.string(forKey: key) {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
    }
    return nil
}

// MARK: - Helpers
private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
}

private struct GlassGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal)
        .background(
            shape.fill(Color.clear)
                .background(.bar, in: shape)
                .glassEffect(in: shape)
        )
        .overlay(shape.stroke(Color.white.opacity(0.18), lineWidth: 0.75).blendMode(.plusLighter))
        .overlay(shape.strokeBorder(Color.black.opacity(0.08), lineWidth: 0.75))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}

private struct SettingsAvatarView: View {
    let size: CGFloat

    var body: some View {
        let gradient: LinearGradient? = {
            if let id = profileIcon_loadColorID() { return gradientForSwatchID(id) }
            return nil
        }()

        ZStack {
            Group {
                if let grad = gradient {
                    Circle().fill(grad)
                } else {
                    Circle().fill(defaultProfileColor)
                }
            }
            .frame(width: size, height: size)

            if let ui = settings_loadProfileImage() {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let name = settings_loadProfileName(),
                      let initials = settings_initials(from: name), !initials.isEmpty {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size, alignment: .center)
            } else {
                Image(systemName: "person")
                    .font(.system(size: size * 0.52, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: size, height: size, alignment: .center)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}

private struct GlassCircleIcon: View {
    @Environment(\.colorScheme) private var scheme
    let systemName: String
    let size: CGFloat
    let frame: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
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

private enum AppearanceOption: String, CaseIterable {
    case light, dark
}

private enum ThemeAccent: String, CaseIterable {
    case green, yellow, orange, red, pink, purple, indigo, blue
}

private func languageName(for identifier: String) -> String {
    let current = Locale.current
    if let code = Locale(identifier: identifier).languageCode {
        return current.localizedString(forLanguageCode: code)?.capitalized(with: current) ?? identifier
    }
    return identifier
}

private var currentLanguageLabel: String {
    let id = Bundle.main.preferredLocalizations.first ?? Locale.preferredLanguages.first ?? "en"
    return "System (\(languageName(for: id)))"
}

struct SettingsView: View {
    @State private var animateIn: Bool = false
    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = "light"
    @AppStorage("appAccent") private var appAccentRaw: String = "system"
    @State private var showThemeSheet: Bool = false
    @State private var tempTheme: ThemeAccent = .blue
    @State private var showLogoutAlert: Bool = false
    @State private var notificationsEnabled: Bool = false
    @State private var showEditProfileSheet: Bool = false
    @State private var showSubscriptionSheet: Bool = false
    @State private var profileVersion: Int = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private var appearance: AppearanceOption {
        AppearanceOption(rawValue: appColorSchemeRaw) ?? .light
    }

    private var accentColor: Color {
        if let t = ThemeAccent(rawValue: appAccentRaw) { return color(for: t) }
        return appearance == .dark ? .pink : .blue
    }

    private var settingsBackgroundColor: Color {
        appearance == .dark ? Color(.systemBackground) : Color.white
    }

    private var profileDisplayName: String {
        (settings_loadProfileName() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var profileEmail: String {
        (settings_loadProfileEmail() ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func color(for t: ThemeAccent) -> Color {
        switch t {
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .purple: return .purple
        case .indigo: return .indigo
        case .blue: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Top header row: centered profile
                    VStack(spacing: 12) {
                        HStack {
                            Spacer(minLength: 0)
                            SettingsAvatarView(size: 96).id(profileVersion)
                            Spacer(minLength: 0)
                        }

                        if !profileDisplayName.isEmpty {
                            Text(profileDisplayName)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        if !profileEmail.isEmpty {
                            Text(profileEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        HStack {
                            Spacer(minLength: 0)
                            Button(action: { showEditProfileSheet = true }) {
                                Text("Edit Profile")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .background(.bar, in: Capsule())
                            .glassEffect(.regular.tint(.clear).interactive(), in: Capsule())
                            .contentShape(Capsule())
                            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.top, 0)

                    // Preferences
                    SectionHeader(title: "Preferences")
                    GlassGroup {
                        VStack(spacing: 0) {
                            settingsRow(icon: "iphone.radiowaves.left.and.right", title: "Haptic Feedback")
                            Divider()
                            settingsRow(icon: "globe", title: "App Language", detail: currentLanguageLabel)
                            Divider()
                            Button(action: { showSubscriptionSheet = true }) {
                                settingsRow(icon: "cart", title: "Subscription")
                            }
                            .buttonStyle(.plain)
                            Divider()
                            HStack(spacing: 14) {
                                Image(systemName: "bell")
                                    .font(.system(size: 22))
                                    .frame(width: 30, alignment: .center)
                                    .foregroundStyle(accentColor)

                                Text("Notifications")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Toggle("", isOn: $notificationsEnabled)
                                    .labelsHidden()
                                    .tint(.green)
                            }
                            .padding(.vertical, 14)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal)

                    // Appearance
                    SectionHeader(title: "Appearance")
                    GlassGroup {
                        VStack(spacing: 0) {
                            Button(action: {
                                if let current = ThemeAccent(rawValue: appAccentRaw) {
                                    tempTheme = current
                                } else {
                                    tempTheme = (appearance == .dark) ? .pink : .blue
                                }
                                showThemeSheet = true
                            }) {
                                settingsRow(icon: "paintpalette", title: "Theme")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal)

                    // Help
                    SectionHeader(title: "Help")
                    GlassGroup {
                        VStack(spacing: 0) {
                            settingsRow(icon: "doc.text", title: "Terms of Use")
                            Divider()
                            settingsRow(icon: "questionmark.circle", title: "Help Centre")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal)

                    // Account
                    SectionHeader(title: "Account")
                    GlassGroup {
                        VStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                                    showLogoutAlert = true
                                }
                            }) {
                                HStack(spacing: 14) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 22))
                                        .frame(width: 30, alignment: .center)
                                        .foregroundStyle(.red)
                                    Text("Log Out")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 36)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(settingsBackgroundColor.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(appearance == .dark ? .dark : .light)
        .opacity(animateIn ? 1.0 : 0.96)
        .offset(y: animateIn ? 0 : 1)
        .animation(.smooth(duration: 0.28), value: animateIn)
        .onAppear { animateIn = true }
        .onDisappear { animateIn = false }
        .onReceive(NotificationCenter.default.publisher(for: .ProfileDidChange)) { _ in profileVersion &+= 1 }
        .safeAreaInset(edge: .top) {
            HStack(spacing: 0) {
                Spacer()
                Button(action: {
                    NotificationCenter.default.post(name: .ProfileDidChange, object: nil)
                    dismiss()
                }) {
                    GlassCircleIcon(systemName: "checkmark", size: 16, frame: 44)
                }
                .buttonStyle(.plain)
                .disabled(showEditProfileSheet)
                .allowsHitTesting(!showEditProfileSheet)
                .opacity(showEditProfileSheet ? 0.6 : 1)
            }
            .frame(height: 44)
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .presentationDetents([.fraction(1.0)])
        .presentationDragIndicator(.visible)
        .alert("Log Out?", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) {
                showLogoutAlert = false
            }
            Button("Cancel", role: .cancel) {
                showLogoutAlert = false
            }
        } message: {
            Text("You will need to sign in again to continue.")
        }
        .sheet(isPresented: $showEditProfileSheet) {
            EditProfileSheet()
                .presentationDetents([.fraction(1.0)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheetView()
        }
        .sheet(isPresented: $showThemeSheet) {
            ThemeSheetView()
                .presentationDetents([.fraction(1.0)])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func settingsRow(icon: String, title: String, detail: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .frame(width: 30, alignment: .center)
                .foregroundStyle(accentColor)
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Theme Sheet
private enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

private struct ThemeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var deviceIsDark: Bool {
        UIScreen.main.traitCollection.userInterfaceStyle == .dark
    }

    private var deviceScheme: ColorScheme {
        deviceIsDark ? .dark : .light
    }

    @AppStorage("AivaThemeModeV1") private var storedThemeMode: String = ThemeMode.system.rawValue
    @AppStorage("AivaThemeAccentSwatchIDV1") private var storedAccentID: String = "blue"
    @AppStorage("appAccent") private var appAccentRaw: String = "system"
    @AppStorage("appColorScheme") private var appColorSchemeRaw: String = "light"

    @State private var draftMode: ThemeMode = .system
    @State private var draftAccentID: String = "blue"

    @State private var originalModeRaw: String = ThemeMode.system.rawValue
    @State private var originalAccentID: String = "blue"

    private let previewCorner: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                HStack(spacing: 10) {
                    Button(action: {
                        storedThemeMode = originalModeRaw
                        storedAccentID = originalAccentID
                        NotificationCenter.default.post(name: Notification.Name("AivaThemeDidChange"), object: nil)
                        dismiss()
                    }) {
                        GlassCircleIcon(systemName: "xmark", size: 16, frame: 44)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    Spacer(minLength: 0)

                    Button(action: {
                        storedThemeMode = draftMode.rawValue
                        storedAccentID = draftAccentID
                        if ThemeAccent(rawValue: draftAccentID) != nil {
                            appAccentRaw = draftAccentID
                        }
                        switch draftMode {
                        case .system:
                            appColorSchemeRaw = "light"
                        case .light:
                            appColorSchemeRaw = "light"
                        case .dark:
                            appColorSchemeRaw = "dark"
                        }
                        NotificationCenter.default.post(name: Notification.Name("AivaThemeDidChange"), object: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            dismiss()
                        }
                    }) {
                        GlassCircleIcon(systemName: "checkmark", size: 16, frame: 44)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal)
            }
            .frame(height: 44)
            .padding(.top, 22)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    SectionHeader(title: "Theme")
                    ThemeGlassGroup {
                        VStack(spacing: 14) {
                            let shape = RoundedRectangle(cornerRadius: previewCorner, style: .continuous)
                            let isLightPreview = (draftMode == .light) || (draftMode == .system && !deviceIsDark)

                            let accentStyle: AnyShapeStyle = {
                                if let grad = gradientForSwatchID(draftAccentID) {
                                    return AnyShapeStyle(grad)
                                }
                                if let c = colorForSwatchID(draftAccentID) {
                                    return AnyShapeStyle(c)
                                }
                                return AnyShapeStyle(Color(.systemBlue))
                            }()

                            let cardFill: Color = isLightPreview
                                ? Color.white
                                : Color(.secondarySystemFill).opacity(0.55)

                            let lineFill: Color = isLightPreview
                                ? Color(.systemGray4)
                                : Color(.systemGray4)

                            let panelFill: Color = isLightPreview
                                ? Color(.systemGray4)
                                : Color(.systemGray4)

                            ZStack {
                                shape.fill(cardFill)

                                VStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(accentStyle)
                                        .frame(width: 96, height: 24, alignment: .leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(lineFill)
                                        .frame(height: 16)

                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(panelFill)
                                        .frame(height: 170)
                                }
                                .padding(18)
                                .frame(maxWidth: .infinity)
                            }
                            .frame(height: 280)
                        }
                        .padding(.vertical, 22)
                        .padding(.horizontal, 10)
                    }
                    .padding(.horizontal)

                    ThemeModePicker(selection: $draftMode)
                        .padding(.horizontal)
                        .onChange(of: draftMode) { newValue in
                            storedThemeMode = newValue.rawValue
                            switch newValue {
                            case .system:
                                appColorSchemeRaw = "light"
                            case .light:
                                appColorSchemeRaw = "light"
                            case .dark:
                                appColorSchemeRaw = "dark"
                            }
                            NotificationCenter.default.post(name: Notification.Name("AivaThemeDidChange"), object: nil)
                        }

                    SectionHeader(title: "Accent")
                    ThemeGlassGroup {
                        ThemeColorGrid(selectedID: $draftAccentID)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 24)
                }
                .padding(.top, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            (draftMode == .light
                ? Color.white
                : (draftMode == .dark
                    ? Color(.systemBackground)
                    : (!deviceIsDark ? Color.white : Color(.systemBackground))
                  )
            )
            .ignoresSafeArea()
        )
        .onAppear {
            originalModeRaw = storedThemeMode
            originalAccentID = storedAccentID
            draftMode = ThemeMode(rawValue: storedThemeMode) ?? .system
            if ThemeAccent(rawValue: appAccentRaw) != nil {
                draftAccentID = appAccentRaw
            } else {
                draftAccentID = storedAccentID
            }
            switch draftMode {
            case .system:
                appColorSchemeRaw = "light"
            case .light:
                appColorSchemeRaw = "light"
            case .dark:
                appColorSchemeRaw = "dark"
            }
        }
        .onChange(of: draftAccentID) { newValue in
            if ThemeAccent(rawValue: newValue) != nil {
                appAccentRaw = newValue
            }
            storedAccentID = newValue
        }
        .preferredColorScheme(
            draftMode == .system ? deviceScheme : (draftMode == .light ? .light : .dark)
        )
    }
}

private struct ThemeModePicker: View {
    @Binding var selection: ThemeMode

    var body: some View {
        Picker("Theme", selection: $selection) {
            ForEach(ThemeMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color(.systemBlue))
    }
}

private struct ThemeColorGrid: View {
    @Binding var selectedID: String

    private let swatchOrder: [String] = ["green", "yellow", "orange", "red", "indigo", "blue"]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(swatchOrder, id: \.self) { id in
                if let grad = gradientForSwatchID(id) {
                    Button(action: { selectedID = id }) {
                        ZStack {
                            Circle()
                                .fill(grad)
                                .frame(width: 44, height: 44)

                            if selectedID == id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Edit Profile Sheet
private struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var nickname: String = settings_loadProfileName() ?? ""
    @State private var email: String = settings_loadProfileEmail() ?? ""
    @State private var avatarImage: UIImage? = settings_loadProfileImage()
    @State private var photoItem: PhotosPickerItem? = nil

    @State private var selectedSwatchID: String? = profileIcon_loadColorID()

    private let avatarSize: CGFloat = 180

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: { dismiss() }) {
                        GlassCircleIcon(systemName: "xmark", size: 16, frame: 44)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }

                HStack {
                    Spacer()
                    Button(action: { saveAndClose() }) {
                        GlassCircleIcon(systemName: "checkmark", size: 16, frame: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 44)
            .padding(.horizontal)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 6) {
                Text("Customize Profile")
                    .font(.title2.weight(.bold))
                Text("Set your Account Image and Display Name")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 6)

            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let id = selectedSwatchID ?? profileIcon_loadColorID(),
                       let grad = gradientForSwatchID(id) {
                        Circle().fill(grad)
                    } else {
                        Circle().fill(defaultProfileColor)
                    }
                }
                .frame(width: avatarSize, height: avatarSize)

                if let ui = avatarImage {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                } else if let initials = settings_initials(from: nickname), !initials.isEmpty {
                    Text(initials)
                        .font(.system(size: 88, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: avatarSize, height: avatarSize, alignment: .center)
                } else {
                    Image(systemName: "person")
                        .font(.system(size: 80, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: avatarSize, height: avatarSize, alignment: .center)
                }

                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    GlassCircleIcon(systemName: "pencil", size: 16, frame: 44)
                }
                .buttonStyle(.plain)
                .offset(x: -8, y: -8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField("Display name", text: $nickname)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemFill))
                )
            }
            .padding(.horizontal)
            .padding(.top, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField("email@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .font(.body)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemFill))
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                let containerShape = RoundedRectangle(cornerRadius: 26, style: .continuous)
                let swatchOrder: [String] = ["red", "orange", "yellow", "green", "lightBlue", "blue", "indigo", "pink", "purple", "peach", "sand", "slate"]
                let columns = Array(
                    repeating: GridItem(.flexible(minimum: 34, maximum: 60), spacing: 18, alignment: .center),
                    count: 7
                )

                LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                    ForEach(swatchOrder, id: \.self) { id in
                        if let _ = swatch(for: id) {
                            Button(action: {
                                selectedSwatchID = id
                                avatarImage = nil
                                photoItem = nil
                                profileIcon_saveColorID(id)
                            }) {
                                ZStack {
                                    if let grad = gradientForSwatchID(id) {
                                        Circle().fill(grad)
                                    } else {
                                        Circle().fill(defaultProfileColor)
                                    }
                                    if selectedSwatchID == id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(width: 34, height: 34)
                                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(
                    containerShape
                        .fill(Color.clear)
                        .background(.bar, in: containerShape)
                        .glassEffect(in: containerShape)
                        .overlay(containerShape.stroke(Color.white.opacity(0.18), lineWidth: 0.75).blendMode(.plusLighter))
                        .overlay(containerShape.strokeBorder(Color.black.opacity(0.08), lineWidth: 0.75))
                        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Spacer()
        }
        .onChange(of: photoItem) { _ in
            Task {
                if let data = try? await photoItem?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    avatarImage = ui
                }
            }
        }
        .background((scheme == .dark ? Color(.systemBackground) : Color.white).ignoresSafeArea())
        .presentationDetents([.fraction(1.0)])
        .presentationDragIndicator(.visible)
    }

    private func saveAndClose() {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: settings_nsKey("ProfileDisplayNameV1"))
        } else {
            UserDefaults.standard.removeObject(forKey: settings_nsKey("ProfileDisplayNameV1"))
        }

        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !emailTrimmed.isEmpty {
            UserDefaults.standard.set(emailTrimmed, forKey: settings_nsKey("ProfileEmailV1"))
        } else {
            UserDefaults.standard.removeObject(forKey: settings_nsKey("ProfileEmailV1"))
        }

        if let ui = avatarImage, let data = ui.jpegData(compressionQuality: 0.9) {
            UserDefaults.standard.set(data, forKey: settings_nsKey("ProfileImageJPEGV1"))
        } else {
            UserDefaults.standard.removeObject(forKey: settings_nsKey("ProfileImageJPEGV1"))
        }

        profileIcon_saveColorID(selectedSwatchID)
        NotificationCenter.default.post(name: .ProfileDidChange, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
}
