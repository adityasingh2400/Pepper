import XCTest
@testable import Peptide

final class SyringeMathTests: XCTestCase {

    // MARK: - suggest()

    func test_suggest_5mgVial_BPC_picks_smallest_comfortable() {
        // BPC-157: 200–500 mcg, 5 mg vial.
        // 1 mL → 50 mcg/u, low=4u (FAIL <5)
        // 1.5 mL → 33.33 mcg/u, low=6u (PASS), high=15u (PASS) — first comfortable wins
        let s = SyringeMath.suggest(totalMg: 5, lowDoseMcg: 200, highDoseMcg: 500)
        XCTAssertEqual(s.bacWaterMl, 1.5, accuracy: 0.001)
        XCTAssertEqual(s.mcgPerUnit, 33.333, accuracy: 0.01)
        XCTAssertEqual(s.unitsForLowDose, 6, accuracy: 0.01)
        XCTAssertEqual(s.unitsForHighDose, 15, accuracy: 0.01)
        XCTAssertTrue(s.comfortable)
        XCTAssertFalse(s.rationale.isEmpty)
    }

    func test_suggest_10mgVial_GH_peptide_picks_smallest_comfortable_water() {
        // CJC/Ipa: 100–300 mcg, 10 mg vial.
        // We expect the smallest water that lands both in [5, 95].
        // 1 mL → 100 mcg/unit. low=1u (FAIL <5).
        // 1.5 mL → 66.67 mcg/unit. low=1.5u (FAIL).
        // 2 mL → 50 mcg/unit. low=2u (FAIL).
        // 2.5 mL → 40 mcg/unit. low=2.5u (FAIL).
        // 3 mL → 33.33 mcg/unit. low=3u (FAIL).
        // 4 mL → 25 mcg/unit. low=4u (FAIL).
        // 5 mL → 20 mcg/unit. low=5u (PASS). high=15u (PASS).
        let s = SyringeMath.suggest(totalMg: 10, lowDoseMcg: 100, highDoseMcg: 300)
        XCTAssertEqual(s.bacWaterMl, 5.0, accuracy: 0.001)
        XCTAssertTrue(s.comfortable)
    }

    func test_suggest_falls_back_when_nothing_comfortable() {
        // Tiny doses against a tiny vial: nothing fits; we still get the best try.
        let s = SyringeMath.suggest(totalMg: 1, lowDoseMcg: 5, highDoseMcg: 10)
        XCTAssertNotNil(s.bacWaterMl)
        XCTAssertGreaterThan(s.mcgPerUnit, 0)
    }

    // MARK: - draw()

    func test_draw_basic_dose() {
        // 250 mcg at 25 mcg/unit = 10 units = 0.10 mL
        let d = SyringeMath.draw(mcg: 250, mcgPerUnit: 25)
        XCTAssertEqual(d.units, 10, accuracy: 0.001)
        XCTAssertEqual(d.unitsRounded, 10, accuracy: 0.001)
        XCTAssertEqual(d.mL, 0.10, accuracy: 0.0001)
        XCTAssertFalse(d.isOutOfRange)
        XCTAssertEqual(d.unitsLabel, "10 units")
    }

    func test_draw_rounds_to_half_unit() {
        // 240 mcg at 25 mcg/unit = 9.6 units → rounds to 9.5
        let d = SyringeMath.draw(mcg: 240, mcgPerUnit: 25)
        XCTAssertEqual(d.units, 9.6, accuracy: 0.001)
        XCTAssertEqual(d.unitsRounded, 9.5, accuracy: 0.001)
        XCTAssertEqual(d.unitsLabel, "9.5 units")
    }

    func test_draw_out_of_range_flagged_when_too_small() {
        // 5 mcg at 100 mcg/unit = 0.05 units → rounds up to 0.5, still <1 unit → out of range.
        let d = SyringeMath.draw(mcg: 5, mcgPerUnit: 100)
        XCTAssertTrue(d.isOutOfRange)
    }

    func test_draw_out_of_range_flagged_when_too_large() {
        // 5000 mcg at 25 mcg/unit = 200 units → > 100 unit syringe.
        let d = SyringeMath.draw(mcg: 5000, mcgPerUnit: 25)
        XCTAssertTrue(d.isOutOfRange)
    }

    // MARK: - roundUnitsToHalf()

    func test_roundUnitsToHalf_clamps_low() {
        XCTAssertEqual(SyringeMath.roundUnitsToHalf(0.1), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SyringeMath.roundUnitsToHalf(0), 0, accuracy: 0.0001)
    }

    func test_roundUnitsToHalf_rounds_correctly() {
        XCTAssertEqual(SyringeMath.roundUnitsToHalf(9.74), 9.5, accuracy: 0.0001)
        XCTAssertEqual(SyringeMath.roundUnitsToHalf(9.76), 10, accuracy: 0.0001)
        XCTAssertEqual(SyringeMath.roundUnitsToHalf(12.5), 12.5, accuracy: 0.0001)
    }

    // MARK: - Compound convenience

    func test_compound_extension_uses_dosing_range() {
        let bpc = Compound(
            name: "BPC-157",
            slug: "bpc-157",
            dosingRangeLowMcg: 200,
            dosingRangeHighMcg: 500
        )
        let s = bpc.bacSuggestion(forVialMg: 5)
        // 1.5 mL is the smallest comfortable for 200–500 mcg / 5 mg.
        XCTAssertEqual(s.bacWaterMl, 1.5, accuracy: 0.001)
        XCTAssertTrue(s.comfortable)

        // 250 mcg at 33.33 mcg/u = 7.5u, rounds to 7.5 (already on the half).
        let d = bpc.defaultDraw(forMcg: 250, vialMg: 5)
        XCTAssertEqual(d.unitsRounded, 7.5, accuracy: 0.001)
    }
}
