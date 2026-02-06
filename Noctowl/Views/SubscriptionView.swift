//
//  SubscriptionView.swift
//  Noctowl
//
//  Copied layout from Phase 2 reference (UI-only).
//

import SwiftUI
import UIKit
import PassKit

private struct GlassCircleIconSub: View {
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

private struct LogoCircle: View {
    let size: CGFloat
    let assetName: String = "NoctowlLogo120x120"

    var body: some View {
        ZStack {
            let c = Circle()
            c
                .fill(Color.clear)
                .background(.bar, in: c)
                .glassEffect(.regular.tint(.clear).interactive(), in: .circle)

            Group {
                if let ui = UIImage(named: assetName) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.6))
                        .frame(width: size, height: size)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
        .compositingGroup()
    }
}

/// Sheet-friendly Subscription editor matching your Liquid Glass design language.
/// Presents plan selection and cancel flow as nested sheets.
struct SubscriptionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var keyboardHeight: CGFloat = 0
    @State private var showAvailablePlans = false
    @State private var showCancel = false

    @AppStorage("aiva.subscriptionTier") private var subscriptionTier: String = "Lite"
    @AppStorage("aiva.subscriptionPrice") private var subscriptionPrice: String = "4.99"
    /// When a paid tier is selected, we record the start date to compute next renewal
    @AppStorage("aiva.subscriptionStartDate") private var subscriptionStartDate: Double = 0 // epoch seconds

    // Notifications opt-in (set from SettingsView toggle). This is used to gate upgrade nudges.
    @AppStorage("NoctowlNotificationsOptInV1") private var notificationsOptInLegacy: Bool = false

    private var renewalText: String {
        let isFreeTier = subscriptionTier.lowercased() == "lite" || (Double(subscriptionPrice) ?? 0) == 0
        if isFreeTier {
            return "Upgrade to Air"
        }
        let baseDate: Date = subscriptionStartDate > 0 ? Date(timeIntervalSince1970: subscriptionStartDate) : Date()
        let next = Calendar.current.date(byAdding: .month, value: 1, to: baseDate) ?? Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM d"
        return "Renews \(fmt.string(from: next))"
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            GlassCircleIconSub(systemName: "chevron.left", size: 16, frame: 44)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }

                    Text("Subscription")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            GlassCircleIconSub(systemName: "checkmark", size: 16, frame: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal)
                .padding(.top, 16)

