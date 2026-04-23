import Foundation

// Reconstitution + storage protocol for a peptide vial.
// Inputs: total mg powder in vial + bac water mL added.
// Outputs: concentration per "unit" (insulin-syringe tick = 0.01 mL),
// usable shelf life, and a recommended draw volume for a target dose.
struct BACProtocol: Equatable, Hashable {
    let totalMg: Double         // dry mg in the vial
    let bacWaterMl: Double      // reconstitution volume
    let storageTemp: String     // "refrigerated" | "frozen" | "room"
    let storageMaxDays: Int

    // Concentration in mcg per insulin-syringe unit (1 unit = 0.01 mL).
    var mcgPerUnit: Double {
        guard bacWaterMl > 0 else { return 0 }
        return (totalMg * 1_000.0) / (bacWaterMl * 100.0)
    }

    // Concentration in mcg per mL.
    var mcgPerMl: Double {
        guard bacWaterMl > 0 else { return 0 }
        return (totalMg * 1_000.0) / bacWaterMl
    }

    // Returns the units (insulin-syringe ticks) required to draw `mcg`.
    func unitsForDose(mcg: Double) -> Double {
        guard mcgPerUnit > 0 else { return 0 }
        return mcg / mcgPerUnit
    }

    // Returns the mL volume required to draw `mcg`.
    func mlForDose(mcg: Double) -> Double {
        guard mcgPerMl > 0 else { return 0 }
        return mcg / mcgPerMl
    }

    // Friendly storage line (e.g. "Refrigerated, up to 30 days")
    var storageLine: String {
        let temp = storageTemp.capitalized
        return "\(temp), up to \(storageMaxDays) days"
    }
}

extension Compound {
    func suggestedBAC() -> BACProtocol {
        BACProtocol(
            totalMg:        suggestedVialMg,
            bacWaterMl:     bacWaterMlDefault ?? 2.0,
            storageTemp:    storageTemp ?? "refrigerated",
            storageMaxDays: storageMaxDays ?? 30
        )
    }

    // Heuristic: assume the cheapest common vial size ≥ a single full dose × 7.
    var suggestedVialMg: Double {
        // Default to 5 mg (typical for BPC, GH peptides). GLP-1s vary.
        if let high = dosingRangeHighMcg {
            // weeklyMcg = high (single) ; cycle ~4 weeks ; pad 25%
            let monthly = high * 28
            let mg = monthly / 1_000.0
            return max(2, ceil(mg))
        }
        return 5.0
    }
}
