import Foundation

/// Heuristic parser that turns free-form text (typed notes, voice transcripts,
/// pasted-from-Notes inventories) into a structured list of stack entries.
///
/// Why no LLM:
///   How people actually write down their stacks is *very* regular —
///     "BPC-157 250mcg daily"
///     "Tirzepatide 5 mg weekly (Sunday)"
///     "TB-500 — 5mg twice a week"
///     "Sema 0.5 mg / wk"
///   A line/segment-aware regex parser handles >95% of these for free, with
///   zero latency and zero per-token cost. We can layer an LLM fallback later
///   for the long tail of weird notation.
///
/// Algorithm:
///   1. Split the input into "segments": lines, sentences, and clauses
///      separated by newlines, periods, semicolons, ` and `, commas-with-mcg.
///   2. For each segment, walk the catalog and try to find a compound name.
///   3. If found, look in the *same* segment for a dose pattern and a
///      frequency pattern. Anchor everything to the matched name.
///   4. Return one `Detection` per detected compound, with confidence based on
///      whether we found dose / frequency / both.
///
/// Output is `Detection` (not `LocalProtocolCompound` directly) so the UI can
/// present an editable preview before any SwiftData writes happen.
enum StackParser {

    // MARK: - Public surface

    struct Detection: Identifiable, Hashable {
        let id = UUID()
        /// Single compound, or a **blend** title like `CJC-1295 + Ipamorelin`.
        var compoundName: String
        /// When non-empty, these peptides are co-reconstituted (one vial / one draw).
        /// `compoundName` should still be the human-readable blend title.
        var blendMembers: [String]
        /// Best-guess dose in micrograms. Nil = couldn't extract.
        var doseMcg: Double?
        /// Best-guess frequency token (matches `LocalProtocolCompound.frequency`).
        var frequency: String?
        /// Original text segment we lifted this from — handy for UI debugging.
        let sourceSegment: String
        /// 0..1 — how confident we are in the parse.
        let confidence: Double

        var hasDose: Bool { doseMcg != nil }
        var hasFrequency: Bool { frequency != nil }
        var isBlend: Bool { blendMembers.count >= 2 }
    }

    /// Parse an entire blob and return one detection per compound found,
    /// de-duplicated by name (the higher-confidence detection wins).
    static func parse(_ raw: String) -> [Detection] {
        let segments = splitIntoSegments(raw)
        var byCompound: [String: Detection] = [:]

        for segment in segments {
            for det in detectionsIn(segment: segment) {
                if let existing = byCompound[det.compoundName] {
                    if det.confidence > existing.confidence {
                        byCompound[det.compoundName] = det
                    }
                } else {
                    byCompound[det.compoundName] = det
                }
            }
        }

        var merged = Array(byCompound.values)
        merged = mergeCJCIpamorelinBlend(detections: merged, fullText: raw)

        // Stable sort: highest confidence first, then alphabetical.
        return merged.sorted {
            if $0.confidence != $1.confidence { return $0.confidence > $1.confidence }
            return $0.compoundName < $1.compoundName
        }
    }

    // MARK: - Blend merging (same-vial formulations)

    /// Community-standard GH secretagogue blend. When the transcript clearly
    /// refers to a **combined** product, collapse two rows into one vial.
    private static func mergeCJCIpamorelinBlend(detections: [Detection], fullText: String) -> [Detection] {
        let cjc = "CJC-1295"
        let ipa = "Ipamorelin"
        guard let detC = detections.first(where: { $0.compoundName == cjc }),
              let detI = detections.first(where: { $0.compoundName == ipa }) else {
            return detections
        }
        guard shouldTreatAsCJCIpaBlend(fullText: fullText, a: detC, b: detI) else {
            return detections
        }

        var rest = detections.filter { $0.compoundName != cjc && $0.compoundName != ipa }
        let title = cjc + CompoundCatalog.blendDisplaySeparator + ipa
        let mergedSegment = [detC.sourceSegment, detI.sourceSegment]
            .filter { !$0.isEmpty }
            .uniquedPreservingOrder()
            .joined(separator: " · ")

        let blend = Detection(
            compoundName: title,
            blendMembers: [cjc, ipa],
            doseMcg: detC.doseMcg ?? detI.doseMcg,
            frequency: detC.frequency ?? detI.frequency,
            sourceSegment: mergedSegment.isEmpty ? detC.sourceSegment : mergedSegment,
            confidence: max(detC.confidence, detI.confidence)
        )
        rest.append(blend)
        return rest
    }

