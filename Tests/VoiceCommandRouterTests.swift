import XCTest
@testable import Peptide

/// Tests the new zero-network voice routing layer that powers the
/// sub-second voice navigator. These tests lock in the confidence scores
/// because the VoiceNavigatorView's early-fire behavior depends on them:
/// drift here → navigator fires too late (regression) or fires on
/// ambiguous fragments (spammy).
final class VoiceCommandRouterTests: XCTestCase {

    // MARK: - Tab routing

    @MainActor
    func test_open_research_tab_fires_immediately() {
        let cmd = VoiceCommandRouter.route("open research")
        XCTAssertNotNil(cmd)
        guard let cmd else { return }
        if case .openTab(let tab) = cmd.kind {
            XCTAssertEqual(tab, .research)
        } else {
            XCTFail("expected openTab(.research), got \(cmd.kind)")
        }
        XCTAssertGreaterThanOrEqual(cmd.confidence, 0.9, "explicit verb + tab must fire immediately")
        XCTAssertTrue(cmd.isNavigational)
    }

    @MainActor
    func test_bare_tab_name_uses_medium_confidence() {
        // "research" alone should route, but with lower confidence so we
        // give the user 300 ms to continue (e.g. "research on BPC-157").
        let cmd = VoiceCommandRouter.route("research")
        XCTAssertNotNil(cmd)
        XCTAssertLessThan(cmd!.confidence, 0.9)
        XCTAssertGreaterThanOrEqual(cmd!.confidence, 0.8)
    }

    @MainActor
    func test_all_tabs_route() {
        let cases: [(String, NavigationCoordinator.Tab)] = [
            ("go to today", .today),
            ("open food", .food),
            ("open stack", .protocol),
            ("go to protocol", .protocol),
            ("open track", .track),
            ("show research", .research)
        ]
        for (phrase, tab) in cases {
            guard let cmd = VoiceCommandRouter.route(phrase) else {
                XCTFail("no route for \(phrase)"); continue
            }
            if case .openTab(let t) = cmd.kind {
                XCTAssertEqual(t, tab, "phrase: \(phrase)")
            } else {
                XCTFail("expected tab for \(phrase), got \(cmd.kind)")
            }
        }
    }

    // MARK: - Compound + action composition

    @MainActor
    func test_research_on_compound_routes_with_viewResearch_action() {
        let cmd = VoiceCommandRouter.route("show me the research on BPC 157")
        XCTAssertNotNil(cmd)
        guard case .openCompound(let compound, let action) = cmd?.kind else {
            return XCTFail("expected openCompound, got \(String(describing: cmd?.kind))")
        }
        XCTAssertEqual(compound.name, "BPC-157")
        XCTAssertEqual(action, .viewResearch)
    }

    @MainActor
    func test_dosing_calc_for_compound() {
        let cmd = VoiceCommandRouter.route("calculator for tirzepatide")
        guard case .openCompound(let compound, let action) = cmd?.kind else {
            return XCTFail("expected openCompound")
        }
        XCTAssertTrue(compound.name.lowercased().contains("tirzepatide"))
        XCTAssertEqual(action, .openDosingCalculator)
    }

    @MainActor
    func test_pinning_for_compound() {
        let cmd = VoiceCommandRouter.route("how do I inject semaglutide")
        guard case .openCompound(let compound, let action) = cmd?.kind else {
            return XCTFail("expected openCompound")
        }
        XCTAssertTrue(compound.name.lowercased().contains("semaglutide"))
        XCTAssertEqual(action, .openPinningProtocol)
    }

    @MainActor
    func test_bare_compound_gets_default_detail_action() {
        let cmd = VoiceCommandRouter.route("BPC-157")
        guard case .openCompound(_, let action) = cmd?.kind else {
            return XCTFail("expected openCompound")
        }
        XCTAssertEqual(action, .openCompoundDetail)
    }

    // MARK: - Injection tracker & log dose

    @MainActor
    func test_injection_tracker_variants() {
        for phrase in ["injection site tracker", "site tracker", "where do I inject", "body map"] {
            let cmd = VoiceCommandRouter.route(phrase)
            XCTAssertEqual(cmd?.kind, .openInjectionTracker, "phrase: \(phrase)")
        }
    }

    @MainActor
    func test_log_dose_variants() {
        for phrase in ["log a dose", "log my injection", "I just dosed"] {
            let cmd = VoiceCommandRouter.route(phrase)
            XCTAssertEqual(cmd?.kind, .logDose, "phrase: \(phrase)")
        }
    }

    // MARK: - Ask-Pepper fallback

    @MainActor
    func test_open_ended_question_falls_through_to_pepper() {
        let cmd = VoiceCommandRouter.route("what is the half life of a peptide")
        guard case .askPepper = cmd?.kind else {
            return XCTFail("expected askPepper")
        }
        XCTAssertLessThan(cmd!.confidence, 0.9, "Pepper fallback should never be high-confidence")
    }

    @MainActor
    func test_one_word_unknown_returns_nil_not_askpepper() {
        // "hello" shouldn't fire anything — we keep listening.
        XCTAssertNil(VoiceCommandRouter.route("hello"))
    }

