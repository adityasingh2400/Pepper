import Foundation

/// Deterministic, zero-network voice command router.
///
/// Upgrades `VoiceIntent` with compound + action composition and confidence
/// scoring so `VoiceNavigatorView` can:
///
///   1. Fire the moment a partial transcript resolves a **high-confidence**
///      intent — no more 1.1-second silence wait.
///   2. Skip the Claude round-trip entirely for any navigational command
///      (which is ~90 % of voice traffic). Only truly open-ended questions
///      ("what's the half-life of tirz?") fall through to Pepper.
///
/// The router is pure: no side effects, no IO, no async. Call it from any
/// actor. ~1 ms on a real phone.
enum VoiceAction: Equatable {
    case openCompoundDetail        // "show me BPC-157"
    case openDosingCalculator      // "dosing calc for BPC-157"
    case openPinningProtocol       // "how do I inject tirzepatide"
    case viewResearch              // "research on BPC-157"
}

/// A fully-resolved voice command — richer than the legacy `VoiceIntent`
/// because it also carries the target compound (when relevant) and a
/// confidence score so the navigator knows when it's safe to fire early.
struct VoiceCommand: Equatable {
    enum Kind: Equatable {
        case openTab(NavigationCoordinator.Tab)
        case openCompound(Compound, action: VoiceAction)
        /// Transcript names a family of variants ("cjc", "melanotan",
        /// "ghrp") without a disambiguator. Surface all variants as
        /// pop-out choices; user taps the one they meant.
        case disambiguate(DisambiguationGroup, action: VoiceAction)
        case openInjectionTracker
        case logDose
        case askPepper(String)
        case unknown
    }

    let kind: Kind
    /// 0...1. ≥0.9 means "fire immediately on partial transcript".
    /// 0.6...0.9 = "fire after short dwell (≈250 ms)". <0.6 = wait for the
    /// full submit path.
    let confidence: Double
    /// Short (<80 char) spoken confirmation. Matches the prerecorded-audio
    /// phrase catalog so playback can be instant.
    let spokenConfirmation: String
    /// Original raw transcript — kept for analytics + Pepper fallback.
    let rawTranscript: String

    var isHighConfidence: Bool { confidence >= 0.9 }
    var isNavigational: Bool {
        switch kind {
        case .openTab, .openCompound, .openInjectionTracker, .logDose, .disambiguate: return true
        case .askPepper, .unknown: return false
        }
    }
}

/// A cluster of real compound variants that share a bare acronym / stem.
/// When the user says just the stem ("cjc", "melanotan") we surface every
/// option as a chooser bubble rather than picking one at random.
///
/// Keep these hand-curated — automatic alias-collision detection would
/// include every mishearing ("amarillo" is an alias of Ipamorelin, not a
/// real variant). The point is presenting *meaningful choices to the user*,
/// not just collisions in the lookup table.
struct DisambiguationGroup: Equatable, Identifiable {
    let id: String           // stable key used for analytics + state
    let title: String        // "CJC Variants" — shown above the bubbles
    let options: [Option]

    struct Option: Equatable, Identifiable {
        let id: String
        /// Short label for the bubble ("CJC-1295", "No DAC", "+ Ipa Blend").
        let label: String
        /// One-line subtitle the bubble shows underneath the label.
        let subtitle: String
        /// What to do when the user taps this bubble. The action carries
        /// through whatever the original transcript asked for (dosing,
        /// pinning, research) — the chooser only disambiguates *which*
        /// compound, not *what* to do with it.
        let resolution: Resolution
    }

    enum Resolution: Equatable {
        /// Pick a single compound and hand off to the normal walkthrough.
        case compound(Compound)
        /// A blend (e.g. "CJC-1295 + Ipamorelin") — we open the first
        /// member's detail page since we don't have a blend-detail page
        /// (matches existing `CompoundCatalog.blendDisplaySeparator` convention).
        case blend(primary: Compound, display: String)
    }
}

enum VoiceCommandRouter {