                Spacer().frame(height: 30)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        LogoCircle(size: 52)
                            .allowsHitTesting(false)
                            .padding(.bottom, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Noctowl")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            HStack {
                                Text("Noctowl \(subscriptionTier)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button(action: { showAvailablePlans = true }) {
                                    HStack(spacing: 6) {
                                        Text("See all plans")
                                            .font(.subheadline)
                                            .foregroundStyle(.tint)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.tint)
                                    }
                                }
                                .tint(.blue)
                            }
                            Divider().background(Color.primary.opacity(0.15))
                            let iconWidth: CGFloat = 22
                            let isFreeTier = subscriptionTier.lowercased() == "lite" || (Double(subscriptionPrice) ?? 0) == 0
                            HStack(spacing: 6) {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.primary)
                                    .frame(width: iconWidth, alignment: .leading)
                                    .offset(x: -3)
                                Text(displayedPrice)
                                    .font(.footnote)
                                    .foregroundColor(isFreeTier ? .primary : .secondary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.primary)
                                    .frame(width: iconWidth, alignment: .leading)
                                Text(renewalText)
                                    .font(.footnote)
                                    .foregroundColor(isFreeTier ? .primary : .secondary)
                            }
                        }
                    }
                    .padding(20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background {
                    let cardShape = RoundedRectangle(cornerRadius: 30, style: .continuous)
                    cardShape
                        .fill(Color.clear)
                        .background(.bar, in: cardShape)
                        .glassEffect(.regular.tint(.clear), in: cardShape)
                }
                .overlay {
                    let cardShape = RoundedRectangle(cornerRadius: 30, style: .continuous)
                    cardShape.stroke(Color.white.opacity(0.18), lineWidth: 0.75).blendMode(.plusLighter)
                }
                .overlay {
                    let cardShape = RoundedRectangle(cornerRadius: 30, style: .continuous)
                    cardShape.strokeBorder(Color.black.opacity(0.08), lineWidth: 0.75)
                }
                .cornerRadius(30)
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                .padding(.horizontal, 12)
                .onAppear {
                    let isFreeTier = subscriptionTier.lowercased() == "lite" || (Double(subscriptionPrice) ?? 0) == 0
                    if !isFreeTier && subscriptionStartDate == 0 {
                        subscriptionStartDate = Date().timeIntervalSince1970
                    }

                    NotificationManager.shared.configureUpgradeNudges(
                        enabled: notificationsOptInLegacy,
                        currentTierRaw: subscriptionTier,
                        deepLinkURL: URL(string: "aiva://settings/subscription")
                    )
                }
                .onChange(of: subscriptionTier) { _, newTier in
                    let isFree = newTier.lowercased() == "lite" || (Double(subscriptionPrice) ?? 0) == 0
                    if isFree {
                        subscriptionStartDate = 0
                    } else {
                        subscriptionStartDate = Date().timeIntervalSince1970
                    }

                    NotificationManager.shared.configureUpgradeNudges(
                        enabled: notificationsOptInLegacy,
                        currentTierRaw: newTier,
                        deepLinkURL: URL(string: "aiva://settings/subscription")
                    )
                }

                Spacer().frame(height: 24)

                Button(action: { showCancel = true }) {
                    HStack {
                        Text("Cancel Subscription")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 44)
                    .background {
                        let pillShape = RoundedRectangle(cornerRadius: 100, style: .continuous)
                        pillShape
                            .fill(Color.clear)
                            .background(.bar, in: pillShape)
                            .glassEffect(.regular.tint(.clear).interactive(), in: pillShape)
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)

                Spacer().frame(height: 12)

                Text("If you cancel now, you can still access your subscription until your next renewal date.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button(action: {}) {
                    Text("About Subscriptions and Privacy")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 15)
            }
            .padding(.top, 8)
            .padding(.horizontal, 12)
        }
        .sheet(isPresented: $showAvailablePlans) {
            AvailablePlansView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCancel) {
            CancelSubscriptionView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var displayedPrice: String {
        if subscriptionTier.lowercased() == "lite" || (Double(subscriptionPrice) ?? 0) == 0 {
            return "Free"
        }
        return "$\(subscriptionPrice) per month"
    }
}

