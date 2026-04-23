import XCTest
@testable import Peptide

final class DosingFormulaTests: XCTestCase {

    func test_simple_arithmetic() throws {
        let f = DosingFormula(expression: "weightKg * 0.5")
        let r = try f.evaluate(with: .init(weightKg: 80))
        XCTAssertEqual(r, 40, accuracy: 0.0001)
    }

    func test_clamp_function() throws {
        let f = DosingFormula(expression: "clamp(weightKg * 2, 100, 250)")
        let low  = try f.evaluate(with: .init(weightKg: 30))   // 60 → 100
        let mid  = try f.evaluate(with: .init(weightKg: 80))   // 160 → 160
        let high = try f.evaluate(with: .init(weightKg: 200))  // 400 → 250

        XCTAssertEqual(low,  100, accuracy: 0.0001)
        XCTAssertEqual(mid,  160, accuracy: 0.0001)
        XCTAssertEqual(high, 250, accuracy: 0.0001)
    }

    func test_min_max_functions() throws {
        let fmin = DosingFormula(expression: "min(100, weightKg)")
        XCTAssertEqual(try fmin.evaluate(with: .init(weightKg: 80)), 80, accuracy: 0.0001)

        let fmax = DosingFormula(expression: "max(weightKg * 0.5, 50)")
        XCTAssertEqual(try fmax.evaluate(with: .init(weightKg: 80)),  50, accuracy: 0.0001)
        XCTAssertEqual(try fmax.evaluate(with: .init(weightKg: 200)), 100, accuracy: 0.0001)
    }

    func test_division_by_zero_throws() {
        let f = DosingFormula(expression: "weightKg / 0")
        XCTAssertThrowsError(try f.evaluate(with: .init(weightKg: 80)))
    }

    func test_unknown_identifier_throws() {
        let f = DosingFormula(expression: "wat * 2")
        XCTAssertThrowsError(try f.evaluate(with: .init(weightKg: 80)))
    }

    func test_parens_precedence() throws {
        let f = DosingFormula(expression: "(weightKg + 10) * 2")
        let r = try f.evaluate(with: .init(weightKg: 80))
        XCTAssertEqual(r, 180, accuracy: 0.0001)
    }
}