    /// Resolve a transcript (partial or final) into a `VoiceCommand`.
    /// Returns `nil` when the transcript is too short/ambiguous to route
    /// yet — the caller should keep waiting.
    static func route(_ transcript: String) -> VoiceCommand? {
        let raw = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, raw.count >= 2 else { return nil }
        let lower = raw.lowercased()

        // ── Tab-only nav (highest confidence) ─────────────────────────────
        // Short phrases like "research" or "research tab" should fire the
        // instant the recognizer emits them — no dwell needed.
        if let tab = matchTab(lower) {
            return VoiceCommand(
                kind: .openTab(tab),
                confidence: confidenceForTabPhrase(lower, tab: tab),
                spokenConfirmation: PrerecordedAudioCache.phraseForTab(tab),
                rawTranscript: raw
            )
        }

        // ── Logging + injection tracker ───────────────────────────────────
        if matchesAny(lower, [
            "log a dose", "log dose", "i just dosed", "log my pin",
            "log my injection", "log injection", "quick log"
        ]) {
            return VoiceCommand(
                kind: .logDose,
                confidence: 0.95,
                spokenConfirmation: "Logging a dose.",
                rawTranscript: raw
            )
        }
        if matchesAny(lower, [
            "injection site tracker", "site tracker", "where do i inject",
            "injection tracker", "site rotation", "where should i inject",
            "body map", "injection map"
        ]) {
            return VoiceCommand(
                kind: .openInjectionTracker,
                confidence: 0.95,
                spokenConfirmation: "Opening the injection tracker.",
                rawTranscript: raw
            )
        }

        // ── Compound + optional action ────────────────────────────────────
        // We split the detection so phrases like "research bpc 157", "dose
        // calc for tirz", or "how do I inject sema" all route without Claude.
        //
        // Ambiguity guard runs BEFORE the single-compound match: if the
        // transcript names a bare stem from a known group (e.g. "cjc",
        // "melanotan") without a disambiguator, surface the chooser
        // instead of picking one at random.
        if let group = detectAmbiguityGroup(in: lower) {
            let action = detectAction(in: lower)
            return VoiceCommand(
                kind: .disambiguate(group, action: action),
                confidence: 0.95,
                spokenConfirmation: "Which one?",
                rawTranscript: raw
            )
        }

        if let compound = resolveCompound(in: lower) {
            let action = detectAction(in: lower)
            let conf = confidenceForCompoundPhrase(lower, compound: compound, action: action)
            return VoiceCommand(
                kind: .openCompound(compound, action: action),
                confidence: conf,
                spokenConfirmation: spokenPhrase(for: action, compound: compound),
                rawTranscript: raw
            )
        }

        // ── Open-ended Q&A — hand to Pepper ───────────────────────────────
        // Only route to Pepper when the transcript looks like a real
        // question (ends with "?", or starts with "what/why/how/when/is/are
        // /should/can"). Anything shorter keeps listening.
        if looksLikeQuestion(lower) && raw.count >= 6 {
            return VoiceCommand(
                kind: .askPepper(raw),
                confidence: 0.5,
                spokenConfirmation: "Let me think about that.",
                rawTranscript: raw
            )
        }

        return nil
    }

    // MARK: - Tab matching

    private static func matchTab(_ lower: String) -> NavigationCoordinator.Tab? {
        // Check most-specific phrases first.
        if matchesAny(lower, ["go to today", "open today", "show today", "home tab"]) { return .today }
        if matchesAny(lower, ["go to food", "open food", "show food", "food tab", "log food", "meals", "nutrition", "macros"]) { return .food }
        if matchesAny(lower, ["go to protocol", "go to stack", "open protocol", "open stack", "my protocol", "my stack", "protocol tab", "stack tab", "vials"]) { return .protocol }
        if matchesAny(lower, ["go to track", "open track", "show track", "track tab", "tracking", "stats", "progress", "workout", "workouts"]) { return .track }
        if matchesAny(lower, ["go to research", "open research", "show research", "research tab", "library", "compounds list"]) { return .research }

        // Bare tab names: fall through to compound detection if the phrase
        // also names a compound or ambiguity stem. "research on cjc" and
        // "research on igf" mean "find this compound", not "open the
        // Research tab" — let the downstream handlers run instead of
        // eagerly teleporting to an empty tab.
        if phraseReferencesCompoundOrGroup(lower) { return nil }

        if matchesWord(lower, "today") && lower.count <= 16 { return .today }
        if matchesWord(lower, "food")  && lower.count <= 16 { return .food }
        if matchesWord(lower, "protocol") && lower.count <= 20 { return .protocol }
        if matchesWord(lower, "stack") && lower.count <= 20 { return .protocol }
        if matchesWord(lower, "track") && lower.count <= 16 { return .track }
        if matchesWord(lower, "research") && lower.count <= 20 { return .research }

        return nil
    }