    @MainActor
    func test_bare_compound_does_not_fire_immediately() {
        // Single compound mention must use medium confidence so we give the
        // user room to append ("BPC-157... dosing"). Would-be regression:
        // firing at 0.95 would teleport the user before they finish speaking.
        let cmd = VoiceCommandRouter.route("BPC-157")
        XCTAssertNotNil(cmd)
        XCTAssertLessThan(cmd!.confidence, 0.9)
    }

    // MARK: - Ambiguity chooser

    @MainActor
    func test_bare_cjc_triggers_disambiguation() {
        let cmd = VoiceCommandRouter.route("show me the research on cjc")
        XCTAssertNotNil(cmd)
        guard case .disambiguate(let group, let action) = cmd?.kind else {
            return XCTFail("expected disambiguate, got \(String(describing: cmd?.kind))")
        }
        XCTAssertEqual(group.id, "cjc")
        XCTAssertEqual(action, .viewResearch)
        // All three real variants must be there.
        let ids = Set(group.options.map { $0.id })
        XCTAssertTrue(ids.contains("cjc-1295"))
        XCTAssertTrue(ids.contains("cjc-1295-no-dac"))
        XCTAssertTrue(ids.contains("cjc-ipa-blend"))
    }

    @MainActor
    func test_cjc_no_dac_resolves_directly_not_chooser() {
        // Disambiguator word present → no chooser, direct compound route.
        let cmd = VoiceCommandRouter.route("open cjc no dac")
        guard case .openCompound(let compound, _) = cmd?.kind else {
            return XCTFail("expected direct openCompound, got \(String(describing: cmd?.kind))")
        }
        XCTAssertEqual(compound.name, "CJC-1295 No DAC")
    }

    @MainActor
    func test_cjc_1295_resolves_directly_not_chooser() {
        let cmd = VoiceCommandRouter.route("show me cjc 1295")
        guard case .openCompound(let compound, _) = cmd?.kind else {
            return XCTFail("expected direct openCompound, got \(String(describing: cmd?.kind))")
        }
        XCTAssertEqual(compound.name, "CJC-1295")
    }

    @MainActor
    func test_melanotan_triggers_disambiguation() {
        let cmd = VoiceCommandRouter.route("tell me about melanotan")
        guard case .disambiguate(let group, _) = cmd?.kind else {
            return XCTFail("expected disambiguate")
        }
        XCTAssertEqual(group.id, "melanotan")
        XCTAssertEqual(group.options.count, 2)
    }

    @MainActor
    func test_melanotan_ii_resolves_directly() {
        let cmd = VoiceCommandRouter.route("melanotan 2")
        guard case .openCompound(let compound, _) = cmd?.kind else {
            return XCTFail("expected direct openCompound")
        }
        XCTAssertEqual(compound.name, "Melanotan II")
    }

    @MainActor
    func test_ghrp_triggers_disambiguation() {
        let cmd = VoiceCommandRouter.route("ghrp dosing")
        guard case .disambiguate(let group, let action) = cmd?.kind else {
            return XCTFail("expected disambiguate")
        }
        XCTAssertEqual(group.id, "ghrp")
        XCTAssertEqual(action, .openDosingCalculator)
    }

    @MainActor
    func test_ghrp_2_resolves_directly() {
        let cmd = VoiceCommandRouter.route("ghrp 2 dosing")
        guard case .openCompound(let compound, _) = cmd?.kind else {
            return XCTFail("expected direct openCompound")
        }
        XCTAssertEqual(compound.name, "GHRP-2")
    }

    @MainActor
    func test_igf_triggers_disambiguation() {
        let cmd = VoiceCommandRouter.route("research on igf")
        guard case .disambiguate(let group, _) = cmd?.kind else {
            return XCTFail("expected disambiguate, got \(String(describing: cmd?.kind))")
        }
        XCTAssertEqual(group.id, "igf")
    }

    @MainActor
    func test_igf_lr3_resolves_directly() {
        let cmd = VoiceCommandRouter.route("igf 1 lr3")
        guard case .openCompound(let compound, _) = cmd?.kind else {
            return XCTFail("expected direct openCompound")
        }
        XCTAssertEqual(compound.name, "IGF-1 LR3")
    }

    @MainActor
    func test_disambiguate_preserves_action_context() {
        // The chooser only picks WHICH compound, not WHAT to do with it.
        // "how do I inject cjc" → chooser for CJC, action = pinning.
        let cmd = VoiceCommandRouter.route("how do I inject cjc")
        guard case .disambiguate(_, let action) = cmd?.kind else {
            return XCTFail("expected disambiguate")
        }
        XCTAssertEqual(action, .openPinningProtocol)
    }

    @MainActor
    func test_ambiguity_groups_are_navigational() {
        // So `executeNavCommand` skips the Claude round-trip and goes
        // straight to the chooser UI.
        let cmd = VoiceCommandRouter.route("cjc")
        XCTAssertTrue(cmd?.isNavigational ?? false)
    }
}
