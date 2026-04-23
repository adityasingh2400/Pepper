import SwiftUI

/// God-tier visual pharmacokinetic timeline for a peptide.
///
/// Two modes:
/// - `.compact`  : a single-line curve with onset/peak/duration markers.
///                 Used inline on Today and Protocol cards.
/// - `.expanded` : the curve plus a labelled grid of onset / peak / duration /
///                 half-life / steady-state. Used on the Research detail page.
///
/// What makes it good:
/// - We draw an actual concentration curve (sigmoid rise → exponential decay)
///   built from the compound's published time-to-effect, peak, duration, and
///   half-life — not a flat bar.
/// - The curve animates in on appear (left → right reveal) so the eye lands on
///   the peak naturally.
/// - Hour ticks are spaced on a real x-axis so 30 min and 24 h compounds use
///   the same component but read differently.
/// - Optional `dosedAt` timestamp draws a "Now" indicator that animates as the
///   user lingers on the screen, anchoring the abstract curve to real time.
struct PeptideTimelineView: View {
    enum Mode { case compact, expanded }

    let timeline: PeptideTimeline
    var mode: Mode = .compact
    var accentColor: Color = .appAccent
    /// Optional anchor for a "Now" marker. Pass the most recent dose time to
    /// turn the curve into something the user can read against the clock.
    var dosedAt: Date? = nil

    @State private var animateProgress: Double = 0
    @State private var pulse = false

    var body: some View {
        if !timeline.hasAnyData {
            EmptyView()
        } else {
            switch mode {
            case .compact: compactBody
            case .expanded: expandedBody
            }
        }
    }

