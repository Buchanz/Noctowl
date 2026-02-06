import SwiftUI

/// Reusable 44×44 circular "profile" button using the app's Liquid Glass style.
/// Usage:
///     ProfileButton { showSettings = true }
/// or
///     ProfileButton(symbolName: "person") { pushSettings() }
struct ProfileButton: View {
    var symbolName: String = "person.crop.circle"
    var size: CGFloat = 44
    var symbolSize: CGFloat = 18
    var postsSettings: Bool = true
    var action: () -> Void = {}
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: {
            action()
            if postsSettings {
                NotificationCenter.default.post(name: Notification.Name("RequestPushSettings"), object: nil)
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .background(.bar, in: Circle())
                    .glassEffect(.regular.tint(.clear).interactive(), in: .circle)
                Image(systemName: symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: symbolSize, height: symbolSize)
                    .foregroundStyle(scheme == .dark ? Color.white : Color.black)
            }
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileButton { }
        .padding()
}