    /// Require evidence of a **combined** product so we don't merge people who
    /// run CJC and Ipamorelin from separate vials on the same stack.
    private static func shouldTreatAsCJCIpaBlend(fullText: String, a: Detection, b: Detection) -> Bool {
        let t = fullText.lowercased()

        if slashOrAmpBetweenCJCandIPA(in: t) { return true }

        let blendCue =
            t.contains("blend") || t.contains("blended") ||
            t.contains("combo") || t.contains("combined") ||
            t.contains("premix") || t.contains("pre-mix") ||
            t.contains("same vial") || t.contains("one vial") ||
            t.contains("mixed peptide")

        if blendCue { return true }

        // "CJC no DAC + Ipamorelin" is almost always a single blended SKU in
        // clinic / telemed copy — merge even when the user never says "blend".
        if noDACCJCWithIpamorelinMention(in: t) { return true }

        return false
    }

    /// True when the transcript reads like a Mod GRF(1-29) / Ipamorelin product
    /// description (no DAC on the CJC side + GHRP on the same stack item).
    private static func noDACCJCWithIpamorelinMention(in t: String) -> Bool {
        let noDAC = t.contains("no dac") || t.contains("no-dac") || t.contains("nodac") || t.contains("without dac")
        guard noDAC else { return false }
        let cjcCue = t.contains("cjc") || t.contains("see jc") || t.contains("c j c") || t.contains("mod grf")
        let ipaCue =
            t.contains("ipamorelin") || t.contains(" ipa") || t.contains("ipa ") ||
            t.contains("amarillo") || t.contains("ipa merlin") || t.contains("merlin")
        return cjcCue && ipaCue
    }