// MARK: - AvailablePlansView
struct AvailablePlansView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("aiva.subscriptionTier") private var subscriptionTier: String = "Lite"
    @AppStorage("aiva.subscriptionPrice") private var subscriptionPrice: String = "4.99"

    enum Plan: String, CaseIterable, Identifiable {
        case lite = "Lite"
        case air = "Air"
        case pro = "Pro"
        case max = "Max"
        var id: String { rawValue }

        var displayPrice: String {
            switch self {
            case .lite: return "Free"
            case .air: return "$4.99/m"
            case .pro: return "$19.99/m"
            case .max: return "$29.99/m"
            }
        }
        var numericMonthlyPrice: String {
            switch self {
            case .lite: return "0.00"
            case .air: return "4.99"
            case .pro: return "19.99"
            case .max: return "29.99"
            }
        }
    }

    @State private var selected: Plan? = nil
    @State private var showApplePaySheet: Bool = false
    @State private var showPaymentOptions: Bool = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        GlassCircleIconSub(systemName: "xmark", size: 16, frame: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                LogoCircle(size: 72)

                Text("Available Plans")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                VStack(spacing: 12) {
                    ForEach(Plan.allCases) { plan in
                        PlanRow(title: plan.rawValue, price: plan.displayPrice, isSelected: selected == plan)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    selected = plan
                                    subscriptionTier = plan.rawValue
                                    subscriptionPrice = plan.numericMonthlyPrice
                                    if plan != .lite { showPaymentOptions = true }
                                }
                            }
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(.top, 24)
        }
        .onAppear {
            if let p = Plan(rawValue: subscriptionTier) {
                selected = p
            } else {
                selected = .lite
                subscriptionTier = "Lite"
                subscriptionPrice = "0.00"
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showApplePaySheet) {
            ApplePaySubscriptionSheet(planName: selected?.rawValue ?? "Air",
                                      priceString: selected?.displayPrice ?? "$4.99/m")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaymentOptions) {
            PaymentOptionsSheet(planName: selected?.rawValue ?? "Air",
                                priceString: selected?.displayPrice ?? "$4.99/m",
                                onApplePay: { showApplePaySheet = true })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct PlanRow: View {
    let title: String
    let price: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                if isSelected {
                    let circle = Circle()
                    circle
                        .fill(Color.blue)
                        .overlay(circle.stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    let glass = Circle()
                    glass
                        .fill(Color.clear)
                        .background(.bar, in: glass)
                        .glassEffect(.regular.tint(.clear).interactive(), in: glass)
                }
            }
            .frame(width: 24, height: 24)
            .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(price)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background {
            let pill = RoundedRectangle(cornerRadius: 100, style: .continuous)
            pill
                .fill(Color.clear)
                .background(.bar, in: pill)
                .glassEffect(.regular.tint(.clear).interactive(), in: pill)
        }
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}

private struct PaymentOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let planName: String
    let priceString: String
    let onApplePay: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    GlassCircleIconSub(systemName: "xmark", size: 16, frame: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            VStack(spacing: 6) {
                Text("Subscribe with Apple Pay")
                    .font(.title2.weight(.semibold))
                Text("\(planName)   \(priceString)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            HStack(spacing: 12) {
                LogoCircle(size: 44)
                    .allowsHitTesting(false)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Noctowl \(planName)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(priceString.replacingOccurrences(of: "/m", with: " per month"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background {
                let pill = RoundedRectangle(cornerRadius: 18, style: .continuous)
                pill
                    .fill(Color.clear)
                    .background(.bar, in: pill)
                    .glassEffect(.regular.tint(.clear), in: pill)
            }
            .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)

            ApplePayButtonView(type: .subscribe, style: .black) {
                dismiss()
                onApplePay()
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)

            Text("Confirm with Side Button")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text("You can cancel anytime in Settings   Apple Account. Plan automatically renews until cancelled.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
        }
        .padding(.top, 24)
    }
}

private struct ApplePayButtonView: UIViewRepresentable {
    let type: PKPaymentButtonType
    let style: PKPaymentButtonStyle
    let action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}

private struct ApplePaySubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let planName: String
    let priceString: String

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    GlassCircleIconSub(systemName: "xmark", size: 16, frame: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            VStack(spacing: 6) {
                Text("Confirm Subscription")
                    .font(.title2.weight(.semibold))
                Text("\(planName)   \(priceString)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            ApplePayButtonView(type: .subscribe, style: .black) {
                dismiss()
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)

            Text("Apple Pay subscription flow will be connected to Stripe. No charges will be made in this build.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 24)
    }
}

struct CancelSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingNextStep = false

    private let horizontalPadding: CGFloat = 24

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            GlassCircleIconSub(systemName: "xmark", size: 16, frame: 44)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }

                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            GlassCircleIconSub(systemName: "checkmark", size: 16, frame: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 16)

                Button(action: {}) {
                    LogoCircle(size: 72)
                        .allowsHitTesting(false)
                }

                Text("Cancel Subscription")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("You can continue using Noctowl until your plan ends. Do you want to proceed?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, horizontalPadding)

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    Button(action: { showingNextStep = true }) {
                        HStack {
                            Text("Continue")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            let pillShape = RoundedRectangle(cornerRadius: 100, style: .continuous)
                            pillShape
                                .fill(Color.clear)
                                .background(.bar, in: pillShape)
                                .glassEffect(.regular.tint(.clear).interactive(), in: pillShape)
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)

                    Button(action: { dismiss() }) {
                        HStack {
                            Text("Not now")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "xmark")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            let pillShape = RoundedRectangle(cornerRadius: 100, style: .continuous)
                            pillShape
                                .fill(Color.clear)
                                .background(.bar, in: pillShape)
                                .glassEffect(.regular.tint(.clear).interactive(), in: pillShape)
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 0)
                .padding(.horizontal, horizontalPadding + 4)
                .padding(.bottom, 0)
            }
        }
        .sheet(isPresented: $showingNextStep) {
            VStack(spacing: 16) {
                Text("Cancel flow coming soon")
                    .font(.headline)
                Button("Close") { showingNextStep = false }
            }
            .padding()
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Minimal stub to avoid compile errors without the full notification system.
private final class NotificationManager {
    static let shared = NotificationManager()
    func configureUpgradeNudges(enabled: Bool, currentTierRaw: String, deepLinkURL: URL?) {
        // UI-only placeholder
    }
}

#Preview {
    SubscriptionSheetView()
        .preferredColorScheme(.dark)
}
