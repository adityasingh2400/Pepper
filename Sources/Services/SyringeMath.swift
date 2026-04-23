import Foundation

/// Pure-math service for peptide reconstitution + draw-volume calculations.
///
/// All inputs/outputs use plain `Double` (mg, mL, mcg, units). Insulin syringe
/// "units" are 0.01 mL ticks, which is the dosing surface most peptide users
/// see in real life. There are deliberately no UI types here.
///
/// Public surface:
///   - `Suggestion`           : recommended BAC water + concentration for a vial
///   - `Draw`                 : how to actually pull a target dose
///   - `suggest(...)`         : pick a BAC water volume that lands on a clean draw
///   - `draw(...)`            : compute the draw for a target dose
///   - `roundUnitsToHalf(_:)` : helper used in UI labels
///
/// Conventions:
///   - 1 unit = 0.01 mL (U-100 insulin syringe convention)
///   - Doses are expressed in mcg
///   - We assume 1 mg powder = 1,000 mcg active (standard for peptide vials)
enum SyringeMath {

    // MARK: - Outputs

    struct Suggestion: Equatable, Hashable {
        let bacWaterMl: Double            // recommended water volume to add
        let mcgPerUnit: Double            // resulting concentration
        let unitsForLowDose: Double       // syringe units for the low end
        let unitsForHighDose: Double      // syringe units for the high end
        let comfortable: Bool             // both low + high land in 5–95 unit range
        let rationale: String             // human-readable explanation
    }

    struct Draw: Equatable, Hashable {
        let mcg: Double                   // target dose
        let units: Double                 // raw units (insulin ticks)
        let unitsRounded: Double          // unit nearest 0.5 tick (real syringe precision)
        let mL: Double                    // raw volume in mL
        let mcgPerUnit: Double            // concentration used
        let isOutOfRange: Bool            // true if rounded draw > 100 or < 1 unit

        var unitsLabel: String {
            unitsRounded.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(unitsRounded)) units"
                : String(format: "%.1f units", unitsRounded)
        }

        var concentrationLabel: String {
            String(format: "%.0f mcg / unit", mcgPerUnit)
        }
    }

    // MARK: - Public API

    /// Recommend a BAC water volume that puts the user's expected dose range in
    /// a comfortable 5–95 unit window on a 100-unit insulin syringe.
    ///
    /// We try each candidate water volume (1, 1.5, 2, 2.5, 3, 4, 5 mL) and
    /// pick the smallest one whose low+high doses both fall in [5, 95] units —
    /// this minimises BAC water waste while keeping draws readable. If nothing
    /// is comfortable we fall back to whichever option keeps the high dose
    /// closest to ~50 units (the sweet spot for accuracy) so the UI can warn.
    static func suggest(
        totalMg: Double,
        lowDoseMcg: Double,
        highDoseMcg: Double
    ) -> Suggestion {
        precondition(totalMg > 0, "totalMg must be positive")
        let candidates: [Double] = [1, 1.5, 2, 2.5, 3, 4, 5]
        var best: Suggestion?
        var fallback: Suggestion?
        var fallbackScore = Double.infinity

        for water in candidates {
            let mcgPerUnit = (totalMg * 1_000.0) / (water * 100.0)
            guard mcgPerUnit > 0 else { continue }
            let lowU  = lowDoseMcg  / mcgPerUnit
            let highU = highDoseMcg / mcgPerUnit
            let comfortable = lowU >= 5 && highU <= 95

            let s = Suggestion(
                bacWaterMl: water,
                mcgPerUnit: mcgPerUnit,
                unitsForLowDose: lowU,
                unitsForHighDose: highU,
                comfortable: comfortable,
                rationale: rationale(water: water, mcgPerUnit: mcgPerUnit, lowU: lowU, highU: highU, comfortable: comfortable)
            )

            if comfortable, best == nil {
                best = s   // first comfortable = smallest comfortable
            }
            // Track best non-comfortable: high-dose closest to 50 units
            let score = abs(highU - 50)
            if score < fallbackScore {
                fallbackScore = score
                fallback = s
            }
        }

        return best ?? fallback ?? Suggestion(
            bacWaterMl: 2.0,
            mcgPerUnit: (totalMg * 1_000.0) / 200.0,
            unitsForLowDose:  lowDoseMcg  * 200.0 / (totalMg * 1_000.0),
            unitsForHighDose: highDoseMcg * 200.0 / (totalMg * 1_000.0),
            comfortable: false,
            rationale: "Default 2 mL fallback — adjust manually."
        )
    }

    /// Compute how to draw a single target dose given the vial concentration.
    static func draw(mcg: Double, mcgPerUnit: Double) -> Draw {
        precondition(mcg >= 0, "mcg must be non-negative")
        precondition(mcgPerUnit > 0, "mcgPerUnit must be positive")
        let units = mcg / mcgPerUnit
        let mL    = units * 0.01
        let rounded = roundUnitsToHalf(units)
        let outOfRange = rounded < 1 || rounded > 100
        return Draw(
            mcg: mcg,
            units: units,
            unitsRounded: rounded,
            mL: mL,
            mcgPerUnit: mcgPerUnit,
            isOutOfRange: outOfRange
        )
    }

    /// Round to the nearest 0.5 unit (the real precision a 100-unit insulin
    /// syringe lets you see). Anything below 0.5 rounds up to 0.5 to avoid
    /// returning a "0 unit" draw on tiny doses.
    static func roundUnitsToHalf(_ units: Double) -> Double {
        guard units > 0 else { return 0 }
        let rounded = (units * 2).rounded() / 2
        return Swift.max(rounded, 0.5)
    }

    // MARK: - Internals

    private static func rationale(
        water: Double,
        mcgPerUnit: Double,
        lowU: Double,
        highU: Double,
        comfortable: Bool
    ) -> String {
        let waterStr = water.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(water)) mL"
            : String(format: "%.1f mL", water)
        let conc = String(format: "%.0f mcg/unit", mcgPerUnit)
        let lo = roundUnitsToHalf(lowU)
        let hi = roundUnitsToHalf(highU)
        let loStr = lo.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(lo))" : String(format: "%.1f", lo)
        let hiStr = hi.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(hi))" : String(format: "%.1f", hi)
        if comfortable {
            return "\(waterStr) BAC water → \(conc). Low dose draws \(loStr) units, high dose \(hiStr) — both land in the easy-to-read part of an insulin syringe."
        } else {
            return "\(waterStr) BAC water → \(conc). Best available match (low \(loStr)u, high \(hiStr)u). Smaller draws may be hard to measure precisely."
        }
    }
}

// MARK: - Compound convenience

extension Compound {
    /// Build a `Suggestion` from this compound's defaults + dosing range.
    func bacSuggestion(forVialMg mg: Double? = nil) -> SyringeMath.Suggestion {
        let totalMg = mg ?? suggestedVialMg
        let low  = dosingRangeLowMcg  ?? 100
        let high = dosingRangeHighMcg ?? Swift.max(low, 500)
        return SyringeMath.suggest(totalMg: totalMg, lowDoseMcg: low, highDoseMcg: high)
    }

    /// Compute a draw for a specific dose using the compound's default BAC
    /// water + suggested vial size.
    func defaultDraw(forMcg mcg: Double, vialMg: Double? = nil) -> SyringeMath.Draw {
        let s = bacSuggestion(forVialMg: vialMg)
        return SyringeMath.draw(mcg: mcg, mcgPerUnit: s.mcgPerUnit)
    }
}