    private static func slashOrAmpBetweenCJCandIPA(in text: String) -> Bool {
        // Note: `1295?` in a regex means "129" + optional "5", so we must
        // spell optional "1295" as `(?:1295)?`.
        guard let regex = try? NSRegularExpression(
            pattern: #"(?i)cjc(?:[-\s]*1295)?\s*[/&+]\s*ip(?:amorelin|a)\b|ip(?:amorelin|a)\b\s*[/&+]\s*cjc(?:[-\s]*1295)?"#,
            options: []
        ) else { return false }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    // MARK: - Segmenting

    /// Break the text into per-compound segments. We split on newlines first,
    /// then within each line on `;`, `.`, `,` and the words " and "/" with " —
    /// these are the natural per-item separators in handwritten stack notes.
    static func splitIntoSegments(_ raw: String) -> [String] {
        let lines = raw
            .replacingOccurrences(of: "\r", with: "")
            .components(separatedBy: "\n")

        var out: [String] = []
        for line in lines {
            // Cheap pre-split: bullets and arrows
            var working = line
            for token in ["•", "·", "→", "–"] {
                working = working.replacingOccurrences(of: token, with: ",")
            }

            let separators: [String] = [";", "\\s\\band\\b\\s", "\\s\\bwith\\b\\s"]
            var fragments = [working]
            for pattern in separators {
                fragments = fragments.flatMap { split($0, by: pattern) }
            }
            // Period split is special: "5mg." should NOT be split. Only split
            // on a period followed by a space + capital letter.
            fragments = fragments.flatMap { split($0, by: "\\.\\s+(?=[A-Z])") }

            for f in fragments {
                let trimmed = f.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { out.append(trimmed) }
            }
        }
        return out
    }

    private static func split(_ text: String, by pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return [text]
        }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = regex.matches(in: text, options: [], range: range)
        guard !matches.isEmpty else { return [text] }

        var result: [String] = []
        var cursor = 0
        for m in matches {
            if m.range.location > cursor {
                result.append(ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor)))
            }
            cursor = m.range.location + m.range.length
        }
        if cursor < ns.length {
            result.append(ns.substring(with: NSRange(location: cursor, length: ns.length - cursor)))
        }
        return result
    }

    // MARK: - Per-segment detection

    static func detectionsIn(segment: String) -> [Detection] {
        let names = CompoundCatalog.match(in: segment)
        guard !names.isEmpty else { return [] }

        // For each compound found, attribute the dose/frequency in this segment
        // to it. If multiple compounds share a segment, we still apply the same
        // dose/frequency to each (rare in practice, and the user can correct
        // it in the preview).
        let dose = extractDoseMcg(in: segment)
        let frequency = extractFrequency(in: segment)

        return names.map { name in
            let conf = confidence(hasDose: dose != nil, hasFreq: frequency != nil)
            return Detection(
                compoundName: name,
                blendMembers: [],
                doseMcg: dose,
                frequency: frequency,
                sourceSegment: segment,
                confidence: conf
            )
        }
    }

    private static func confidence(hasDose: Bool, hasFreq: Bool) -> Double {
        switch (hasDose, hasFreq) {
        case (true, true):  return 1.00
        case (true, false): return 0.80
        case (false, true): return 0.65
        case (false, false): return 0.50
        }
    }

    // MARK: - Dose extraction

    /// Returns the dose in micrograms.
    /// Recognises `mcg`, `µg`, `mg`, `iu`, `units?`, `u`. Bare numbers are not
    /// matched (too noisy — could be a year, a body-weight, anything).
    static func extractDoseMcg(in text: String) -> Double? {
        // Order matters: longer units first so "mcg" wins over "mg"+"c"
        let unitPatterns: [(pattern: String, unit: DoseUnit)] = [
            ("mcg|µg|micrograms?", .mcg),
            ("mg|milligrams?",     .mg),
            ("iu",                 .iu),
            ("units?|u\\b",        .units),
        ]

        for (rxUnit, unit) in unitPatterns {
            // value is allowed to be `5`, `5.0`, `0.5`, `2,5` (european), `1/2`
            let pattern = "(\\d+(?:[.,]\\d+)?|\\d+\\s*/\\s*\\d+)\\s*(\(rxUnit))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let ns = text as NSString
            let range = NSRange(location: 0, length: ns.length)
            if let m = regex.firstMatch(in: text, options: [], range: range), m.numberOfRanges >= 2 {
                let raw = ns.substring(with: m.range(at: 1))
                if let value = parseNumber(raw) {
                    return unit.toMcg(value)
                }
            }
        }
        return nil
    }

    private static func parseNumber(_ s: String) -> Double? {
        let cleaned = s.replacingOccurrences(of: " ", with: "")
        if cleaned.contains("/") {
            let parts = cleaned.split(separator: "/")
            if parts.count == 2,
               let n = Double(parts[0]), let d = Double(parts[1]), d > 0 {
                return n / d
            }
            return nil
        }
        return Double(cleaned.replacingOccurrences(of: ",", with: "."))
    }

    private enum DoseUnit {
        case mcg, mg, iu, units
        func toMcg(_ value: Double) -> Double {
            switch self {
            case .mcg:   return value
            case .mg:    return value * 1_000
            case .iu:    return value             // ambiguous, but for GH 1 IU ≈ 333 mcg.
                                                  // We pass through; user can correct.
            case .units: return value             // syringe units, not dose. Pass through.
            }
        }
    }

    // MARK: - Frequency extraction

    /// Returns one of the `LocalProtocolCompound.frequency` tokens
    /// ("daily", "eod", "3x_weekly", "2x_weekly", "weekly", "5on_2off", "mwf").
    static func extractFrequency(in text: String) -> String? {
        let lower = text.lowercased()

        // Order matters: most specific first.
        let rules: [(pattern: String, token: String)] = [
            ("\\bm/?w/?f\\b|monday[/, ]+wednesday[/, ]+friday",                 "mwf"),
            ("5\\s*on[\\s/-]*2\\s*off|5/2",                                    "5on_2off"),
            ("\\b(every other day|eod|every\\s+other\\s+day|q\\.?o\\.?d\\.?)", "eod"),
            ("3\\s*x\\s*[/ ]?\\s*(week|wk|weekly)|three\\s+times\\s+a?\\s*week", "3x_weekly"),
            ("2\\s*x\\s*[/ ]?\\s*(week|wk|weekly)|twice\\s+a?\\s*week|biweekly", "2x_weekly"),
            ("once\\s+a?\\s*week|weekly|1\\s*x\\s*[/ ]?\\s*(week|wk)|/\\s*wk\\b|/\\s*week\\b", "weekly"),
            ("daily|every\\s+day|qd\\b|nightly|in\\s+the\\s+morning|am\\b|pm\\b", "daily"),
        ]

        for (pat, token) in rules {
            if lower.range(of: pat, options: .regularExpression) != nil {
                return token
            }
        }
        return nil
    }
}

// MARK: - Detection → LocalProtocolCompound

extension StackParser.Detection {
    /// Build a SwiftData row from this detection. Fills in sensible defaults
    /// when the parser couldn't pin down a value — the user gets to review
    /// everything before it persists.
    func toProtocolCompound(protocolId: UUID, defaultDoseMcg: Double = 100) -> LocalProtocolCompound {
        LocalProtocolCompound(
            protocolId: protocolId,
            compoundName: compoundName,
            doseMcg: doseMcg ?? defaultDoseMcg,
            frequency: frequency ?? "daily",
            doseTimes: ["08:00"]
        )
    }
}

// MARK: - Small helpers

private extension Array where Element == String {
    func uniquedPreservingOrder() -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for s in self {
            if seen.insert(s).inserted { out.append(s) }
        }
        return out
    }
}
