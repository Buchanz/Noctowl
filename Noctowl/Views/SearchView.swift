import SwiftUI
private struct MonthLikelihoodBar: View {
    let values: [Double] // 12 values (0…1)
    let current: Double  // progress 0…12 (e.g., 5.5 = mid-June)

    private static let monthLabels = ["J","F","M","A","M","J","J","A","S","O","N","D"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let colW = (w - 11) / 12 // 11 gaps of 1pt

            // Layout constants
            let labelH: CGFloat = 12
            let gap: CGFloat = 2
            let barAreaH = max(3, h - (labelH + gap))

            ZStack(alignment: .bottomLeading) {
                // 1) Month labels — fixed baseline at the very bottom
                HStack(spacing: 1) {
                    ForEach(0..<12, id: \.self) { i in
                        Text(Self.monthLabels[i])
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: colW, height: labelH, alignment: .top)
                    }
                }
                .padding(.bottom, 0)

                // 2) Bars — sit above labels, bottom-aligned within bar area
                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(0..<12, id: \.self) { i in
                        let raw = (i < values.count) ? values[i] : 0
                        let v = max(0.08, min(1, raw))
                        let barH = max(3, barAreaH * v)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.secondary.opacity(0.35))
                            .frame(width: colW, height: barH)
                    }
                }
                .frame(height: barAreaH)
                .offset(y: -(labelH + gap))

                // 3) Current day indicator — taller and vertically centered in the bar area
                let progress = max(0, min(11.999, current))
                let x = (colW + 1) * progress
                let indicatorH = barAreaH // full bar area height
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: 2, height: indicatorH)
                    .offset(x: x, y: -(labelH + gap))
                    .animation(.linear(duration: 60), value: current)
            }
        }
    }
}
