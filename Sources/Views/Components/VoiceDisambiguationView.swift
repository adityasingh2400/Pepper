import SwiftUI

/// The pop-out chooser shown when voice input lands on a family of
/// variants (e.g. "cjc" → CJC-1295, No DAC, + Ipamorelin blend).
///
/// Design principles:
///   - Bubbles **emerge from the Pepper face** (bottom-right, voice source)
///     so the user reads them as coming from Pepper rather than a random
///     modal popping into the middle of the screen.
///   - Dark wine (`#5a1528` → `#3d0d1a`) fill, cream (`#f5ead9`) text —
///     matches the existing research family cards + research node cards
///     aesthetic so the surface feels like part of the research layer.
///   - Physics spring (`response: 0.45, damping: 0.72`) plus per-bubble
///     stagger (≈60 ms) — feels like the nodes are being *emitted* rather
///     than appearing all at once.
///   - Tapped bubble pulses + shrinks; unpicked bubbles collapse back
///     toward the Pepper face before the overlay tears down. That visual
///     link back to Pepper closes the loop: "this choice came from that
///     voice, and now it's going back there."
///
/// This view doesn't manage its own dismissal timing — it calls
/// `onPick(option)` and lets the voice navigator orchestrate the
/// subsequent walkthrough + overlay fade-out.
struct VoiceDisambiguationView: View {
    let group: DisambiguationGroup
    let voiceButtonCenter: CGPoint
    let containerSize: CGSize
    let onPick: (DisambiguationGroup.Option) -> Void

    /// Drives the initial emerge animation (0 → 1 on appear).
    @State private var appeared = false
    /// The option the user tapped — used to fade/shrink the rejected
    /// bubbles during the hand-off transition.
    @State private var chosen: DisambiguationGroup.Option.ID? = nil

    var body: some View {
        ZStack {
            // Soft dimming scrim so the bubbles read clearly against
            // whatever tab is behind us. Gradient centered on the voice
            // button so the source anchor stays visually "lit".
            RadialGradient(
                colors: [
                    Color.black.opacity(appeared ? 0.0 : 0.0),
                    Color.black.opacity(appeared ? 0.38 : 0.0)
                ],
                center: UnitPoint(
                    x: voiceButtonCenter.x / max(containerSize.width, 1),
                    y: voiceButtonCenter.y / max(containerSize.height, 1)
                ),
                startRadius: 40,
                endRadius: max(containerSize.width, containerSize.height) * 0.9
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.32), value: appeared)
            .allowsHitTesting(false)

            // Title pill — centered high, introduces the choice.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                    .frame(height: containerSize.height * 0.18)
                Text(group.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(Color(hex: "f5ead9"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(hex: "5a1528"), Color(hex: "3d0d1a")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .overlay(
                        Capsule().stroke(Color(hex: "c9a67a").opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "3d0d1a").opacity(0.45), radius: 10, y: 3)
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.38, dampingFraction: 0.72)
                            .delay(Double(group.options.count) * 0.06 + 0.05),
                        value: appeared
                    )
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)

            // Bubbles — laid out in an arc above the Pepper face. Each
            // bubble's **target position** is fixed by `layout(...)`; on
            // appear we animate from the voice-button anchor to the
            // target with a per-index stagger so the whole constellation
            // blossoms outward.
            ForEach(Array(group.options.enumerated()), id: \.element.id) { pair in
                let option = pair.element
                let target = layoutPosition(for: pair.offset, count: group.options.count)
                let isChosen = chosen == option.id
                let isRejected = chosen != nil && !isChosen

                bubble(for: option)
                    .position(appeared ? target : voiceButtonCenter)
                    .scaleEffect(bubbleScale(isChosen: isChosen, isRejected: isRejected))
                    .opacity(bubbleOpacity(isChosen: isChosen, isRejected: isRejected))
                    .animation(
                        .spring(response: 0.48, dampingFraction: 0.72)
                            .delay(Double(pair.offset) * 0.06),
                        value: appeared
                    )
                    .animation(.easeInOut(duration: 0.28), value: chosen)
            }
        }
        .onAppear {
            // Defer one frame so the position transition animates from the
            // source point rather than snapping there.
            DispatchQueue.main.async {
                withAnimation { appeared = true }
            }
        }
    }

    // MARK: - Bubble

    @ViewBuilder
    private func bubble(for option: DisambiguationGroup.Option) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            guard chosen == nil else { return }
            chosen = option.id
            // Give the collapse animation a beat before the parent tears
            // the chooser down + hands off to the walkthrough.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                onPick(option)
            }
        } label: {
            VStack(spacing: 3) {
                Text(option.label)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "f5ead9"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(option.subtitle)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color(hex: "e8d5bc").opacity(0.88))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(width: 150)
            .background(
                LinearGradient(
                    colors: [Color(hex: "5a1528"), Color(hex: "3d0d1a")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: "c9a67a").opacity(0.38), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "3d0d1a").opacity(0.55), radius: 14, x: 0, y: 6)
            // Subtle maroon outer halo — matches the voice perimeter so the
            // bubbles feel like part of the same surface.
            .shadow(color: Color(hex: "9f1239").opacity(0.35), radius: 24, x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.label) — \(option.subtitle)")
    }

    private func bubbleScale(isChosen: Bool, isRejected: Bool) -> CGFloat {
        if isChosen    { return 1.08 }
        if isRejected  { return 0.55 }
        return appeared ? 1.0 : 0.35
    }

    private func bubbleOpacity(isChosen: Bool, isRejected: Bool) -> Double {
        if isRejected { return 0.0 }
        return appeared ? 1.0 : 0.0
    }

    // MARK: - Layout

    /// Arcs the bubbles across the upper half of the screen, each row
    /// offset so wider groups (4+) don't overlap. The arc is centered
    /// horizontally and sits just above vertical center so it visually
    /// "sits on top of" the Pepper face below.
    private func layoutPosition(for index: Int, count: Int) -> CGPoint {
        let w = containerSize.width
        let h = containerSize.height
        let centerX = w / 2
        let baselineY = h * 0.48     // just above vertical center
        let bubbleWidth: CGFloat = 150
        let bubbleGap: CGFloat = 14
        let perRow = min(count, 3)   // wrap 4+ onto two rows
        let row = index / perRow
        let col = index % perRow
        let rowCount = count <= perRow ? 1 : 2
        let itemsInThisRow: Int = {
            if rowCount == 1 { return count }
            if row == 0 { return perRow }
            return count - perRow
        }()
        let rowWidth = CGFloat(itemsInThisRow) * bubbleWidth + CGFloat(max(itemsInThisRow - 1, 0)) * bubbleGap
        let startX = centerX - rowWidth / 2 + bubbleWidth / 2
        let x = startX + CGFloat(col) * (bubbleWidth + bubbleGap)

        // Light vertical arc within a row so the center bubbles sit a hair
        // lower than the outside ones — makes the constellation feel
        // hand-placed rather than a grid.
        let mid = CGFloat(itemsInThisRow - 1) / 2
        let arc = abs(CGFloat(col) - mid) * 6
        let rowSpacing: CGFloat = 96
        let y = baselineY - CGFloat(row) * rowSpacing + arc

        return CGPoint(x: x, y: y)
    }
}
