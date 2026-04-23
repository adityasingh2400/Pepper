import Foundation

// Pharmacokinetic timeline for a peptide.
// `timeToEffect` = onset (when the user usually feels something).
// `peakEffect`   = peak concentration / maximum response.
// `duration`     = approximate end of action above baseline.
// `halfLife`     = elimination half-life (used for steady-state estimates).
struct PeptideTimeline: Equatable, Hashable {
    let timeToEffectHours: Double?
    let peakEffectHours: Double?
    let durationHours: Double?
    let halfLifeHours: Double?

    var hasAnyData: Bool {
        timeToEffectHours != nil
            || peakEffectHours != nil
            || durationHours != nil
            || halfLifeHours != nil
    }

    // Time until estimated steady-state concentration on a regular schedule
    // (4–5 half-lives by convention).
    var steadyStateHours: Double? {
        guard let h = halfLifeHours, h > 0 else { return nil }
        return h * 5
    }

    // Convenience for friendly display: returns ranges in human units.
    var humanOnset: String? {
        timeToEffectHours.map(Self.formatHours)
    }
    var humanPeak: String? {
        peakEffectHours.map(Self.formatHours)
    }
    var humanDuration: String? {
        durationHours.map(Self.formatHours)
    }
    var humanHalfLife: String? {
        halfLifeHours.map(Self.formatHours)
    }

    static func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            let minutes = Int((hours * 60).rounded())
            return "\(minutes) min"
        }
        if hours < 36 {
            // Show 0.5 precision under 36h
            let rounded = (hours * 2).rounded() / 2
            return rounded.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(rounded)) hr"
                : String(format: "%.1f hr", rounded)
        }
        let days = (hours / 24).rounded(.toNearestOrEven)
        return "~\(Int(days)) days"
    }
}

extension Compound {
    var timeline: PeptideTimeline {
        PeptideTimeline(
            timeToEffectHours: timeToEffectHours,
            peakEffectHours:   peakEffectHours,
            durationHours:     durationHours,
            halfLifeHours:     halfLifeHrs
        )
    }
}
