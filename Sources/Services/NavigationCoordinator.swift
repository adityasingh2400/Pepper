import SwiftUI

/// Single source of truth for "where the user is in the app".
///
/// Drives `MainTabView`'s tab selection, lets PepperService and the voice
/// navigator deep-link into specific compounds or sheets without weaving
/// state through 6 levels of view modifiers.
///
/// Public surface:
///   - `selectedTab` — current bottom tab (0…4, see `Tab`)
///   - `openCompound(_:)` — push a compound detail when leaving the user on Research
///   - `presentDosingCalculator(for:)` — pop the calculator sheet for a compound
///   - `presentPinningProtocol(for:)` — pop the pinning sheet for a compound
///   - `presentInjectionTracker()` — open the 3D injection site tracker
///   - `presentVoiceNavigator()` — open the floating voice navigator overlay
@MainActor
final class NavigationCoordinator: ObservableObject {

    enum Tab: Int, CaseIterable {
        case today = 0
        case food = 1
        case `protocol` = 2  // Stays "protocol" internally for compat;
                              // user-facing label is "Stack" (see `title`).
        case track = 3
        case research = 4

        var systemImage: String {
            switch self {
            case .today:    return "house.fill"
            case .food:     return "fork.knife"
            case .protocol: return "drop.fill"
            case .track:    return "figure.strengthtraining.traditional"
            case .research: return "books.vertical.fill"
            }
        }

        var title: String {
            switch self {
            case .today:    return "Today"
            case .food:     return "Food"
            case .protocol: return "Stack"
            case .track:    return "Track"
            case .research: return "Research"
            }
        }
    }

    @Published var selectedTab: Tab = .today

    /// When set, the Research tab will push this compound's detail view.
    @Published var researchPushedCompound: Compound? = nil

    /// Voice-driven deep-link breadcrumb. When non-nil, the Research tab
    /// drives a **visible walkthrough**: family hub → family list → compound
    /// detail (each step animated + spotlit), so the user sees the
    /// hierarchy Pepper navigated through.
    @Published var researchWalkthrough: ResearchWalkthrough? = nil

    /// The currently-highlighted family card / compound row, driven by the
    /// walkthrough. Separate from `PepperSpotlight.activeAnchorId` because
    /// the research walkthrough lives on its own fast cadence (250 ms hop
    /// per step) and shouldn't fight the slower Pepper spotlight timeouts.
    @Published var researchSpotlightId: String? = nil

    /// Follow-up action to run after the walkthrough reaches the compound
    /// detail — e.g. auto-open the dosing calculator sheet. Cleared when
    /// consumed so it doesn't re-fire on the next nav.
    @Published var researchTrailingAction: VoiceAction? = nil

    /// Sheet presentations driven from the voice navigator.
    @Published var dosingCalculatorCompound: Compound? = nil
    @Published var pinningProtocolCompound: Compound? = nil
    @Published var showInjectionTracker = false

    /// Voice navigator overlay visibility.
    @Published var showVoiceNavigator = false

    /// Pepper assistant visibility.
    @Published var showPepper = false

    /// Quick-log dose sheet driven by voice.
    @Published var showQuickDoseLog = false

    // MARK: - High-level actions

    func switchTab(_ tab: Tab) {
        if selectedTab != tab {
            selectedTab = tab
            Analytics.capture(.tabViewed, properties: ["tab": tab.title.lowercased()])
        }
    }

    func openCompound(_ compound: Compound) {
        switchTab(.research)
        researchPushedCompound = compound
    }