    // MARK: - Compact

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: nowConcentrationFraction == nil ? "waveform.path.ecg" : "waveform.badge.mic")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(accentColor)
                Text(compactHeadline)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                Spacer(minLength: 6)
                if let pct = nowConcentrationFraction {
                    nowPill(percent: pct)
                } else if let summary = activityHeadline {
                    Text(summary)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextTertiary)
                        .lineLimit(1)
                }
            }

            curveArea(height: 78, showLabels: true, showGrid: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appCardElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
        .onAppear { animateIn() }
    }

    /// Headline used at the top of the compact card. Switches to a friendlier
    /// "Active in your system" copy when we know how long ago you dosed.
    private var compactHeadline: String {
        nowConcentrationFraction == nil ? "Active window" : "Active in your system"
    }

    /// Animated "Now: 67%" pill that anchors the abstract curve to a real
    /// percentage so the user can read it like a status bar.
    private func nowPill(percent: Double) -> some View {
        let value = Int((percent * 100).rounded())
        return HStack(spacing: 5) {
            Circle()
                .fill(accentColor)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(0.4), lineWidth: 4)
                        .scaleEffect(pulse ? 2.2 : 1)
                        .opacity(pulse ? 0 : 0.8)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                )
            Text("Now \(value)%")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: accentColor.opacity(0.35), radius: 6, y: 2)
    }

    /// Compute the current concentration as a fraction (0..1) of peak.
    /// Returns nil when no `dosedAt` was supplied or we're outside the curve.
    private var nowConcentrationFraction: Double? {
        guard let frac = nowAxisFraction(), frac >= 0, frac <= 1 else { return nil }
        let samples = curveSamples()
        guard let after = samples.firstIndex(where: { $0.x >= frac }), after > 0 else { return nil }
        let prev = samples[after - 1]
        let next = samples[after]
        let span = next.x - prev.x
        let alpha = span > 0 ? (frac - prev.x) / span : 0
        return prev.y + (next.y - prev.y) * alpha
    }

    // MARK: - Expanded

    private var expandedBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accentColor)
                Text("Pharmacokinetic timeline")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                Spacer()
                if let summary = activityHeadline {
                    Text(summary)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(accentColor.opacity(0.10))
                        )
                }
            }

            curveArea(height: 130, showLabels: true, showGrid: true)

            statsGrid
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appCardElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
        .onAppear { animateIn() }
    }

    private var statsGrid: some View {
        let items: [(String, String?, String)] = [
            ("Onset",        timeline.humanOnset,                                          "bolt.fill"),
            ("Peak",         timeline.humanPeak,                                           "chart.line.uptrend.xyaxis"),
            ("Duration",     timeline.humanDuration,                                       "clock.fill"),
            ("Half-life",    timeline.humanHalfLife,                                       "arrow.triangle.2.circlepath"),
            ("Steady state", timeline.steadyStateHours.map(PeptideTimeline.formatHours),   "infinity"),
        ].filter { $0.1 != nil }

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ],
            spacing: 10
        ) {
            ForEach(items, id: \.0) { item in
                statTile(label: item.0, value: item.1 ?? "", icon: item.2)
            }
        }
    }

    private func statTile(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .kerning(0.6)
            }
            .foregroundColor(Color.appTextMeta)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color.appTextPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.appCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Curve area

    private func curveArea(height: CGFloat, showLabels: Bool, showGrid: Bool) -> some View {
        GeometryReader { geo in
            let width  = geo.size.width
            let curveH = height
            let topPadding: CGFloat = showLabels ? 18 : 4
            let baseY  = curveH - 14

            ZStack(alignment: .topLeading) {
                // Background grid
                if showGrid {
                    timeGrid(width: width, height: curveH, baseY: baseY, topPadding: topPadding)
                }

                // Filled area under curve
                CurveShape(
                    samples: curveSamples(),
                    progress: animateProgress,
                    fillBaseline: baseY
                )
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.32), accentColor.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: curveH)

                // The curve itself
                CurveLine(samples: curveSamples(), progress: animateProgress)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor.opacity(0.6), accentColor, accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: width, height: curveH)

                // Markers on top
                markersOverlay(width: width, height: curveH, baseY: baseY, showLabels: showLabels)

                // "Now" indicator
                if let nowFraction = nowAxisFraction(), nowFraction >= 0, nowFraction <= 1 {
                    nowIndicator(at: width * CGFloat(nowFraction), height: curveH)
                }
            }
            .clipped()
        }
        .frame(height: height)
    }

    // MARK: - Grid

    private func timeGrid(width: CGFloat, height: CGFloat, baseY: CGFloat, topPadding: CGFloat) -> some View {
        let stops = gridStops()
        return ZStack(alignment: .topLeading) {
            // Baseline
            Path { p in
                p.move(to: CGPoint(x: 0, y: baseY))
                p.addLine(to: CGPoint(x: width, y: baseY))
            }
            .stroke(Color.appBorder.opacity(0.45), lineWidth: 0.5)

            // Vertical hour ticks + tiny labels at the bottom
            ForEach(stops, id: \.value) { stop in
                let x = width * CGFloat(stop.fraction)
                Path { p in
                    p.move(to: CGPoint(x: x, y: topPadding))
                    p.addLine(to: CGPoint(x: x, y: baseY))
                }
                .stroke(Color.appBorder.opacity(0.25), style: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))

                Text(stop.label)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Color.appTextMeta)
                    .position(x: x, y: baseY + 8)
            }
        }
    }

    /// Returns hour-stops for the grid (between 4 and 6 ticks across the axis).
    private func gridStops() -> [(value: Double, fraction: Double, label: String)] {
        let maxX = maxXHours
        let candidates: [Double]
        if maxX <= 1 {           candidates = [0, 0.25, 0.5, 0.75, 1] }
        else if maxX <= 6  {     candidates = [0, 1, 2, 3, 4, 6] }
        else if maxX <= 12 {     candidates = [0, 2, 4, 6, 8, 12] }
        else if maxX <= 24 {     candidates = [0, 4, 8, 12, 18, 24] }
        else if maxX <= 72 {     candidates = [0, 12, 24, 48, 72] }
        else if maxX <= 168 {    candidates = [0, 24, 72, 120, 168] }
        else                {    candidates = [0, maxX * 0.25, maxX * 0.5, maxX * 0.75, maxX] }

        return candidates
            .filter { $0 <= maxX + 0.001 }
            .map { v in
                (value: v, fraction: v / maxX, label: shortHourLabel(v))
            }
    }

    private func shortHourLabel(_ hours: Double) -> String {
        if hours == 0 { return "0" }
        if hours < 1 {
            return "\(Int(hours * 60))m"
        }
        if hours < 24 {
            return hours.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(hours))h"
                : String(format: "%.1fh", hours)
        }
        let days = hours / 24
        return days.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(days))d"
            : String(format: "%.1fd", days)
    }

    // MARK: - Markers overlay

    private func markersOverlay(width: CGFloat, height: CGFloat, baseY: CGFloat, showLabels: Bool) -> some View {
        let onsetX    = (timeline.timeToEffectHours ?? 0) / maxXHours
        let peakX     = (timeline.peakEffectHours ?? 0) / maxXHours
        let durationX = (timeline.durationHours ?? maxXHours) / maxXHours

        return ZStack(alignment: .topLeading) {
            if let _ = timeline.timeToEffectHours {
                marker(
                    label: showLabels ? "Onset" : nil,
                    x: width * onsetX,
                    y: yForFraction(onsetX, baseY: baseY, height: height),
                    color: accentColor.opacity(0.6),
                    prominent: false
                )
            }
            if let _ = timeline.peakEffectHours {
                marker(
                    label: showLabels ? "Peak" : nil,
                    x: width * peakX,
                    y: yForFraction(peakX, baseY: baseY, height: height),
                    color: accentColor,
                    prominent: true
                )
            }
            if let _ = timeline.durationHours {
                marker(
                    label: showLabels ? "End" : nil,
                    x: width * durationX,
                    y: yForFraction(durationX, baseY: baseY, height: height),
                    color: accentColor.opacity(0.55),
                    prominent: false
                )
            }
        }
        .opacity(animateProgress)
    }

    private func marker(label: String?, x: CGFloat, y: CGFloat, color: Color, prominent: Bool) -> some View {
        let dotSize: CGFloat = prominent ? 11 : 8
        return ZStack {
            if prominent {
                Circle()
                    .stroke(color.opacity(0.45), lineWidth: 1.5)
                    .frame(width: pulse ? 24 : 14, height: pulse ? 24 : 14)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
            }
            Circle()
                .fill(color)
                .frame(width: dotSize, height: dotSize)
                .overlay(
                    Circle()
                        .stroke(Color.appCardElevated, lineWidth: 2)
                )
            if let label {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(color)
                    )
                    .offset(y: -16)
            }
        }
        .position(x: x, y: y)
    }

    private func nowIndicator(at x: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Path { p in
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: height - 14))
            }
            .stroke(Color.appTextPrimary.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            Text("Now")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.appTextPrimary))
                .position(x: x, y: 8)
        }
    }

    // MARK: - Curve math

    /// Produce a normalized x→y sample curve in (0..1) coordinates.
    /// We use a smoothstep ramp to peak, then exponential decay using half-life.
    private func curveSamples() -> [CGPoint] {
        let onset    = timeline.timeToEffectHours ?? 0
        let peak     = timeline.peakEffectHours   ?? Swift.max(onset, maxXHours / 4)
        let duration = timeline.durationHours     ?? maxXHours
        let halfLife = timeline.halfLifeHours     ?? Swift.max(0.5, (duration - peak) / 2)

        let resolution = 80
        return (0...resolution).map { i in
            let t = Double(i) / Double(resolution) * maxXHours
            let y: Double
            if t <= onset {
                // Slow lead-in
                y = 0.05 * (t / Swift.max(0.001, onset))
            } else if t <= peak {
                let p = (t - onset) / Swift.max(0.001, (peak - onset))
                // smoothstep
                let s = p * p * (3 - 2 * p)
                y = 0.05 + 0.95 * s
            } else {
                // Exponential decay using half-life
                let dt = t - peak
                let decay = pow(0.5, dt / Swift.max(0.001, halfLife))
                y = decay
            }
            return CGPoint(x: t / maxXHours, y: Swift.max(0, Swift.min(1, y)))
        }
    }

    /// Get y position for a normalized x fraction by interpolating samples.
    private func yForFraction(_ fraction: Double, baseY: CGFloat, height: CGFloat) -> CGFloat {
        let samples = curveSamples()
        let target = Swift.max(0, Swift.min(1, fraction))
        guard let next = samples.firstIndex(where: { $0.x >= target }), next > 0 else {
            return baseY
        }
        let prev = samples[next - 1]
        let n = samples[next]
        let span = n.x - prev.x
        let alpha = span > 0 ? (target - prev.x) / span : 0
        let y = prev.y + (n.y - prev.y) * alpha
        // Map y (0..1) to vertical baseY..top
        let topY: CGFloat = 18
        return baseY - (baseY - topY) * y
    }

    private var maxXHours: Double {
        if let d = timeline.durationHours, d > 0 {
            // Pad by 10% so the end marker doesn't sit on the right edge
            return d * 1.05
        }
        if let p = timeline.peakEffectHours, p > 0 { return p * 2 }
        if let o = timeline.timeToEffectHours, o > 0 { return o * 4 }
        return 24
    }

    /// If `dosedAt` was provided, return the fraction along the axis that
    /// corresponds to "now". Otherwise nil.
    private func nowAxisFraction() -> Double? {
        guard let t0 = dosedAt else { return nil }
        let elapsedHours = Date().timeIntervalSince(t0) / 3600
        guard elapsedHours >= 0 else { return nil }
        return elapsedHours / maxXHours
    }

    /// Single-line summary like "Active 8 h · Peaks at 2 h"
    private var activityHeadline: String? {
        var parts: [String] = []
        if let peak = timeline.humanPeak { parts.append("Peaks at \(peak)") }
        if let dur  = timeline.humanDuration { parts.append("active \(dur)") }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ").capitalizedFirstLetter
    }

    private func animateIn() {
        animateProgress = 0
        withAnimation(.easeInOut(duration: 1.0)) {
            animateProgress = 1
        }
        pulse = true
    }
}