    /// True if the transcript looks like it references a compound (exact or
    /// fuzzy via `CompoundCatalog.match`) or one of our ambiguity stems.
    /// Used as a guard so bare tab-word fast paths don't swallow phrases
    /// like "research on cjc" that are actually compound queries.
    private static func phraseReferencesCompoundOrGroup(_ lower: String) -> Bool {
        if !CompoundCatalog.match(in: lower).isEmpty { return true }
        for def in groups where def.triggerWords.contains(where: { matchesWord(lower, $0) }) {
            return true
        }
        return false
    }

    private static func confidenceForTabPhrase(_ lower: String, tab: NavigationCoordinator.Tab) -> Double {
        // "open research" or "go to food" = max confidence (verb + tab).
        if lower.hasPrefix("go to ") || lower.hasPrefix("open ") || lower.hasPrefix("show ") {
            return 0.98
        }
        // Bare tab name ("research") needs a tiny dwell since STT can
        // re-expand to "research on BPC-157" — downgrade confidence so we
        // wait ~300 ms before firing.
        if lower.split(separator: " ").count <= 2 {
            return 0.82
        }
        return 0.94
    }

    // MARK: - Action detection

    /// Detects what the user wants done with the named compound. Defaults to
    /// `.openCompoundDetail` when no action keyword is present.
    private static func detectAction(in lower: String) -> VoiceAction {
        if matchesAny(lower, [
            "calculator", "calculate", "calc", "dosing calc", "dose calc",
            "how much", "what dose", "how many units", "how many mcg",
            "what should my dose",
            // Bare "dosing" / "dose" as in "ghrp dosing", "tirz dose"
            "dosing", "my dose"
        ]) {
            return .openDosingCalculator
        }
        if matchesAny(lower, [
            "pinning protocol", "how do i inject", "how do i pin",
            "injection site for", "where do i pin", "how to inject",
            "pinning", "pin protocol"
        ]) {
            return .openPinningProtocol
        }
        if matchesAny(lower, [
            "research on", "research for", "research about",
            "studies on", "studies about", "science on",
            "tell me about", "info on", "info about", "what is",
            "show me research", "show research"
        ]) {
            return .viewResearch
        }
        return .openCompoundDetail
    }

    private static func confidenceForCompoundPhrase(_ lower: String, compound: Compound, action: VoiceAction) -> Double {
        // Strong: explicit verb + compound ("show me bpc 157", "dosing for tirz").
        let strongVerbs = ["show me", "open", "go to", "pull up", "research on", "research for", "dosing for", "calculator for", "how do i inject"]
        if strongVerbs.contains(where: { lower.contains($0) }) {
            return 0.95
        }
        // Bare compound name — fine but keep a short dwell in case user
        // continues ("BPC-157..." → "BPC-157 dosing").
        return 0.82
    }

    private static func spokenPhrase(for action: VoiceAction, compound: Compound) -> String {
        switch action {
        case .openCompoundDetail: return "Here's \(compound.name)."
        case .openDosingCalculator: return "Here's the dosing calculator."
        case .openPinningProtocol: return "Here's how to pin it."
        case .viewResearch: return "Here's the research."
        }
    }

    // MARK: - Helpers

    private static func looksLikeQuestion(_ lower: String) -> Bool {
        let starters = ["what", "why", "how", "when", "where", "is ", "are ", "should", "can ", "could ", "would ", "do i", "does "]
        if starters.contains(where: { lower.hasPrefix($0) }) { return true }
        if lower.hasSuffix("?") { return true }
        return false
    }

