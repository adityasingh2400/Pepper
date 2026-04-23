import XCTest
@testable import Peptide

final class VoiceIntentTests: XCTestCase {

    func test_open_today_tab_variants() {
        for phrase in ["go to today", "Today screen please", "open today", "show today"] {
            let intent = VoiceIntent.detect(in: phrase)
            XCTAssertEqual(intent, .openTab(.today), "phrase: \(phrase)")
        }
    }

    func test_open_research_tab() {
        let intent = VoiceIntent.detect(in: "research")
        XCTAssertEqual(intent, .openTab(.research))
    }

    func test_open_protocol_tab() {
        let intent = VoiceIntent.detect(in: "open my protocol")
        XCTAssertEqual(intent, .openTab(.protocol))
    }

    func test_log_dose_intent() {
        let intent = VoiceIntent.detect(in: "log a dose")
        XCTAssertEqual(intent, .logDose)
    }

    func test_compound_lookup_routes_to_open_compound() {
        let intent = VoiceIntent.detect(in: "show me BPC-157")
        if case let .openCompound(c) = intent {
            XCTAssertEqual(c.name, "BPC-157")
        } else {
            XCTFail("expected openCompound, got \(intent)")
        }
    }

    func test_calculator_for_compound() {
        let intent = VoiceIntent.detect(in: "calculator for tirzepatide")
        if case let .openDosingCalculator(c) = intent {
            XCTAssertTrue(c.name.lowercased().contains("tirzepatide"))
        } else {
            XCTFail("expected openDosingCalculator, got \(intent)")
        }
    }

    func test_pinning_protocol_for_compound() {
        let intent = VoiceIntent.detect(in: "how do I pin BPC-157")
        if case let .openPinningProtocol(c) = intent {
            XCTAssertEqual(c.name, "BPC-157")
        } else {
            XCTFail("expected openPinningProtocol, got \(intent)")
        }
    }

    func test_unknown_text_routes_to_pepper() {
        let intent = VoiceIntent.detect(in: "what's the weather like")
        if case .askPepper = intent {
            // pass
        } else {
            XCTFail("expected askPepper, got \(intent)")
        }
    }

    func test_empty_transcript_is_unknown() {
        let intent = VoiceIntent.detect(in: "   ")
        if case .unknown = intent {
            // pass
        } else {
            XCTFail("expected unknown, got \(intent)")
        }
    }
}