// MARK: - Curve shapes

/// Closed shape under the curve for the gradient fill.
private struct CurveShape: Shape {
    let samples: [CGPoint]
    var progress: Double
    let fillBaseline: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let visible = Swift.max(0, Swift.min(1, progress))
        let cutoff = visible
        let active = samples.filter { $0.x <= cutoff + 1e-6 }
        guard let first = active.first else { return path }

        // Map y(0..1) to baseY → top
        let baseY = fillBaseline
        let topY: CGFloat = 18
        func yMap(_ y: Double) -> CGFloat { baseY - (baseY - topY) * CGFloat(y) }

        path.move(to: CGPoint(x: rect.width * CGFloat(first.x), y: baseY))
        for pt in active {
            path.addLine(to: CGPoint(x: rect.width * CGFloat(pt.x), y: yMap(pt.y)))
        }
        if let last = active.last {
            path.addLine(to: CGPoint(x: rect.width * CGFloat(last.x), y: baseY))
        }
        path.closeSubpath()
        return path
    }
}

/// Stroked top edge of the curve.
private struct CurveLine: Shape {
    let samples: [CGPoint]
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let visible = Swift.max(0, Swift.min(1, progress))
        let cutoff = visible
        let active = samples.filter { $0.x <= cutoff + 1e-6 }
        guard let first = active.first else { return path }

        let baseY: CGFloat = rect.height - 14
        let topY:  CGFloat = 18
        func yMap(_ y: Double) -> CGFloat { baseY - (baseY - topY) * CGFloat(y) }

        path.move(to: CGPoint(x: rect.width * CGFloat(first.x), y: yMap(first.y)))
        for pt in active.dropFirst() {
            path.addLine(to: CGPoint(x: rect.width * CGFloat(pt.x), y: yMap(pt.y)))
        }
        return path
    }
}

private extension String {
    var capitalizedFirstLetter: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

#if DEBUG
#Preview("Compact") {
    VStack(spacing: 16) {
        PeptideTimelineView(
            timeline: .init(
                timeToEffectHours: 0.5,
                peakEffectHours:   2,
                durationHours:     8,
                halfLifeHours:     4
            ),
            mode: .compact
        )
        PeptideTimelineView(
            timeline: .init(
                timeToEffectHours: 24,
                peakEffectHours:   72,
                durationHours:     168,
                halfLifeHours:     180
            ),
            mode: .expanded,
            dosedAt: Date().addingTimeInterval(-3600 * 36)
        )
    }
    .padding()
    .background(Color.appBackground)
}
#endif