    private static func matchesAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains(where: { text.contains($0) })
    }

    private static func matchesWord(_ text: String, _ word: String) -> Bool {
        // \b boundary check so "track" matches "track"/"the track"/"track tab"
        // but not "tracking" or "racetrack".
        text.range(of: "\\b\(word)\\b", options: .regularExpression) != nil
    }

    // MARK: - Compound resolution

    /// Picks the single best-matching compound for the transcript.
    ///
    /// `CompoundCatalog.match` runs two passes (exact substring + fuzzy
    /// Levenshtein) and returns a Set — order is non-deterministic when
    /// multiple entries hit. That's fine for the compound picker UI which
    /// shows all of them, but a voice navigator needs a *single*
    /// deterministic answer or half the time "melanotan 2" navigates to
    /// Melanotan I.
    ///
    /// Tiebreak order (highest score wins):
    ///   1. Longer exact (word-boundary) alias match → the more specific
    ///      alias wins. "melanotan 2" contains both "melanotan" (alias of
    ///      MT2 only) and "melanotan 2" (alias of MT2 only) — MT2 wins
    ///      over any fuzzy MT1 hit because MT1 has no exact hit.
    ///   2. Higher popularity (lower `popularityRank`) breaks ties.
    private static func resolveCompound(in lower: String) -> Compound? {
        let hits = CompoundCatalog.match(in: lower)
        guard !hits.isEmpty else { return nil }
        guard hits.count > 1 else {
            return hits.first.flatMap(CompoundCatalog.compound)
        }

        let scored: [(compound: Compound, score: Int)] = hits.compactMap { name in
            guard let c = CompoundCatalog.compound(named: name),
                  let entry = CompoundCatalog.all.first(where: { $0.canonical == name }) else {
                return nil
            }
            let candidates = [entry.canonical.lowercased()] + entry.aliases.map { $0.lowercased() }
            let longest = candidates.compactMap { alias -> Int? in
                matchesWord(lower, alias) ? alias.count : nil
            }.max() ?? 0
            let popularityBoost: Int = {
                if let rank = c.popularityRank { return max(0, 100 - rank) }
                return 0
            }()
            return (c, longest * 1000 + popularityBoost)
        }

        return scored.max(by: { $0.score < $1.score })?.compound
    }

    // MARK: - Ambiguity detection

    /// Hand-curated ambiguity groups. Each entry is a common acronym /
    /// stem that maps to multiple legitimate variants the user might
    /// actually mean — not just alias collisions. We surface the chooser
    /// **only** when the transcript contains the stem but NONE of the
    /// disambiguators (so "cjc no dac" resolves directly without asking).
    private struct GroupDef {
        let id: String
        let title: String
        /// Words that, if present, indicate the user said the bare stem
        /// (match at least one).
        let triggerWords: [String]
        /// Words that, if ANY are present, mean the user already specified
        /// which variant — skip the chooser and let normal compound
        /// matching handle it.
        let disambiguators: [String]
        let buildOptions: () -> [DisambiguationGroup.Option]
    }

    nonisolated(unsafe) private static let groups: [GroupDef] = [
        // CJC family — three common variants people ask about.
        GroupDef(
            id: "cjc",
            title: "Which CJC?",
            triggerWords: ["cjc", "c j c"],
            disambiguators: ["no dac", "nodac", "with dac", "1295", "blend", "ipamorelin", "ipa", "mod grf", "modgrf"],
            buildOptions: {
                var out: [DisambiguationGroup.Option] = []
                if let cjc = CompoundCatalog.compound(named: "CJC-1295") {
                    out.append(.init(
                        id: "cjc-1295",
                        label: "CJC-1295",
                        subtitle: "Long-acting, with DAC · weekly",
                        resolution: .compound(cjc)
                    ))
                }
                if let noDac = CompoundCatalog.compound(named: "CJC-1295 No DAC") {
                    out.append(.init(
                        id: "cjc-1295-no-dac",
                        label: "No DAC",
                        subtitle: "Mod GRF 1-29 · short-acting, daily",
                        resolution: .compound(noDac)
                    ))
                }
                // The classic CJC+Ipa blend — we don't have a blend detail
                // page, so route to CJC-1295's page (primary member) and
                // show the blend display string as context.
                if let cjc = CompoundCatalog.compound(named: "CJC-1295"),
                   let _ = CompoundCatalog.compound(named: "Ipamorelin") {
                    out.append(.init(
                        id: "cjc-ipa-blend",
                        label: "+ Ipamorelin",
                        subtitle: "Classic GH pulse blend · pre-bed",
                        resolution: .blend(primary: cjc, display: "CJC-1295 + Ipamorelin")
                    ))
                }
                return out
            }
        ),
        // Melanotan I vs II — different receptor profiles, real choice.
        GroupDef(
            id: "melanotan",
            title: "Which Melanotan?",
            triggerWords: ["melanotan", "mt"],
            disambiguators: ["mt 1", "mt1", "mt 2", "mt2", "melanotan 1", "melanotan i", "melanotan 2", "melanotan ii", "afamelanotide"],
            buildOptions: {
                var out: [DisambiguationGroup.Option] = []
                if let mt1 = CompoundCatalog.compound(named: "Melanotan I") {
                    out.append(.init(
                        id: "mt-1",
                        label: "Melanotan I",
                        subtitle: "Selective MC1R · tanning only",
                        resolution: .compound(mt1)
                    ))
                }
                if let mt2 = CompoundCatalog.compound(named: "Melanotan II") {
                    out.append(.init(
                        id: "mt-2",
                        label: "Melanotan II",
                        subtitle: "Non-selective · tanning + libido",
                        resolution: .compound(mt2)
                    ))
                }
                return out
            }
        ),
        // IGF-1 LR3 vs DES — both serious-user-facing, different use cases.
        GroupDef(
            id: "igf",
            title: "Which IGF?",
            triggerWords: ["igf", "i g f"],
            disambiguators: ["lr3", "l r 3", "des", "long r3"],
            buildOptions: {
                var out: [DisambiguationGroup.Option] = []
                if let lr3 = CompoundCatalog.compound(named: "IGF-1 LR3") {
                    out.append(.init(
                        id: "igf-lr3",
                        label: "IGF-1 LR3",
                        subtitle: "Long half-life · systemic",
                        resolution: .compound(lr3)
                    ))
                }
                if let des = CompoundCatalog.compound(named: "IGF-1 DES") {
                    out.append(.init(
                        id: "igf-des",
                        label: "IGF-1 DES",
                        subtitle: "Short half-life · site-specific",
                        resolution: .compound(des)
                    ))
                }
                return out
            }
        ),
        // GHRP-2 vs GHRP-6 — different appetite/cortisol profiles.
        GroupDef(
            id: "ghrp",
            title: "Which GHRP?",
            triggerWords: ["ghrp", "g h r p"],
            disambiguators: ["ghrp 2", "ghrp2", "ghrp 6", "ghrp6", "ghrp two", "ghrp six"],
            buildOptions: {
                var out: [DisambiguationGroup.Option] = []
                if let two = CompoundCatalog.compound(named: "GHRP-2") {
                    out.append(.init(
                        id: "ghrp-2",
                        label: "GHRP-2",
                        subtitle: "Cleaner profile · less hunger",
                        resolution: .compound(two)
                    ))
                }
                if let six = CompoundCatalog.compound(named: "GHRP-6") {
                    out.append(.init(
                        id: "ghrp-6",
                        label: "GHRP-6",
                        subtitle: "Strong hunger · lean bulk",
                        resolution: .compound(six)
                    ))
                }
                return out
            }
        )
    ]

    private static func detectAmbiguityGroup(in lower: String) -> DisambiguationGroup? {
        for def in groups {
            let hasTrigger = def.triggerWords.contains { word in
                // Word-boundary so "igf" doesn't fire on "fig leaf" etc.
                matchesWord(lower, word)
            }
            guard hasTrigger else { continue }
            let hasDisambiguator = def.disambiguators.contains { lower.contains($0) }
            guard !hasDisambiguator else { continue }

            let options = def.buildOptions()
            // Need at least 2 real options for a meaningful chooser.
            guard options.count >= 2 else { continue }
            return DisambiguationGroup(id: def.id, title: def.title, options: options)
        }
        return nil
    }
}
