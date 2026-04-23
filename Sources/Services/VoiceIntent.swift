import Foundation

/// What the user wants the app to do, parsed from a voice transcript.
///
/// Intentionally tiny + deterministic — we don't ship a tool-calling LLM here
/// because (a) it would need to be very fast for navigation to feel snappy and
/// (b) the navigation surface is small. PepperService still covers
/// open-ended Q&A.
enum VoiceIntent: Equatable {
    case openTab(NavigationCoordinator.Tab)
    case openCompound(Compound)
    case openDosingCalculator(Compound)
    case openPinningProtocol(Compound)
    case logDose
    case askPepper(String)
    case unknown(String)

    /// Detect the intent from a free-form voice transcript.
    static func detect(in transcript: String) -> VoiceIntent {
        let raw = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return .unknown(raw) }
        let lower = raw.lowercased()

        // 1) Tab navigation — straightforward keyword match.
        if matchesAny(lower, ["go to today", "open today", "show today", "today screen", "home"]) {
            return .openTab(.today)
        }
        if matchesAny(lower, ["food", "log food", "meals", "nutrition", "macros"]) {
            return .openTab(.food)
        }
        if matchesAny(lower, ["go to protocol", "open protocol", "my protocol", "vials"]) {
            return .openTab(.protocol)
        }
        if matchesAny(lower, ["track", "tracking", "open track", "stats", "progress"]) {
            return .openTab(.track)
        }
        if matchesAny(lower, ["research", "library", "compounds list"]) {
            return .openTab(.research)
        }

        // 2) Action verbs — log a dose, calculator, pinning protocol.
        if matchesAny(lower, ["log a dose", "log dose", "i just dosed", "log my pin", "log my injection"]) {
            return .logDose
        }

        // Calculator flow — must mention a compound to make sense.
        if matchesAny(lower, ["calculator", "calculate dose", "what dose", "how much should i take"]),
           let compound = detectCompound(in: lower) {
            return .openDosingCalculator(compound)
        }

        // Pinning / injection flow.
        if matchesAny(lower, ["how do i inject", "how do i pin", "pinning protocol", "injection site", "where do i inject"]),
           let compound = detectCompound(in: lower) {
            return .openPinningProtocol(compound)
        }

        // 3) Explicit compound mention — "show me BPC" / "open Tirzepatide".
        if let compound = detectCompound(in: lower) {
            return .openCompound(compound)
        }

        // 4) Otherwise, hand off to Pepper for free-form Q&A.
        return .askPepper(raw)
    }

    private static func matchesAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains(where: { text.contains($0) })
    }

    /// Best-effort compound extraction from the transcript. Walks the catalog
    /// canonical names and aliases — same engine the picker uses.
    private static func detectCompound(in text: String) -> Compound? {
        let matchedNames = CompoundCatalog.match(in: text)
        guard let firstName = matchedNames.first else { return nil }
        return CompoundCatalog.compound(named: firstName)
    }
}

extension VoiceIntent {
    /// Friendly, spoken-style confirmation for use with TTS.
    var spokenConfirmation: String {
        switch self {
        case .openTab(let tab):                   return "Opening \(tab.title)."
        case .openCompound(let c):                return "Pulling up \(c.name)."
        case .openDosingCalculator(let c):        return "Here's the dosing calculator for \(c.name)."
        case .openPinningProtocol(let c):         return "Walking you through the pinning protocol for \(c.name)."
        case .logDose:                            return "Quick-logging a dose."
        case .askPepper:                          return "Let me think about that."
        case .unknown:                            return "I didn't catch that — say it again."
        }
    }
}