    /// Voice entry point — drive the Research tab through a visible
    /// umbrella → compound walkthrough. Fast (~500 ms total) but animated
    /// so the user sees the hierarchy. When `trailingAction` is provided
    /// (dosing calc / pinning protocol / research node), it's fired after
    /// the detail view appears.
    func voiceOpenCompound(_ compound: Compound, action: VoiceAction) {
        switchTab(.research)
        researchWalkthrough = ResearchWalkthrough(compound: compound)
        researchTrailingAction = action

        let walkthrough = researchWalkthrough
        // Stage 1 (immediate): highlight the umbrella card.
        let familyId = ResearchSpotlight.family(walkthrough!.primaryFamily)
        researchSpotlightId = familyId
        spotlight?.highlight(familyId, duration: 0.6)

        // Stage 2 (≈220 ms): push the family list; highlight the row.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
            guard let self, self.researchWalkthrough?.id == walkthrough?.id else { return }
            self.researchWalkthrough?.stage = .familyList
            let rowId = ResearchSpotlight.compoundRow(compound)
            self.researchSpotlightId = rowId
            self.spotlight?.highlight(rowId, duration: 0.7)
        }

        // Stage 3 (≈460 ms): push compound detail.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) { [weak self] in
            guard let self, self.researchWalkthrough?.id == walkthrough?.id else { return }
            self.researchWalkthrough?.stage = .detail
            self.researchPushedCompound = compound
            // Trailing action spotlight — shown once the detail has rendered.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
                self?.applyTrailingAction(for: compound)
            }
        }

        // Stage 4 (≈1.4 s): clear the walkthrough spotlight so it doesn't
        // over-linger. The user has arrived; the ring has done its job.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self, self.researchWalkthrough?.id == walkthrough?.id else { return }
            self.researchSpotlightId = nil
        }
    }

    private func applyTrailingAction(for compound: Compound) {
        guard let action = researchTrailingAction else { return }
        researchTrailingAction = nil
        switch action {
        case .openCompoundDetail:
            break
        case .openDosingCalculator:
            researchSpotlightId = "compound.action.dosing"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                self?.dosingCalculatorCompound = compound
            }
        case .openPinningProtocol:
            researchSpotlightId = "compound.action.pinning"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                self?.pinningProtocolCompound = compound
            }
        case .viewResearch:
            // Already on the detail page — highlight the "How It Works" node.
            researchSpotlightId = "compound.node.mechanism"
        }
        // Whatever we just highlighted, also forward to the global spotlight
        // overlay so `PepperSpotlightOverlay` draws its ring in the root
        // coordinate space.
        if let id = researchSpotlightId, let s = spotlight {
            s.highlight(id, duration: 2.5)
        }
    }

    /// Weak ref, set by `MainTabView` at launch. Lets walkthrough steps
    /// light up the shared PepperSpotlight overlay without threading a
    /// second environment object through every view.
    weak var spotlight: PepperSpotlight?

    func presentDosingCalculator(for compound: Compound) {
        dosingCalculatorCompound = compound
    }

    func presentPinningProtocol(for compound: Compound) {
        pinningProtocolCompound = compound
    }

    func presentInjectionTracker() {
        switchTab(.protocol)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.showInjectionTracker = true
        }
    }

    func presentVoiceNavigator() {
        showVoiceNavigator = true
    }

    func dismissVoiceNavigator() {
        showVoiceNavigator = false
    }

    func presentPepper() {
        showPepper = true
    }

    func presentQuickDoseLog() {
        switchTab(.today)
        showQuickDoseLog = true
    }
}

/// Breadcrumb the Research tab follows when voice drives a deep-link so
/// the user sees the umbrella → sub → compound hierarchy instead of being
/// teleported straight to the detail page.
struct ResearchWalkthrough: Equatable {
    enum Stage: Equatable { case familyHub, familyList, detail }

    let id: UUID
    let compound: Compound
    let primaryFamily: ResearchFamily
    var stage: Stage

    init(compound: Compound) {
        self.id = UUID()
        self.compound = compound
        self.primaryFamily = ResearchFamily.families(for: compound).first ?? .other
        self.stage = .familyHub
    }
}

/// Canonical spotlight anchor IDs for the research walkthrough. Keeps
/// string keys centralised so the coordinator, family cards, compound
/// rows, and overlay stay in sync.
enum ResearchSpotlight {
    static func family(_ family: ResearchFamily) -> String {
        "research.family.\(family.rawValue)"
    }
    static func compoundRow(_ compound: Compound) -> String {
        "research.compound.\(compound.slug.lowercased())"
    }
}
