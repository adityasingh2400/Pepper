import Foundation

// Single source of truth for the 24-compound starter catalog.
//
// `Entry`              – minimal aliasing data used by voice/search picker.
// `allCompoundsSeed`   – fully-populated `Compound` objects (same data
//                         that ships in `data/compound_metadata.yaml`).
//
// The YAML file at `data/compound_metadata.yaml` mirrors the same content
// and is loaded into Supabase by `scripts/seed_compound_metadata.ts`.
struct CompoundCatalog {

    struct Entry: Hashable, Identifiable {
        let canonical: String
        let category: Category
        let aliases: [String]
        var id: String { canonical }
    }

    enum Category: String, CaseIterable {
        case healing        = "Healing"
        case ghSecretagogue = "GH / Growth"
        case fatLoss        = "Metabolic"
        case other          = "Other"
    }

    static let all: [Entry] = [
        // Healing & recovery
        .init(canonical: "BPC-157",          category: .healing, aliases: [
            "bpc", "b p c", "bpc 157", "bpc157", "bpc one fifty seven",
            "bpc 1 5 7", "b p c 157",
            // STT mishearings
            "vpc", "vpc 157", "bpc one five seven"
        ]),
        .init(canonical: "TB-500",           category: .healing, aliases: [
            "tb", "tb 500", "tb500", "thymosin beta", "thymosin beta 4", "tb four",
            "t b 500", "t b five hundred",
            // STT mishearings
            "tv 500", "tb five hundred"
        ]),
        .init(canonical: "GHK-Cu",           category: .healing, aliases: [
            "ghk", "g h k", "ghk copper", "copper peptide",
            "ghkcu", "ghk cu", "g h k cu", "g h k c u", "ghk c u", "ghk-cu",
            "ghk see you", "ghk copper peptide",
            // STT mishearings
            "g h kcu", "geek copper"
        ]),
        .init(canonical: "Thymosin Alpha-1", category: .healing, aliases: [
            "thymosin alpha", "thymosin", "ta1", "ta 1", "t a 1",
            "thymosin alpha one", "thymalpha"
        ]),

        // GH secretagogues
        .init(canonical: "Ipamorelin",       category: .ghSecretagogue, aliases: [
            "ipa", "ipamorelan", "ipamorelan",
            "ipa morelin", "ipa merlin",      // STT loves this one
            "epimorelin", "ipamoreline",
            // Speech-to-text often hears "Ipamorelin" as the city name:
            "amarillo", "a marillo"
        ]),
        .init(canonical: "CJC-1295",         category: .ghSecretagogue, aliases: [
            "cjc", "c j c", "cjc 1295", "cjc1295", "cjc twelve ninety five",
            "c j c 1295", "cjc with dac", "cjc dac", "cjc-1295",
            // STT mishearings
            "see jc", "cj c"
        ]),
        .init(canonical: "Sermorelin",       category: .ghSecretagogue, aliases: [
            "sermorlin", "sermoreline", "ser morelin", "ceremonalin"
        ]),
        .init(canonical: "Tesamorelin",      category: .ghSecretagogue, aliases: [
            "tesa", "tesamorelan", "tesamoreline", "tesa morelin", "egrifta"
        ]),
        .init(canonical: "GHRP-2",           category: .ghSecretagogue, aliases: [
            "ghrp 2", "ghrp two", "ghrp2", "g h r p 2", "g h r p two"
        ]),
        .init(canonical: "GHRP-6",           category: .ghSecretagogue, aliases: [
            "ghrp 6", "ghrp six", "ghrp6", "g h r p 6", "g h r p six"
        ]),
        .init(canonical: "Hexarelin",        category: .ghSecretagogue, aliases: [
            "hex", "hex a relin", "hexarelan"
        ]),
        .init(canonical: "MK-677",           category: .ghSecretagogue, aliases: [
            "mk", "m k", "mk 677", "ibutamoren", "mk677", "mk six seventy seven",
            "m k six seventy seven", "ibutamorin"
        ]),

        // Metabolic / fat loss
        .init(canonical: "Tirzepatide",      category: .fatLoss, aliases: [
            "tirz", "mounjaro", "zepbound", "tirz a peptide",
            "tier z a tide", "tears a peptide"   // STT mishearings of "tirzepatide"
        ]),
        .init(canonical: "Semaglutide",      category: .fatLoss, aliases: [
            "sema", "ozempic", "wegovy", "rybelsus", "sema glue tide",
            "sema glue tied", "summa glue tide"
        ]),
        .init(canonical: "AOD-9604",         category: .fatLoss, aliases: [
            "aod", "a o d", "aod9604", "aod 9604", "a o d 9604",
            "a o d ninety six oh four"
        ]),
        .init(canonical: "Retatrutide",      category: .fatLoss, aliases: [
            "reta", "reta trutide", "retta trutide"
        ]),

        // Mitochondrial / longevity
        .init(canonical: "MOTS-c",           category: .other, aliases: [
            "mots c", "motsc", "mots", "mots see", "moats c", "moats see",
            "mots-c", "m o t s c", "m o t s",
            // STT loves to butcher this one — "Mazi" is what it heard for the
            // user. Add the most plausible mishearings.
            "mazi", "moats", "motsy", "motzi", "motsi", "moatsi"
        ]),

        // Other / cognitive / sexual
        .init(canonical: "PT-141",           category: .other, aliases: [
            "pt", "p t", "pt 141", "bremelanotide", "p t 141",
            "pt one forty one", "pt141"
        ]),
        .init(canonical: "Melanotan II",     category: .other, aliases: [
            "melanotan", "mt2", "mt 2", "tan peptide", "melanotan 2",
            "melanotan two", "m t 2", "melanotan ii"
        ]),
        .init(canonical: "Selank",           category: .other, aliases: ["sea lank", "celink"]),
        .init(canonical: "Semax",            category: .other, aliases: ["see max", "ceemax"]),
        .init(canonical: "Epithalon",        category: .other, aliases: [
            "epitalon", "epithalone", "epi talon", "epi th alon"
        ]),
        .init(canonical: "DSIP",             category: .other, aliases: [
            "d s i p", "dee sip", "dsip peptide"
        ]),
        .init(canonical: "KPV",              category: .other, aliases: [
            "k p v", "kay pee vee"
        ]),
        .init(canonical: "LL-37",            category: .other, aliases: [
            "l l 37", "l l thirty seven", "ll37", "double l 37"
        ]),

        // ── Extended 60-compound catalog (added from Reddit, Looksmax,
        //    vendor catalog, and biohacker community ranking) ────────────
        .init(canonical: "IGF-1 LR3",        category: .ghSecretagogue, aliases: [
            "igf", "igf 1", "igf1", "igf 1 lr3", "igf1 lr3", "igf lr3",
            "i g f 1 lr3", "i g f lr3", "long r3 igf"
        ]),
        .init(canonical: "Kisspeptin-10",    category: .other, aliases: [
            "kisspeptin", "kiss peptin", "kisspeptin 10", "kp 10", "kiss 10"
        ]),
        .init(canonical: "5-Amino-1MQ",      category: .fatLoss, aliases: [
            "5 amino 1mq", "amino 1mq", "5 amino", "five amino one mq",
            "5amino1mq", "nnmt inhibitor"
        ]),
        .init(canonical: "HGH Fragment 176-191", category: .fatLoss, aliases: [
            "hgh frag", "hgh fragment", "frag 176 191", "176 191",
            "hgh 176 191", "fragment 176", "h g h fragment"
        ]),
        .init(canonical: "Follistatin 344",  category: .ghSecretagogue, aliases: [
            "follistatin", "folli 344", "follistatin 344", "fs 344"
        ]),
        .init(canonical: "NAD+",             category: .other, aliases: [
            "nad", "n a d", "nad plus", "nad injection", "nad injectable"
        ]),
        .init(canonical: "Cagrilintide",     category: .fatLoss, aliases: [
            "cagri", "cagrilintide", "cagri lintide", "amylin analog"
        ]),
        .init(canonical: "Dihexa",           category: .other, aliases: [
            "dihexa", "di hexa", "dihex a", "d hexa"
        ]),
        .init(canonical: "PEG-MGF",          category: .ghSecretagogue, aliases: [
            "peg mgf", "pegmgf", "mgf", "mechano growth factor",
            "p e g m g f"
        ]),
        .init(canonical: "Mazdutide",        category: .fatLoss, aliases: [
            "mazdutide", "maz dutide", "mazdu tide"
        ]),
        .init(canonical: "Survodutide",      category: .fatLoss, aliases: [
            "survodutide", "survo dutide", "survo tide"
        ]),
        .init(canonical: "Pentadeca Arginate", category: .healing, aliases: [
            "pda", "pentadeca", "pentadeca arginate", "oral bpc",
            "bpc arginine salt", "p d a"
        ]),
        .init(canonical: "Cerebrolysin",     category: .other, aliases: [
            "cerebrolysin", "cere broly sin", "cerebro lysin", "cerebrolysine"
        ]),
        .init(canonical: "SS-31",            category: .other, aliases: [
            "ss 31", "ss31", "elamipretide", "s s 31", "elam ipretide"
        ]),
        .init(canonical: "FOXO4-DRI",        category: .other, aliases: [
            "foxo4", "foxo4 dri", "fox04 dri", "fox o 4 dri", "senolytic peptide",
            "fox o four", "proxofim"
        ]),
        .init(canonical: "Pinealon",         category: .other, aliases: [
            "pinealon", "pineal on", "pinea lon"
        ]),
        .init(canonical: "P-21",             category: .other, aliases: [
            "p 21", "p21", "p021", "p o 21", "p zero twenty one"
        ]),
        .init(canonical: "Tesofensine",      category: .fatLoss, aliases: [
            "teso", "tesofensine", "teso fensine", "teso fenzine"
        ]),
        .init(canonical: "Liraglutide",      category: .fatLoss, aliases: [
            "lira", "liraglutide", "saxenda", "victoza", "lira glutide"
        ]),
        .init(canonical: "SLU-PP-332",       category: .fatLoss, aliases: [
            "slu pp 332", "slupp332", "slu 332", "s l u p p 332",
            "exercise mimetic"
        ]),
        .init(canonical: "Melanotan I",      category: .other, aliases: [
            "melanotan 1", "mt1", "mt 1", "melanotan one", "m t 1",
            "afamelanotide"
        ]),
        .init(canonical: "Oxytocin",         category: .other, aliases: [
            "oxytocin", "oxy tocin", "cuddle hormone", "love hormone"
        ]),
        .init(canonical: "AICAR",            category: .fatLoss, aliases: [
            "aicar", "a i c a r", "ay car", "exercise mimetic", "ampk activator"
        ]),
        .init(canonical: "ARA-290",          category: .healing, aliases: [
            "ara 290", "ara290", "a r a 290", "cibinetide"
        ]),
        .init(canonical: "Gonadorelin",      category: .other, aliases: [
            "gonadorelin", "gnrh", "g n r h", "gona dorelin", "gonarelin"
        ]),
        .init(canonical: "HCG",              category: .other, aliases: [
            "h c g", "hcg", "human chorionic", "chorionic gonadotropin"
        ]),
        .init(canonical: "Humanin",          category: .other, aliases: [
            "humanin", "human in", "hu manin"
        ]),
        .init(canonical: "Thymalin",         category: .healing, aliases: [
            "thymalin", "thy malin", "thymus peptide"
        ]),
        .init(canonical: "Thymogen",         category: .healing, aliases: [
            "thymogen", "thy mogen", "timogen"
        ]),
        .init(canonical: "Adipotide",        category: .fatLoss, aliases: [
            "adipotide", "ftpp", "adipo tide", "f t p p"
        ]),
        .init(canonical: "Matrixyl",         category: .other, aliases: [
            "matrixyl", "matri xyl", "palmitoyl pentapeptide",
            "palmitoyl pentapeptide 4"
        ]),
        .init(canonical: "CJC-1295 No DAC",  category: .ghSecretagogue, aliases: [
            "cjc no dac", "cjc 1295 no dac", "mod grf", "modgrf",
            "modified grf", "mod grf 1 29", "modgrf 1 29"
        ]),
        .init(canonical: "IGF-1 DES",        category: .ghSecretagogue, aliases: [
            "igf 1 des", "igf des", "igf1 des", "des igf"
        ]),
        .init(canonical: "GHRH",             category: .ghSecretagogue, aliases: [
            "ghrh", "g h r h", "growth hormone releasing hormone"
        ]),
        .init(canonical: "Argireline",       category: .other, aliases: [
            "argireline", "argie reline", "acetyl hexapeptide",
            "acetyl hexapeptide 3", "acetyl hexapeptide 8"
        ]),
    ]

    static let popular: [String] = [
        "BPC-157", "Tirzepatide", "Semaglutide", "Ipamorelin",
        "CJC-1295", "TB-500", "MK-677", "PT-141",
    ]

    static let speechVocabulary: [String] = {
        var v = Set<String>()
        for e in all {
            v.insert(e.canonical)
            v.insert(e.canonical.replacingOccurrences(of: "-", with: " "))
            for alias in e.aliases { v.insert(alias) }
        }
        return Array(v)
    }()

    /// Best-effort compound match. Two passes:
    ///   1. **Exact**: substring match against canonical names + aliases (with
    ///      and without internal whitespace, so "ghkcu" hits "ghk cu").
    ///   2. **Fuzzy**: sliding 1–3 word window over the transcript; for each
    ///      window we Levenshtein-compare against catalog tokens. This catches
    ///      STT mishearings like "Mazi" → MOTS-c, "ipa Merlin" → Ipamorelin,
    ///      and run-together words like "GHKCU" → GHK-Cu.
    static func match(in text: String) -> [String] {
        let haystack = normalize(text)
        guard !haystack.isEmpty else { return [] }

        var hits = Set<String>()

        // ── Pass 1: exact substring (with both spaced + collapsed forms) ──
        let collapsedHaystack = haystack.replacingOccurrences(of: " ", with: "")
        for entry in all {
            let candidates = [entry.canonical] + entry.aliases
            outer: for c in candidates {
                let needle = normalize(c)
                guard !needle.isEmpty else { continue }
                let escaped = NSRegularExpression.escapedPattern(for: needle)
                if haystack.range(of: "\\b\(escaped)\\b", options: .regularExpression) != nil {
                    hits.insert(entry.canonical); break outer
                }
                // Also try collapsed form so "g h k cu" can hit "ghkcu" and
                // vice versa. Small word floor so single letters don't false
                // positive ("a" or "i" against everything).
                let collapsedNeedle = needle.replacingOccurrences(of: " ", with: "")
                if collapsedNeedle.count >= 3,
                   collapsedHaystack.range(of: collapsedNeedle) != nil {
                    hits.insert(entry.canonical); break outer
                }
            }
        }

        // ── Pass 2: fuzzy windows (only for compounds we didn't already hit) ──
        let words = haystack.split(separator: " ").map(String.init)
        if !words.isEmpty {
            for entry in all where !hits.contains(entry.canonical) {
                if fuzzyHit(entry: entry, words: words) {
                    hits.insert(entry.canonical)
                }
            }
        }

        return Array(hits)
    }

    /// True when any 1-, 2-, or 3-word window in the transcript is close
    /// enough (under our distance threshold) to *any* alias or canonical
    /// name for this entry.
    ///
    /// Conservative on purpose — most real mishearings are already handled
    /// by aliases (we curated phonetic ones for each compound). Fuzzy here
    /// is the safety net for **single-character typos** ("ipamorlin",
    /// "sermoreline", "tirzepetide") and runs only when:
    ///   - window is ≥5 chars (kills "tea" → "tesa" false positives)
    ///   - target is ≥6 chars (no fuzzy on short aliases)
    ///   - the first two characters match exactly (kills cross-compound
    ///     pollution: Ipamorelin shares 7/10 chars with Sermorelin but they
    ///     start "ip" vs "se", so no false positive)
    private static func fuzzyHit(entry: Entry, words: [String]) -> Bool {
        let candidates: [String] = ([entry.canonical] + entry.aliases).map { normalize($0) }
        let primaryTargets = candidates
            .map { $0.replacingOccurrences(of: " ", with: "") }
            .filter { (6...14).contains($0.count) }
        guard !primaryTargets.isEmpty else { return false }

        for windowSize in 1...min(3, words.count) {
            for start in 0...(words.count - windowSize) {
                let window = words[start..<(start + windowSize)]
                    .joined()
                    .replacingOccurrences(of: " ", with: "")
                guard (5...18).contains(window.count) else { continue }
                for target in primaryTargets {
                    if isFuzzyMatch(window, target) { return true }
                }
            }
        }
        return false
    }

    /// Treats `window` as a fuzzy match for `target` if all of:
    ///   - their first two characters are identical (anchors the prefix —
    ///     this single guard kills almost every cross-compound false hit)
    ///   - lengths differ by ≤2
    ///   - Levenshtein distance ≤ length-scaled threshold
    ///   - shared character bag covers ≥70% of the shorter string
    private static func isFuzzyMatch(_ window: String, _ target: String) -> Bool {
        // Prefix anchor — strongest cheap signal.
        guard window.prefix(2) == target.prefix(2) else { return false }

        let lenDelta = abs(window.count - target.count)
        guard lenDelta <= 2 else { return false }

        let minLen = Swift.min(window.count, target.count)
        let threshold: Int
        switch minLen {
        case 0...5:   threshold = 1
        case 6...9:   threshold = 2
        default:      threshold = 3
        }

        let dist = levenshtein(window, target)
        guard dist <= threshold else { return false }

        let overlap = sharedCharCount(window, target)
        return Double(overlap) / Double(minLen) >= 0.7
    }

    /// Classic Levenshtein edit distance (insertions + deletions + subs).
    /// Iterative two-row implementation — O(n×m) time, O(min(n,m)) space.
    private static func levenshtein(_ a: String, _ b: String) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        let aChars = Array(a), bChars = Array(b)
        var prev = Array(0...bChars.count)
        var curr = [Int](repeating: 0, count: bChars.count + 1)
        for i in 1...aChars.count {
            curr[0] = i
            for j in 1...bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                curr[j] = Swift.min(
                    prev[j] + 1,         // deletion
                    curr[j - 1] + 1,     // insertion
                    prev[j - 1] + cost   // substitution
                )
            }
            swap(&prev, &curr)
        }
        return prev[bChars.count]
    }

    /// Count of characters that appear in both strings (with multiplicity).
    /// Used as a sanity guard so "I am pretty" doesn't fuzzy-match "Ipamorelin".
    private static func sharedCharCount(_ a: String, _ b: String) -> Int {
        var bag: [Character: Int] = [:]
        for c in a { bag[c, default: 0] += 1 }
        var shared = 0
        for c in b {
            if let count = bag[c], count > 0 {
                shared += 1
                bag[c] = count - 1
            }
        }
        return shared
    }

    static func normalize(_ s: String) -> String {
        let lower = s.lowercased()
        let scrubbed = lower
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: ",", with: " ")
        return scrubbed
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - Hand-curated v1.5 metadata for the 24 catalog compounds
// Mirrored to data/compound_metadata.yaml (source of truth for Supabase loader).
extension CompoundCatalog {

    static let allCompoundsSeed: [Compound] = [

        // ── Healing & recovery ─────────────────────────────────────────────

        Compound(
            name: "BPC-157",
            slug: "bpc-157",
            halfLifeHrs: 4,
            dosingRangeLowMcg: 200,
            dosingRangeHighMcg: 750,
            benefits: ["Tendon and ligament repair", "Gut healing", "Anti-inflammatory", "Wound healing"],
            sideEffects: ["Generally well tolerated", "Mild nausea (rare)"],
            stackingNotes: "Stacks well with TB-500 for systemic vs. local repair.",
            fdaStatus: .research,
            summaryMd: "BPC-157 (Body Protection Compound 157) is a synthetic peptide derived from a protein found in gastric juice. Best-studied for tendon/ligament healing and GI recovery.",
            goalCategories: ["recovery", "skin_hair"],
            administrationRoutes: ["subq", "im"],
            timeToEffectHours: 0.5,
            peakEffectHours: 2,
            durationHours: 6,
            dosingFormula: "clamp(weightKg * 5, 250, 750)",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left", "thigh-subq-right"],
            popularityRank: 3,
            effectsTimeline: "Day 3-5: injection-site tendon pain often reduces. Week 2: GI symptoms (reflux, loose stools) improve; soft-tissue injuries feel less raw. Week 4-6: measurable tendon/ligament recovery, gut-lining repair evident in IBD cohorts. 6-8 week cycles standard — longer uninterrupted use isn't well-studied.",
            mechanism: "15-amino-acid peptide derived from a gastric juice protein. Three converging pathways: (1) Upregulates VEGFR2-Akt-eNOS signaling → angiogenesis + nitric oxide balance for blood flow to damaged tissue; (2) Increases FAK-paxillin phosphorylation → fibroblast migration into wounds; (3) Upregulates growth hormone receptor expression on tendon/ligament fibroblasts, amplifying endogenous GH signal without being a GH itself. Remarkably orally stable due to gastric origin.",
            risks: "Theoretical tumor-angiogenesis acceleration in undiagnosed cancer (BPC promotes new vessel growth — same pathway tumors exploit) · Off-target fibrotic response in some tissues · Anecdotal mild dizziness, injection-site irritation · Immunogenicity (antibody formation) over long chronic use · No large human RCTs — most data is rodent · FDA placed BPC-157 on compounding bulk-substance negative list in 2023",
            mitigations: "Full cancer screening baseline before first cycle — dermatology check, CBC/CMP, age-appropriate colonoscopy/mammography/PSA. Cycle 4-8 weeks on, 2-4 weeks off rather than chronic use. Avoid in active malignancy or <5y cancer remission. Oral route for GI-specific issues preserves gut-localized benefit while reducing systemic angiogenic exposure. Stop if unexplained lumps, bleeding, or new skin lesions appear."
        ),

        Compound(
            name: "TB-500",
            slug: "tb-500",
            halfLifeHrs: 96,
            dosingRangeLowMcg: 2_000,
            dosingRangeHighMcg: 5_000,
            benefits: ["Systemic tissue repair", "Reduced inflammation", "Improved flexibility", "Cardiovascular recovery"],
            sideEffects: ["Fatigue", "Head rush", "Nausea at higher doses"],
            stackingNotes: "Pairs with BPC-157 for comprehensive injury recovery.",
            fdaStatus: .research,
            summaryMd: "TB-500 is a synthetic Thymosin Beta-4 fragment researched for cell migration and tissue repair.",
            goalCategories: ["recovery"],
            administrationRoutes: ["subq", "im"],
            timeToEffectHours: 24,
            peakEffectHours: 48,
            durationHours: 168,
            dosingFormula: "clamp(weightKg * 30, 2000, 5000)",
            dosingUnit: "mcg",
            dosingFrequency: "2x_weekly",
            bacWaterMlDefault: 3.0,
            storageTemp: "refrigerated",
            storageMaxDays: 60,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "glute-im-left", "glute-im-right"],
            popularityRank: 8,
            effectsTimeline: "Week 1: loading dose may cause mild fatigue or head rush for first 48h. Week 2-3: systemic inflammation noticeably lower; chronic injuries feel less stuck. Week 4-6: flexibility and connective-tissue recovery clearly improved. Typical protocol: load 5 mg 2x/week for 4 weeks, then maintain 2-3 mg weekly. Works slower than BPC-157 but more systemically.",
            mechanism: "Synthetic fragment (17-23) of thymosin beta-4, a 43-amino-acid actin-regulating peptide found in platelets, macrophages, and wound tissue. Primary mechanism: binds G-actin (monomeric actin) and controls its availability for polymerization into F-actin filaments — this actin-dynamics regulation enables coordinated cell migration (fibroblasts, keratinocytes, endothelial cells) into wounds. Secondary mechanisms: NF-kB inhibition via ILK pathway (anti-inflammatory), angiogenesis via endothelial cell migration, myofibroblast differentiation for collagen deposition. The Ac-SDKP tetrapeptide released from Tb4 is strongly anti-fibrotic.",
            risks: "Shared BPC-157 concern: angiogenesis promotion, theoretical acceleration of undiagnosed tumor vasculature · Fatigue and head rush on loading doses · Mild nausea · Injection site reactions · Systemic distribution is much broader than BPC (larger peptide, longer half-life ~96h) so off-target effects harder to contain · Immunogenicity with chronic use · No human RCTs — almost all data is rodent · WADA-banned",
            mitigations: "Full cancer screening before first cycle (dermatology, age-appropriate GI, breast/prostate). Cycle load 4-6 weeks then maintenance, not indefinite. Combine with BPC-157 rather than run solo — synergistic coverage (BPC vascular stabilization + TB cell migration). Pause during any active infection or unexplained lymphadenopathy. Avoid within 5 years of cancer remission. Hold during pregnancy. Start at 2 mg 2x weekly; only escalate after 2 weeks tolerated."
        ),

        Compound(
            name: "GHK-Cu",
            slug: "ghk-cu",
            halfLifeHrs: 2,
            dosingRangeLowMcg: 1_000,
            dosingRangeHighMcg: 3_000,
            benefits: ["Skin regeneration", "Collagen production", "Hair growth", "Wound healing"],
            sideEffects: ["Injection-site irritation", "Skin discoloration (rare)"],
            stackingNotes: "Often used topically; subq for systemic effects.",
            fdaStatus: .research,
            summaryMd: "GHK-Cu is a copper-binding tripeptide researched for skin remodeling, hair regrowth, and wound repair.",
            goalCategories: ["skin_hair", "recovery", "longevity"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 72,
            durationHours: 168,
            dosingFormula: "1500",
            dosingUnit: "mcg",
            dosingFrequency: "3x_weekly",
            bacWaterMlDefault: 3.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 5,
            effectsTimeline: "Week 1-2: topical — skin feels smoother within days; injectable — mild injection-site pinkness. Week 4: visible skin-quality improvement, wound healing noticeably faster, some hair-density increase on scalp. Week 8-12: collagen density measurable by ultrasound, fine lines soften, post-procedure recovery accelerated. Standard cycles are 4-6 weeks on, 2-4 weeks off for injectable.",
            mechanism: "Tripeptide (glycyl-L-histidyl-L-lysine) with a copper(II) binding pocket. Two mechanisms: (1) Copper delivery — cofactor for lysyl oxidase (collagen/elastin crosslinking), SOD (antioxidant), and cytochrome c oxidase (mitochondrial energy); (2) Gene expression modulation — affects ~31% of human genes per the Broad Institute's Connectivity Map, shifting expression toward a younger phenotype (upregulates collagen synthesis, DNA repair, antioxidant defenses; downregulates inflammatory cytokines, matrix metalloproteinases, TGF-beta fibrosis pathways). Plasma GHK levels drop ~60% between age 20 and 60.",
            risks: "Copper toxicity — theoretical concern with chronic injectable use, especially at doses >2 mg/day or stacked with oral copper · Disruption of copper-zinc-iron trivalent balance → zinc deficiency symptoms (hair loss, immune drop, taste disturbance) · Hyperpigmentation at injection sites · Pro-angiogenic (mild, shared BPC/TB-500 tumor-growth theoretical concern) · Contraindicated in Wilson's disease (copper accumulation) · Injection-site darkening / irritation",
            mitigations: "Zinc supplementation 15-30 mg/day is the canonical pairing — prevents copper-induced zinc depletion and keeps the Cu:Zn ratio in balance (your 'zinc for copper poisoning' insight is exactly right). Baseline and periodic labs: serum copper, ceruloplasmin, non-ceruloplasmin-bound copper, RBC zinc, liver enzymes, high-sensitivity CRP. Cap injectable at 1.5-2 mg/day for most users. Prefer topical route when the goal is skin-only — avoids systemic copper entirely. Avoid in Wilson's disease, active malignancy, or unresolved hepatic dysfunction."
        ),

        Compound(
            name: "Thymosin Alpha-1",
            slug: "thymosin-alpha-1",
            halfLifeHrs: 2,
            dosingRangeLowMcg: 800,
            dosingRangeHighMcg: 1_600,
            benefits: ["Immune modulation", "Anti-viral support", "Reduced inflammation"],
            sideEffects: ["Injection site reaction", "Mild flu-like symptoms"],
            stackingNotes: "Combine with TB-500 during recovery from viral illness.",
            fdaStatus: .research,
            summaryMd: "Thymosin Alpha-1 (Tα1) is an immune-modulating peptide. Studied for chronic viral infections and immune dysregulation.",
            goalCategories: ["immune", "recovery"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 12,
            peakEffectHours: 24,
            durationHours: 72,
            dosingFormula: "1600",
            dosingUnit: "mcg",
            dosingFrequency: "2x_weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 31,
            effectsTimeline: "Week 1-2: mild flu-like symptoms occasionally during immune ramp — body 'waking up' T-cell function. Week 2-4: noticeable reduction in chronic infection symptoms (Lyme, CMV, EBV reactivation) in affected users. Week 4-8: baseline immune function measurably stronger — lymphocyte counts, NK cell activity trending up. Commonly dosed 1.6 mg 2x weekly for 3-6 months. FDA Phase 3 trials for hepatitis B and certain cancers; approved in 35+ countries outside US as Zadaxin.",
            mechanism: "Synthetic 28-amino-acid thymosin alpha-1 identical to endogenous Tα1 produced by thymic epithelial cells. Modulates dendritic cell maturation and T-cell differentiation via TLR-9 and TLR-2 activation, enhancing Th1 response and cytotoxic T-cell activity. Increases IL-2 and IFN-gamma production, suppresses apoptosis of activated T cells, restores NK cell activity in immunocompromised states. Not immunostimulatory per se — rather immunomodulatory: ramps up deficient immune function without over-activating healthy immunity.",
            risks: "Mild flu-like symptoms during initial doses · Injection-site erythema / tenderness · Rare hypersensitivity / urticaria · Theoretical autoimmune flare in existing autoimmune disease (Hashimoto's, lupus, RA) · Potential interference with immunosuppressive therapy (transplant patients) · Limited safety data in pregnancy · Costly on grey market · Contaminated supply risk · Not FDA-approved despite Phase 3 trials",
            mitigations: "Baseline immune panel: CBC with differential, total IgG/A/M, lymphocyte subsets (CD4, CD8, NK). Avoid in active uncontrolled autoimmune disease, organ transplant on immunosuppression, pregnancy. Start 800 mcg 2x weekly for first 2 weeks, escalate to 1.6 mg if tolerated. Dose 2-3 days apart. Cycle 3-6 months on, then 1-2 months off. Source with COA — common counterfeit target. Stop for unexplained joint flare, new rash persistent > 1 week, or lymphadenopathy."
        ),

        // ── GH secretagogues ───────────────────────────────────────────────

        Compound(
            name: "Ipamorelin",
            slug: "ipamorelin",
            halfLifeHrs: 2,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["GH release", "Deeper slow-wave sleep", "Circadian GH pulse support", "Lean muscle", "Fat loss"],
            sideEffects: ["Mild hunger increase", "Water retention", "Headache"],
            stackingNotes: "Commonly stacked with CJC-1295 (No DAC) pre-bed — the classic sleep + recovery protocol. The pulse rides the natural slow-wave-sleep GH surge.",
            fdaStatus: .research,
            summaryMd: "Ipamorelin is a selective ghrelin mimetic that stimulates GH without significantly affecting cortisol or prolactin. Pre-bed dosing (usually with CJC-1295 No DAC) is the most popular use — users consistently report deeper, more restorative sleep alongside recovery and body-composition benefits.",
            goalCategories: ["growth", "sleep", "recovery"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 3,
            dosingFormula: "clamp(weightKg * 1.5, 100, 300)",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left", "thigh-subq-right"],
            popularityRank: 7,
            effectsTimeline: "Night 1 (pre-bed dose): deeper sleep often immediate, some report vivid dreams. Week 1-2: morning recovery improved, transient hunger spike after injection. Week 4: skin quality improving, joint soreness down, lean-mass trending up slightly. Week 8-12: body-comp changes visible when stacked with CJC-1295 No DAC pre-bed. Selective and clean — the most tolerated GHRP, ideal for beginners.",
            mechanism: "Selective ghrelin-receptor (GHSR-1a) agonist on pituitary somatotrophs. Raun et al. 1998: stimulates GH release with potency comparable to GHRP-6 but without the dose-dependent cortisol, prolactin, ACTH, or aldosterone elevation that older GHRPs cause. This is the 'selectivity' that makes Ipamorelin the cleanest GHRP — stress-hormone neutral. Works through a different receptor than GHRH analogues (CJC/Sermorelin), which is why stacking the two produces synergistic pulses larger than either alone.",
            risks: "Transient hunger immediately post-injection (ghrelin-mimetic) · Water retention (mild) · Headache · Injection site reactions · Flu-like symptoms occasionally · FDA-flagged immunogenicity (anaphylaxis possible) · Death risk if accidentally injected IV instead of subq · Theoretical IGF-1-mediated cancer acceleration on undiagnosed malignancy · Receptor desensitization with chronic uninterrupted use",
            mitigations: "Always subq — never IV. Cycle 4-6 months on, 1 month off to prevent desensitization. Pre-bed dosing rides the natural slow-wave-sleep GH pulse; stack with CJC-1295 No DAC 100-200 mcg for synergistic effect. Dose 30 min fasted (food blunts GH pulse). Baseline and 6-month IGF-1, fasting glucose, A1c. Cancer screening baseline. Start at 100 mcg to assess anaphylaxis risk. Keep epi-auto-injector accessible first 3 doses."
        ),

        Compound(
            name: "CJC-1295",
            slug: "cjc-1295",
            halfLifeHrs: 168,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 200,
            benefits: ["Sustained GH elevation", "Deeper slow-wave sleep", "Improved recovery", "Increased IGF-1"],
            sideEffects: ["Water retention", "Fatigue", "Injection site reaction"],
            stackingNotes: "Pairs with Ipamorelin for amplified GH pulses. Pre-bed dosing aligns the pulse with the natural slow-wave sleep GH surge.",
            fdaStatus: .research,
            summaryMd: "CJC-1295 (with DAC) is a long-acting GHRH analogue. The DAC complex extends half-life to ~7 days, elevating baseline GH/IGF-1 between doses and improving slow-wave sleep quality.",
            goalCategories: ["growth", "sleep", "recovery"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 6,
            peakEffectHours: 24,
            durationHours: 168,
            dosingFormula: "clamp(weightKg * 1.5, 100, 200)",
            dosingUnit: "mcg",
            dosingFrequency: "weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 60,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 6,
            effectsTimeline: "Week 1-2: deeper slow-wave sleep within days (most-reported first effect). Week 4: recovery between workouts noticeably faster, IGF-1 rising. Week 8-12: lean mass edge, skin tightening, reduced visceral fat. DAC version (this one) has ~6-8 day half-life so weekly or twice-weekly dosing maintains sustained GH/IGF-1 elevation for ~168h per shot.",
            mechanism: "Long-acting GHRH analogue with a maleimido group that covalently binds plasma albumin, extending half-life from GHRH's native ~7 minutes to 5.8-8.1 days. Activates GHRH receptors on pituitary somatotrophs → cAMP → GH synthesis + pulsatile release. Produces 2-10x baseline GH for 6+ days and 1.5-3x IGF-1 for 9-11 days per dose. Unlike GHRPs, still subject to somatostatin negative feedback — which preserves physiological pulsing.",
            risks: "Sustained non-physiological GH elevation can drive insulin resistance (unlike the cleaner pulsatile pattern of no-DAC variants) · Water retention · Fatigue, especially during first weeks · Injection site reactions · Tingling/numb hands (fluid retention around median nerve) · Carpal tunnel symptoms · Theoretical cancer risk via elevated IGF-1 on any undiagnosed malignancy · FDA-warned for immunogenicity (anaphylaxis potential) and systemic vasodilatory flushing · WADA-banned for athletes",
            mitigations: "Cycle 3 months on, 1 month off to reset receptor sensitivity and avoid chronic insulin resistance. Baseline and quarterly fasting glucose + A1c + IGF-1 (target ≤250-280 ng/mL for most adults). Cancer screening baseline. If choosing sustained-GH goals, CJC-1295 No DAC (Mod GRF 1-29) is preferable — pulsatile not tonic — and closer to natural physiology. Pre-bed dosing aligns with the nocturnal GH surge. Stop immediately for anaphylaxis signs. Avoid if history of any cancer, active retinopathy, or uncontrolled diabetes."
        ),

        Compound(
            name: "Sermorelin",
            slug: "sermorelin",
            halfLifeHrs: 0.2,
            dosingRangeLowMcg: 200,
            dosingRangeHighMcg: 500,
            benefits: ["Natural GH pulse", "Improved sleep", "Recovery"],
            sideEffects: ["Flushing", "Headache", "Injection site reaction"],
            stackingNotes: "Pre-bed dosing aligns with the natural GH pulse.",
            fdaStatus: .research,
            summaryMd: "Sermorelin is a short GHRH analogue. Stimulates pituitary GH release with a fast on/off profile.",
            goalCategories: ["growth", "sleep", "recovery"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 2,
            dosingFormula: "300",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 13,
            effectsTimeline: "Week 1-2: noticeably deeper sleep within days, mild flushing at injection site. Week 4: recovery between workouts improved, morning energy better. Week 8-16: lean-mass edge with training, skin tightening, IGF-1 up ~30-50%. FDA-cleared for pediatric GH deficiency but used off-label in adult anti-aging at 200-500 mcg pre-bed. Requires daily dosing due to ~11-minute half-life.",
            mechanism: "29-amino-acid GHRH analogue (the active N-terminal fragment of endogenous 44-aa GHRH). Binds GHRH receptors on pituitary somatotrophs → Gs / cAMP / PKA cascade → pulsatile GH synthesis and release. Still subject to somatostatin negative feedback, which preserves physiological on/off pulsing and makes side-effect profile gentler than exogenous HGH or long-acting GHRH analogues like CJC-1295 DAC. Shortest-acting GHRH analogue in clinical use — mimics natural pre-sleep GH pulse when dosed at bedtime.",
            risks: "Injection site reactions (most common) · Flushing, especially facial · Headache, dizziness · Fluid retention (much milder than MK-677 or CJC-1295 DAC) · Joint pain · Increased appetite · Allergic reactions (rash to rare anaphylaxis) · Theoretical IGF-1-mediated cancer acceleration on undiagnosed malignancy · Hypothyroidism blunts response — check baseline thyroid · Requires daily injection (adherence barrier)",
            mitigations: "Pre-bed dosing aligns with natural GH pulse and minimizes daytime fluid retention. Baseline + 3-month + annual fasting glucose, A1c, IGF-1 (target ≤280 ng/mL adults), TSH, cancer screening. Rotate injection sites weekly. Start at 200 mcg to assess allergic response; keep epi accessible first 3 doses. Cycle 3-4 months on, 4-6 weeks off to avoid receptor downregulation. Stop for persistent joint pain or A1c > 0.3 point rise. Avoid with active cancer, severe obesity, pregnancy."
        ),

        Compound(
            name: "Tesamorelin",
            slug: "tesamorelin",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 1_000,
            dosingRangeHighMcg: 2_000,
            benefits: ["Visceral fat reduction", "Improved lipid profile", "Cognitive benefits"],
            sideEffects: ["Injection site reaction", "Joint pain", "Insulin resistance"],
            stackingNotes: "Best for visceral adiposity. Monitor blood glucose.",
            fdaStatus: .approved,
            summaryMd: "Tesamorelin is an FDA-approved GHRH analogue used for HIV-associated lipodystrophy. Off-label use for visceral fat.",
            goalCategories: ["fat_loss", "growth", "cognitive"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.5,
            peakEffectHours: 1,
            durationHours: 4,
            dosingFormula: "2000",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 14,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 10,
            effectsTimeline: "Week 1-2: mild flushing at injection site, some fatigue as IGF-1 rises. Week 4: visceral fat visibly softer, waist tightening. Week 8-12: ~15% visceral adipose tissue reduction (Phase 3 data in HIV-lipodystrophy), triglycerides down ~25%, cognitive processing speed improves in some users. Effects reverse within 6 months of stopping (VAT rebounds) — not a one-and-done intervention. FaFa cutting-cycle favorite for this reason.",
            mechanism: "44-amino-acid GHRH analogue with a trans-3-hexenoic acid modification that resists DPP-IV enzymatic degradation, giving it ~30-minute half-life vs native GHRH's ~7 min. Activates GHRH receptors on pituitary somatotrophs → pulsatile endogenous GH release → hepatic IGF-1 synthesis → lipolysis specifically in visceral adipose tissue (VAT has more GH receptors than subcutaneous fat, explaining VAT-selective effect). FDA-approved as Egrifta for HIV-associated lipodystrophy — the most clinically validated GH secretagogue.",
            risks: "Arthralgia (joint pain) — most common side effect · Peripheral edema / fluid retention · Carpal-tunnel-like paresthesias · Insulin resistance and glucose intolerance (VAT reduction helps but IGF-1 elevation works against it) · Injection site reactions · Rare but documented: pancreatitis, hypersensitivity reactions · VAT rebound after discontinuation (effects not sustained) · Theoretical cancer acceleration via IGF-1 · Contraindicated: active malignancy, pregnancy, hypersensitivity to mannitol",
            mitigations: "Evening dosing aligns with natural GH pulse and minimizes daytime fluid retention symptoms. 5-days-on / 2-days-off schedule reduces desensitization. Baseline + quarterly fasting glucose, A1c, IGF-1 (target ≤250-280 ng/mL). Cancer screening baseline + annual. Start at 1 mg daily, escalate to 2 mg only if tolerated 2 weeks. Pair with resistance training + ≥1.6 g/kg protein — VAT loss without lean-mass preservation is cosmetic, not metabolic. Rotate injection sites (abdomen left/right) to prevent lipoatrophy. Discontinue for unexplained persistent joint pain > 2 weeks or A1c rise > 0.5 points."
        ),

        Compound(
            name: "GHRP-2",
            slug: "ghrp-2",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["GH release", "Appetite stimulation", "Lean muscle"],
            sideEffects: ["Increased prolactin", "Cortisol bump", "Hunger"],
            stackingNotes: "Synergistic with CJC-1295. More cortisol/prolactin than Ipamorelin.",
            fdaStatus: .research,
            summaryMd: "GHRP-2 is a ghrelin mimetic with stronger GH release than Ipamorelin but more cortisol/prolactin activity.",
            goalCategories: ["growth"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 2,
            dosingFormula: "clamp(weightKg * 1.5, 100, 300)",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 41,
            effectsTimeline: "Within 30 min: noticeable appetite surge and strong GH pulse. Day 1-3: recovery and sleep quality improving. Week 1-2: lean mass trending up if training; water retention mild. Week 4: cortisol and prolactin elevation becomes measurable — why Ipamorelin is preferred for long-term use. 4-6 week cycles max, then 4 weeks off. 100-300 mcg subq 2-3x daily.",
            mechanism: "Synthetic hexapeptide ghrelin receptor (GHSR-1a) agonist. Stronger GH-releasing potency than Ipamorelin but NOT selective — also elevates cortisol, prolactin, and ACTH substantially (dose-dependent). Mechanistically: activates GHSR-1a on pituitary somatotrophs AND hypothalamic neurons → robust GH pulse plus downstream stress hormone co-release. Appetite stimulation through NPY/AgRP neurons in arcuate nucleus. Short half-life (~30 min); often stacked with CJC/Mod GRF 1-29 for synergistic GH pulse.",
            risks: "Cortisol elevation → blunted recovery, body-fat retention, sleep disruption at higher doses · Prolactin elevation → gynecomastia risk, libido reduction, potential galactorrhea · Appetite surge (unavoidable, can drive overeating) · Water retention · Numbness in hands · Theoretical IGF-1-mediated cancer acceleration on undiagnosed malignancy · Faster receptor desensitization than Ipamorelin · Immunogenicity with chronic use · Injection-site reactions",
            mitigations: "Prefer Ipamorelin for long-term / chronic use — same GHSR-1a target with cleaner hormone profile. Reserve GHRP-2 for short cycles where maximal pulse matters. 4-6 week cycles, 4 weeks off. Cap 200 mcg per dose, 2-3x daily. Morning and pre-bed dosing only (avoid late afternoon). Baseline and end-of-cycle cortisol, prolactin, IGF-1, fasting glucose. Avoid in gynecomastia-prone users, active cancer, adrenal insufficiency, pregnancy. Stop for breast tenderness, mood flattening, or persistent sleep disruption."
        ),

        Compound(
            name: "GHRP-6",
            slug: "ghrp-6",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["GH release", "Strong appetite", "Connective tissue"],
            sideEffects: ["Strong hunger", "Lethargy", "Cortisol bump"],
            stackingNotes: "Best for those who want appetite increase. Heavier prolactin profile.",
            fdaStatus: .research,
            summaryMd: "GHRP-6 is a ghrelin mimetic with the strongest appetite-stimulating effect of the GHRP family.",
            goalCategories: ["growth"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 2,
            dosingFormula: "200",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 42,
            effectsTimeline: "Within 15-30 min: very strong appetite surge — stronger than GHRP-2, ghrelin-like hunger. Day 1-3: sleep depth improves. Week 1-2: if the goal is weight gain, this is the strongest eating trigger in the GHRP class. Week 4+: receptor desensitization and cortisol/prolactin costs mount. 4-6 week cycles max. Mostly useful for underweight users or bulking phases — the appetite stim is a feature for them, a bug for most.",
            mechanism: "Synthetic hexapeptide GHSR-1a agonist — same receptor as GHRP-2 and Ipamorelin but with the strongest ghrelin-mimetic appetite-stimulating effect of the class. Activates NPY/AgRP hunger neurons more robustly than GHRP-2. GH release comparable to GHRP-2. Cortisol and prolactin co-release: higher than Ipamorelin, similar to or slightly below GHRP-2. Half-life ~30 min; 2-3x daily dosing.",
            risks: "Strongest appetite surge of the GHRP class — genuinely difficult to resist overeating · Cortisol and prolactin elevation — gynecomastia, mood, libido concerns · Lethargy post-dose sometimes · Water retention, numb hands · Receptor desensitization with chronic use · Theoretical IGF-1 / cancer concern as other GHRPs · Not appropriate for users actively trying to lose weight · Injection site reactions · Immunogenicity with repeated cycles",
            mitigations: "Use only when weight gain is an explicit goal — otherwise Ipamorelin is strictly better. 100-300 mcg subq 2-3x daily. 4-6 week cycle, 4 weeks off. Morning + pre-training dosing uses the appetite bump productively (fuels workouts). Pair with high-protein diet structure to channel appetite into lean-mass gain rather than indiscriminate eating. Baseline and end-of-cycle cortisol, prolactin, IGF-1. Avoid in obesity, T2D, gynecomastia-prone users, active cancer. Stop for uncontrolled appetite disrupting body composition or breast tenderness."
        ),

        Compound(
            name: "Hexarelin",
            slug: "hexarelin",
            halfLifeHrs: 1,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 200,
            benefits: ["Strong GH pulse", "Cardioprotective", "Muscle"],
            sideEffects: ["Receptor desensitization", "Cortisol bump"],
            stackingNotes: "Cycle on/off (4 weeks on, 4 off) to avoid desensitization.",
            fdaStatus: .research,
            summaryMd: "Hexarelin gives the strongest GH pulse of the GHRPs but desensitizes receptors with chronic use.",
            goalCategories: ["growth", "longevity"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 2,
            dosingFormula: "100",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 28,
            effectsTimeline: "Within 20-30 min of injection: strong GH pulse — stronger than Ipamorelin or GHRP-6. Week 1-2: noticeable recovery boost, deeper sleep. Week 3-4: lean-mass edge, skin quality improving. Week 4+: receptor desensitization kicks in — GH response dulls even at higher doses. This is why strict 4-week-on / 4-week-off cycling is non-negotiable. Longer cycles waste product and blunt future responsiveness.",
            mechanism: "Synthetic hexapeptide GHS — ghrelin receptor (GHSR-1a) agonist with the strongest GH-releasing potency of the GHRP family. Unlike Ipamorelin's clean profile, Hexarelin substantially elevates cortisol, prolactin, and ACTH as dose climbs — the selectivity cost of potency. Also has direct cardioprotective effects through CD36 receptor binding on cardiomyocytes, a non-GH mechanism — rodent data shows improved cardiac function after ischemia. Short half-life (~1h) but produces the largest single-pulse GH bump of any injectable secretagogue.",
            risks: "Rapid receptor desensitization — the defining risk; chronic use blunts both Hexarelin and endogenous GH response · Cortisol and prolactin elevation can drive body-fat retention, gynecomastia risk, libido drop · ACTH bump may unmask adrenal dysfunction · Water retention more than Ipamorelin · Numbness / paresthesias from fluid retention · Theoretical IGF-1-mediated cancer acceleration · Injection site reactions · More side-effect-heavy than cleaner GHRPs · Immunogenicity possible with repeated cycles",
            mitigations: "Strict 4-weeks-on, 4-weeks-off cycling — no exceptions. Cap at 100-200 mcg, 1-2x daily. Pre-bed dosing aligns with natural GH pulse but avoid late second dose to limit cortisol/sleep interference. If long-term GH-axis support is the goal, cleaner options (Ipamorelin, CJC No DAC, Sermorelin) are strictly better. Use Hexarelin only for short intensive cycles where maximal GH pulse matters. Baseline cortisol, prolactin, IGF-1 — recheck after cycle. Avoid in active cancer, gynecomastia-prone users, existing adrenal insufficiency, or pregnancy. Discontinue for breast tenderness, mood flattening, or sleep disruption."
        ),

        Compound(
            name: "MK-677",
            slug: "mk-677",
            halfLifeHrs: 24,
            dosingRangeLowMcg: 10_000,
            dosingRangeHighMcg: 25_000,
            benefits: ["Sustained GH/IGF-1", "Improved sleep", "Appetite"],
            sideEffects: ["Water retention", "Numb hands", "Blood sugar elevation"],
            stackingNotes: "Oral – not injected. Take with or without food.",
            fdaStatus: .research,
            summaryMd: "MK-677 (Ibutamoren) is an oral ghrelin mimetic. Daily dosing produces sustained GH/IGF-1 elevation.",
            goalCategories: ["growth", "sleep"],
            administrationRoutes: ["oral"],
            timeToEffectHours: 1,
            peakEffectHours: 2,
            durationHours: 24,
            dosingFormula: "20000",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 0,
            storageTemp: "room",
            storageMaxDays: 365,
            recommendedSiteIds: [],
            popularityRank: 11,
            effectsTimeline: "Night 1-3: sleep depth often noticeably deeper, hunger surge on waking and evening. Week 1-2: water retention, mild tingling in hands. Week 4: skin/hair quality improving, recovery faster, IGF-1 rising. Week 8-12: lean mass edge if training, appetite strong throughout. Blood glucose and fasting insulin creep up — the most consistent finding across every clinical trial. Cycle 3-6 months on, 4-8 weeks off.",
            mechanism: "Orally active non-peptide ghrelin receptor (GHSR-1a) agonist. Same receptor as Ipamorelin but with ~24h half-life and oral bioavailability, producing sustained 24-hour elevation of GH and IGF-1 vs the pulsatile pattern of injected GHRPs. Activates hypothalamic GHRH release plus direct pituitary somatotroph stimulation. Also activates NPY/AgRP hunger neurons in the arcuate nucleus — the appetite surge is on-target not a side effect. Crosses blood-brain barrier; ~60% oral bioavailability.",
            risks: "Insulin resistance — the biggest concern (Nass 2008: fasting glucose +5 mg/dL, fasting insulin up significantly at 2 years) · Peripheral edema / swelling in hands, feet, ankles · Carpal-tunnel-like numbness and tingling · Increased appetite (unavoidable) · Lethargy / afternoon fatigue · Joint and muscle pain · Possible congestive heart failure signal (Merck halted Phase 3 for this) · Theoretical cancer risk via sustained elevated IGF-1",
            mitigations: "Baseline + quarterly fasting glucose, A1c, fasting insulin, IGF-1. Pre-existing prediabetes or metabolic syndrome is a strong relative contraindication. Dose before bed to align with natural GH pulse and let hunger spike happen during sleep. Cap at 12.5-25 mg daily — higher doses don't help body comp but worsen side effects. Cycle: 3-4 months on, 6-8 weeks off. Compression sleeves or leg elevation help lower-extremity edema. Cardio + protein-prioritized diet offsets glucose drift. Discontinue for persistent swelling, hand numbness lasting >48h, or A1c rise > 0.5."
        ),

        // ── Metabolic / fat loss ───────────────────────────────────────────

        Compound(
            name: "Tirzepatide",
            slug: "tirzepatide",
            halfLifeHrs: 120,
            dosingRangeLowMcg: 2_500,
            dosingRangeHighMcg: 15_000,
            benefits: ["Significant weight loss", "Glucose control", "Improved insulin sensitivity"],
            sideEffects: ["Nausea", "Constipation", "Reflux", "Fatigue"],
            stackingNotes: "Titrate up slowly (2.5mg → 5 → 7.5 → 10 → 12.5 → 15) to manage GI side effects.",
            fdaStatus: .approved,
            summaryMd: "Tirzepatide is an FDA-approved dual GIP/GLP-1 agonist (Mounjaro/Zepbound). Most effective GLP-1 class peptide for weight loss to date.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 24,
            durationHours: 168,
            dosingFormula: "clamp(2500 + weeksOnCycle * 1250, 2500, 15000)",
            dosingUnit: "mcg",
            dosingFrequency: "weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 28,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left", "thigh-subq-right"],
            popularityRank: 1,
            effectsTimeline: "Week 1-2: initial appetite suppression, mild nausea during titration. Week 4: noticeable food-noise reduction, early water weight drop. Week 8-12: 5-8% body weight loss, clearer energy. Week 24+: 15-22% weight loss, improved insulin sensitivity, waist circumference drops. Titration (2.5 → 5 → 7.5 → 10 → 12.5 → 15 mg weekly) is what keeps GI side effects manageable.",
            mechanism: "Dual agonist of GIP and GLP-1 receptors. GLP-1R activation in the hypothalamus and brainstem suppresses appetite and slows gastric emptying; GLP-1R on pancreatic beta cells enhances glucose-dependent insulin secretion. GIP receptor activation improves adipose insulin sensitivity and — critically — blunts the aversive nausea of GLP-1 agonism via hindbrain area-postrema signaling, which is why tirzepatide is better tolerated than pure GLP-1s. Fatty-diacid side chain enables albumin binding for a ~5-day half-life.",
            risks: "GI side effects (nausea, vomiting, diarrhea, constipation) — most common, dose-dependent · Pancreatitis (rare but serious — severe abdominal pain warrants ER visit) · Gallbladder disease / gallstones · Loss of lean muscle mass (~25% of weight lost) · Resting heart rate bump · Thyroid C-cell tumor signal in rodents (MTC contraindication) · Diabetic retinopathy progression in existing DR · Rebound weight regain if stopped abruptly",
            mitigations: "Titrate slowly — never skip dose levels. Hit 1.6 g/kg protein daily and resistance-train 3x/week to preserve lean mass (Neeland et al. 2024 protocol). Take 4-6h fasted before surgery/endoscopy to avoid aspiration. Ondansetron or ginger for breakthrough nausea. Screen for personal/family history of medullary thyroid carcinoma (absolute contraindication). Monitor lipase/amylase, A1c, lipid panel quarterly. Taper down rather than stop cold to blunt regain."
        ),

        Compound(
            name: "Semaglutide",
            slug: "semaglutide",
            halfLifeHrs: 168,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 2_400,
            benefits: ["Weight loss", "Blood sugar regulation", "Appetite suppression", "Cardiovascular benefit"],
            sideEffects: ["Nausea", "Vomiting", "Diarrhea", "Constipation"],
            stackingNotes: "Titrate slowly. Monitor for hypoglycemia if combined with insulin.",
            fdaStatus: .approved,
            summaryMd: "Semaglutide is an FDA-approved GLP-1 receptor agonist (Ozempic/Wegovy). Originally for T2D, now approved for chronic weight management.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 24,
            durationHours: 168,
            dosingFormula: "clamp(250 + weeksOnCycle * 250, 250, 2400)",
            dosingUnit: "mcg",
            dosingFrequency: "weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 28,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left", "thigh-subq-right"],
            popularityRank: 2,
            effectsTimeline: "Week 1: appetite down, some nausea. Week 4 (0.5 mg dose): 2-4% weight loss, food cravings quieter. Week 12 (1.0 mg): 6-8% loss, improved A1c. Week 28+ (2.4 mg Wegovy dose): 12-15% weight loss plateau. Cardiovascular event risk drops ~20% in SELECT trial population over 3+ years. Full titration: 0.25 → 0.5 → 1.0 → 1.7 → 2.4 mg weekly over 16 weeks.",
            mechanism: "Selective GLP-1 receptor agonist with 94% homology to native GLP-1 and a fatty-acid modification giving it a 7-day half-life. Activates GLP-1R on pancreatic beta cells (glucose-dependent insulin release), hypothalamic POMC neurons (appetite suppression), and GI smooth muscle (delayed gastric emptying). Unlike tirzepatide, no GIP activity — so GI side effects are more prominent at comparable weight-loss doses.",
            risks: "Nausea/vomiting/diarrhea (more pronounced than tirzepatide at matched weight loss) · Pancreatitis · Gallstones / cholecystitis · Muscle mass loss (~35-40% of total lost — worse ratio than tirzepatide) · NAION (rare optic neuropathy signal 2024) · Thyroid C-cell tumors in rodents · Gastroparesis — can persist after discontinuation · Rebound hyperphagia off-cycle",
            mitigations: "Slower titration (4 weeks per step minimum) reduces nausea 40%. Protein target 1.6-2.2 g/kg + resistance training mandatory for body-comp quality. Avoid in personal/family MTC history or MEN 2. Full-body skin + eye exam baseline if risk factors for NAION (cardiovascular, diabetes). Pre-op fasting: 1 week hold for weekly dosing. Glucagon hypoglycemia kit if stacked with insulin/sulfonylurea. Long-term maintenance dose or slow taper to prevent rebound."
        ),

        Compound(
            name: "AOD-9604",
            slug: "aod-9604",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 500,
            benefits: ["Lipolysis", "Cartilage repair", "Non-diabetogenic"],
            sideEffects: ["Generally mild", "Injection site reaction"],
            stackingNotes: "Often combined with low-dose Ipamorelin for fat loss.",
            fdaStatus: .research,
            summaryMd: "AOD-9604 is the C-terminal fragment of GH (residues 176–191). Researched for lipolysis without GH's diabetogenic profile.",
            goalCategories: ["fat_loss", "recovery"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.5,
            peakEffectHours: 1,
            durationHours: 4,
            dosingFormula: "300",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 27,
            effectsTimeline: "Week 1: subtle — mild fatigue first few days. Week 2-4: abdominal and subcutaneous fat visibly softer, especially with morning fasted dosing + cardio. Week 4-8: measurable waist reduction without lean-mass change, no water retention, no hunger shift. Modest effect — failed phase 2b for placebo-beat efficacy but the effect is real if expectations are set appropriately. 5-days-on / 2-off daily protocol standard. Often stacked with Ipamorelin or 5-Amino-1MQ.",
            mechanism: "Modified C-terminal fragment of human growth hormone (residues 176-191 with a tyrosine N-terminal stabilizer). Does NOT bind the GH receptor — confirmed in binding studies. Acts through a distinct, partially characterized lipolytic pathway on adipocytes: enhances beta-3 adrenergic receptor-mediated lipolysis (triglyceride breakdown) and inhibits de novo lipogenesis (fat synthesis from carbs). No IGF-1 elevation, no anti-insulin effect, no anabolic activity — 'GH's weight-loss action without GH's side effects.' ~30-min half-life drives daily dosing.",
            risks: "Generally very well-tolerated — one of the cleanest compounds on this list · Mild fatigue first few days · Injection-site reactions rare · Phase 2b failed primary efficacy endpoint vs placebo — effect is modest, not dramatic · Theoretical immunogenicity with chronic use · Grey-market supply occasionally contaminated with actual hGH (different legal, metabolic, and risk profile) · No cancer concern due to no IGF-1 elevation · Pregnancy contraindicated · Unknown in pediatric / lactating populations",
            mitigations: "Morning fasted dosing (before cardio) maximizes the lipolytic window. 5-on / 2-off per day protocol. 250-500 mcg per day; 300 mcg is the modal dose. Pair with moderate cardio and protein-forward diet. Rotate injection sites. Vendor COA mandatory to rule out hGH contamination. Track waist/weight trends weekly since effect is modest. Discontinue if no measurable change after 8 weeks."
        ),

        Compound(
            name: "Retatrutide",
            slug: "retatrutide",
            halfLifeHrs: 144,
            dosingRangeLowMcg: 2_000,
            dosingRangeHighMcg: 12_000,
            benefits: ["Aggressive weight loss", "GIP/GLP-1/Glucagon triple agonism", "Glycemic control"],
            sideEffects: ["GI upset", "Fatigue", "Nausea"],
            stackingNotes: "Investigational. Titrate slowly.",
            fdaStatus: .research,
            summaryMd: "Retatrutide is a triple GIP/GLP-1/Glucagon receptor agonist in late-stage trials. Phase 2 weight loss exceeded Tirzepatide in head-to-head data.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 24,
            durationHours: 168,
            dosingFormula: "clamp(2000 + weeksOnCycle * 1000, 2000, 12000)",
            dosingUnit: "mcg",
            dosingFrequency: "weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 28,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 4,
            effectsTimeline: "Week 2: strong appetite suppression (stronger than semaglutide dose-for-dose). Week 8: 6-10% weight loss. Week 24: 15-18% loss. Week 48 (12 mg dose): 24.2% mean weight loss in NEJM phase 2; phase 3 TRIUMPH-4 showed 28.7% at 48 weeks. Weight-loss curve had not plateaued at 48w — unprecedented. Resting heart rate peaks +5-10 bpm around week 24 then declines.",
            mechanism: "Triple agonist of GIP, GLP-1, and glucagon receptors (the 'triple G'). GLP-1 reduces appetite, GIP improves insulin sensitivity and blunts nausea, glucagon uniquely increases energy expenditure and drives hepatic fat oxidation (why liver fat drops ~80% in MASLD trials). More potent than tirzepatide at GIP; weaker than native hormones at glucagon and GLP-1 — this asymmetric tuning is the key design insight. 6-day half-life via fatty-diacid albumin binding.",
            risks: "Dose-dependent nausea (60% at 12 mg vs 14% at lowest dose) · Vomiting, diarrhea, constipation · Heart rate elevation (glucagon-mediated) · Dysesthesia / paresthesia (new signal unique to retatrutide) · Pancreatitis signal (class effect) · Gallbladder disease · 18% trial discontinuation at 12 mg vs 4% placebo · Lean mass loss · Long-term CV, thyroid, and oncology data incomplete · Currently investigational (phase 3) — grey market supply quality varies",
            mitigations: "Much slower titration than tirzepatide: start 0.5 mg, increase by ≤1 mg every 4 weeks. 12 mg target is only for patients tolerating lower doses well — many stabilize at 6-8 mg. Protein 1.6-2.2 g/kg + resistance training non-negotiable. Monitor resting HR and BP monthly during dose escalation. Discontinue for unexplained persistent paresthesia. Baseline and 6-month lipase, A1c, TSH. Source only from vendors with published COAs given investigational status."
        ),

        // ── Other / cognitive / sexual ─────────────────────────────────────

        Compound(
            name: "PT-141",
            slug: "pt-141",
            halfLifeHrs: 2,
            dosingRangeLowMcg: 1_000,
            dosingRangeHighMcg: 2_000,
            benefits: ["Sexual desire", "Erectile function", "Libido (M+F)"],
            sideEffects: ["Nausea", "Flushing", "Headache", "Increased BP"],
            stackingNotes: "Take 30 min – 2 hr before activity. Avoid in uncontrolled hypertension.",
            fdaStatus: .approved,
            summaryMd: "PT-141 (Bremelanotide / Vyleesi) is a melanocortin agonist. FDA-approved for HSDD in premenopausal women.",
            goalCategories: ["libido"],
            administrationRoutes: ["subq", "nasal"],
            timeToEffectHours: 0.5,
            peakEffectHours: 1.5,
            durationHours: 8,
            dosingFormula: "1750",
            dosingUnit: "mcg",
            dosingFrequency: "as_needed",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 12,
            effectsTimeline: "15-45 min post-injection: flushing, warmth, mild nausea. 30 min - 2h: sexual desire and arousal noticeably elevated (MC4R effect). 2-8h: arousal window persists; effect largely independent of vascular erectile function (works where Viagra doesn't). Effects fully resolved by 24h. FDA-approved dosing in women (Vyleesi HSDD): 1.75 mg subq as needed, max 1 dose per 24h and 8 doses per month.",
            mechanism: "Cyclic heptapeptide analogue of alpha-MSH. Full MC4R agonist (Ki 0.2-0.7 nM) with activity at MC1R, MC3R. Acts centrally, not vascularly: MC4R activation in hypothalamus → Gs / cAMP → PKA/CREB → dopamine release in mesolimbic reward pathway + oxytocin and serotonin modulation. Net effect is increased sexual desire and reduced distress rather than increased blood flow — why it works for HSDD (desire disorder) and in men who fail PDE5 inhibitors. Minimal MC2R activity so no adrenal stimulation.",
            risks: "Nausea 40% (dose-dependent, worst first dose — can be severe) · Flushing 20% · Injection-site reactions 13% · Headache 11% · Transient BP +6/+3 mmHg · Skin hyperpigmentation (face, gums, breasts) especially with >8 doses/month; may not resolve on stopping · Theoretical melanoma risk from MC1R activation · Rare but serious: priapism in men (ischemic, requires ER) · Dose limit 1 per 24h, 8 per month · Contraindicated: uncontrolled hypertension, CVD history, pregnancy category X",
            mitigations: "Ondansetron 4 mg or 1g ginger 30 min pre-injection blunts nausea ~50%. Start at 1 mg subq to test response before full 1.75 mg. Monitor BP baseline and 30 min post-dose first few uses. Keep under 8 doses/30 days to limit hyperpigmentation. Avoid in men with CVD, uncontrolled HTN, priapism history, sickle-cell trait. Never combine with nitrates (severe hypotension). Annual dermatology check given MC1R activity. Baseline mole photography if using >1x/month. Discontinue for priapism >4h (ER), persistent hyperpigmentation, or new nevi changes."
        ),

        Compound(
            name: "Melanotan II",
            slug: "melanotan-ii",
            halfLifeHrs: 1,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 1_000,
            benefits: ["Skin tanning", "Libido", "Appetite suppression"],
            sideEffects: ["Nausea", "Flushing", "Mole darkening", "BP changes"],
            stackingNotes: "Start very low (250mcg). Build slowly to assess tolerance.",
            fdaStatus: .research,
            summaryMd: "Melanotan II is a non-selective melanocortin agonist. Stimulates melanin production for tanning.",
            goalCategories: ["skin_hair", "libido"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 1,
            peakEffectHours: 2,
            durationHours: 8,
            dosingFormula: "500",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 9,
            effectsTimeline: "Injection 1-3: nausea, flushing, yawning within 15-45 min — peak during loading phase, diminishes after ~10 doses. Week 1-2 (loading 0.25-0.5 mg daily): faint skin darkening begins. Week 3-4: visible tan, mole darkening near-universal, libido spikes (MC4R effect). Week 6-8: maintenance phase — 2x weekly maintains color. Tan fades ~8-12 weeks after stopping; mole darkening can persist months to near-permanent in hyper-responders.",
            mechanism: "Synthetic cyclic heptapeptide analog of alpha-MSH. Non-selective agonist of melanocortin receptors MC1R, MC3R, MC4R, and MC5R. MC1R on melanocytes → cAMP → PKA → CREB phosphorylation → MITF transcription → tyrosinase upregulation → eumelanin synthesis (the photoprotective dark pigment). MC4R in hypothalamus/brainstem → appetite suppression + sexual arousal (same pathway as PT-141 which is a selective MC4R agonist developed from MT-II research). MC3R/MC4R sympathetic activation → transient BP elevation, flushing, nausea.",
            risks: "Near-universal mole darkening + new nevi formation — clinically indistinguishable from early melanoma by dermoscopy alone · Melanoma theoretical risk (not proven causative but chronic melanocyte stimulation on UV-damaged skin is plausibly transformative) · Nausea (60% of users loading) · Facial flushing, yawning · Transient BP elevation · Spontaneous erections / priapism (case-reported ischemic priapism requiring ER) · Rhabdomyolysis (rare, non-medical use) · Rhomboid facial darkening (Addison-like hyperpigmentation) can be near-permanent · Contraindicated in uncontrolled hypertension, priapism history, pregnancy, hepatic impairment",
            mitigations: "Full-body dermatologist skin exam with mole mapping baseline, then every 6 months during use — non-negotiable. Photograph every mole before starting; compare monthly. Start at 0.25 mg only — many users never need more. Take ondansetron 4 mg or 1 g ginger 30 min pre-injection to blunt nausea. Antihistamine H1 pre-dose reduces flushing. Never combine with tanning bed (compounds melanoma risk). Use SPF 30+ — MT2 tan is not UV-protective equivalent. Avoid in family history of melanoma, >50 dysplastic nevi, Fitzpatrick I skin. Stop immediately and see dermatologist for any ABCDE mole changes. No use in men with cardiovascular disease, priapism history, or sickle-cell trait."
        ),

        Compound(
            name: "Selank",
            slug: "selank",
            halfLifeHrs: 0.3,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 750,
            benefits: ["Anxiolytic", "Cognitive enhancement", "Mood"],
            sideEffects: ["Generally mild", "Mild drowsiness"],
            stackingNotes: "Often combined with Semax for synergistic nootropic effect.",
            fdaStatus: .research,
            summaryMd: "Selank is a synthetic analogue of tuftsin researched for anxiety relief without sedation or dependence.",
            goalCategories: ["cognitive"],
            administrationRoutes: ["subq", "nasal"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 6,
            dosingFormula: "500",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 24,
            effectsTimeline: "Within 30-60 min (nasal): calm-alert state — anxiety noticeably reduced without sedation. Day 1-3: anxiolytic effect consistent; better social fluency, sleep quality improves. Week 1-2: stable mood, reduced rumination. Week 2-4 cycle: cumulative effect on cognitive flexibility. Half-life <30 min so effects are acute, not sustained — redose 1-3x daily. 10-30 day cycles then 2-4 week break is standard Russian protocol.",
            mechanism: "Synthetic heptapeptide (Thr-Lys-Pro-Arg-Pro-Gly-Pro) — a stabilized analogue of tuftsin (an endogenous immunomodulatory peptide). Anxiolytic action via modulation of GABAergic neurotransmission, increased brain BDNF and enkephalin expression, and balancing of serotonin/noradrenaline systems — but without GABA-A receptor direct binding, so no benzo-style sedation, tolerance, or dependence. Also upregulates BDNF mRNA and modulates cytokines (IL-6, TNF-alpha). Approved in Russia since 2004 (Peptogen) for generalized anxiety disorder.",
            risks: "Generally well-tolerated — among the cleanest nootropics on this list · Mild drowsiness occasionally · Rare injection-site reactions if subq route · Headache (infrequent) · No established dependence, tolerance, or withdrawal in Russian literature · Not FDA approved; Russian-origin supply quality variable · Limited Western RCTs · Theoretical immune modulation with chronic use (tuftsin family) · Unknown effects during pregnancy / lactation",
            mitigations: "Prefer intranasal over subq — higher brain bioavailability, fewer side effects, Russian protocol standard. 250-500 mcg per nostril, 2-3x daily. Cycle 10-30 days on, then 2-4 weeks off. Source from vendors with COAs. Start at 250 mcg single dose to assess response. Avoid in pregnancy, lactation, active autoimmune flares. Often stacked with Semax for balanced calm-focus — synergistic, not additive."
        ),

        Compound(
            name: "Semax",
            slug: "semax",
            halfLifeHrs: 0.3,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 1_000,
            benefits: ["BDNF/NGF boost", "Focus", "Memory", "Neuroprotection"],
            sideEffects: ["Generally mild", "Slight stimulation"],
            stackingNotes: "Pairs with Selank for balanced focus + calm.",
            fdaStatus: .research,
            summaryMd: "Semax is a Russian-developed ACTH analogue researched for stroke recovery, focus, and BDNF expression.",
            goalCategories: ["cognitive"],
            administrationRoutes: ["subq", "nasal"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 6,
            dosingFormula: "750",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 25,
            effectsTimeline: "Within 15-30 min (nasal): stimulant-like focus lift without the crash — feels like clean attention, not caffeine-edgy. Day 1-3: verbal recall and working memory noticeably sharper; motivation improves. Week 1-2: BDNF/NGF-driven effects emerge — learning speed, sustained attention. Week 2-4 cycle: neuroplasticity consolidation. Russian-approved for stroke recovery, ADHD, cognitive decline, optic nerve disease. 10-14 day cycles standard then 2-4 week break. Longer acute duration than Selank (~4-6h).",
            mechanism: "Heptapeptide — N-terminal fragment of ACTH (4-10) with a Pro-Gly-Pro stabilizing tail. Distinct from ACTH's adrenal effects (no cortisol stimulation). Three convergent mechanisms: (1) Rapid, robust BDNF and NGF mRNA upregulation in hippocampus and cortex — the neuroplasticity driver; (2) melanocortin receptor modulation (MC4R particularly) in brain influencing attention, memory, and neuroprotection; (3) enkephalinase inhibition, raising endogenous enkephalins (natural opioids) for mood/motivation. Approved in Russia since 1995; on the Russian List of Vital Medicines for ischemic stroke.",
            risks: "Generally very well-tolerated · Mild stimulation can disrupt sleep if dosed late (afternoon cutoff wise) · Occasional mild headache or nasal irritation (intranasal route) · Theoretical but not documented tolerance with chronic uninterrupted use · Russian clinical literature extensive but not validated to Western FDA standards · Enkephalinase inhibition raises theoretical interaction with opioid analgesics · Unknown in pregnancy/lactation · Source quality variable · Melanocortin pathway engagement means caution with MT1/MT2 co-use (receptor overlap)",
            mitigations: "Intranasal route — 250-600 mcg per nostril, 2-3x daily before 2 PM. 10-14 day cycles then 2-4 week break per Russian protocol. Pairs exceptionally well with Selank (stimulation + calm balance). Don't dose after 3 PM — sleep disruption. Avoid combining with opioid analgesics due to enkephalinase interaction. Hold during pregnancy, lactation, active psychiatric destabilization, or uncontrolled hypertension. Source with COA. Baseline no specific labs required for healthy users; check BP if hypertensive."
        ),

        Compound(
            name: "MOTS-c",
            slug: "mots-c",
            halfLifeHrs: 4,
            dosingRangeLowMcg: 5_000,
            dosingRangeHighMcg: 10_000,
            benefits: ["Mitochondrial function", "Insulin sensitivity", "Metabolic health", "Endurance"],
            sideEffects: ["Generally well tolerated", "Mild injection-site irritation"],
            stackingNotes: "Stacks well with NAD-precursors and longevity peptides.",
            fdaStatus: .research,
            summaryMd: "MOTS-c is a 16-amino-acid mitochondrial-derived peptide researched for metabolic regulation, insulin sensitivity, and exercise performance.",
            goalCategories: ["longevity", "fat_loss", "growth"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 4,
            peakEffectHours: 12,
            durationHours: 48,
            dosingFormula: "clamp(weightKg * 75, 5000, 10000)",
            dosingUnit: "mcg",
            dosingFrequency: "3x_weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 14,
            effectsTimeline: "Week 1-2: subtle — some users report mild energy improvement during exercise. Week 4: endurance during training noticeably up, recovery between sessions faster. Week 8-12: body-comp shifts favor fat loss over lean mass, insulin sensitivity markers improve on labs. All animal-model timelines — zero published human therapeutic trials. Community protocol: 5-10 mg 3x weekly for 8-12 weeks.",
            mechanism: "16-amino-acid peptide (MRWQEMGYIFYPRKLR) encoded within the 12S rRNA gene of the mitochondrial genome itself — one of the few known mitochondrial-derived peptides. Inhibits the folate-methionine cycle and de novo purine biosynthesis → AICAR accumulates → AMPK activation (the cellular low-energy sensor). AMPK downstream: GLUT4 glucose uptake ↑, fatty-acid oxidation ↑, mitochondrial biogenesis ↑. Under metabolic stress, MOTS-c translocates from cytoplasm to nucleus and regulates antioxidant response element (ARE) genes. Plasma levels decline with age; elevated transiently by exercise — the basis for the 'exercise mimetic' claim.",
            risks: "Zero human therapeutic trials — all efficacy claims are rodent-only · Injection-site reactions (common with analogue CB4211) · Theoretical hypoglycemia via AMPK-driven glucose uptake, especially combined with insulin or metformin · Potential lactic acidosis in mitochondrial dysfunction or impaired lactate clearance · Cancer context-dependent: AMPK activation is tumor-suppressive in some contexts, survival-supporting in others · Self-reported: insomnia, increased HR / palpitations, injection-site irritation, fever · WADA-banned · FDA Section 503A Category 2 — compounding pharmacies can't legally provide it · Immunogenicity (antibody formation) possible with impure sources",
            mitigations: "Treat as experimental — start at 2.5-5 mg 2-3x weekly, titrate only if tolerated. Baseline fasting glucose, A1c, lactate, liver enzymes, CBC; repeat at 4-8 weeks. Never stack with metformin, insulin, or sulfonylureas without close glucose monitoring (additive AMPK / glucose-lowering effects). Dose earlier in day to limit insomnia. Buy only from vendors with published third-party COAs — impurity immunogenicity is the dominant real-world risk. Avoid in active cancer, mitochondrial disease, pregnancy, insulin-dependent diabetes, or recent myocardial infarction."
        ),

        Compound(
            name: "Epithalon",
            slug: "epithalon",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 5_000,
            dosingRangeHighMcg: 10_000,
            benefits: ["Telomere lengthening", "Sleep improvement", "Melatonin regulation"],
            sideEffects: ["Generally mild", "Vivid dreams"],
            stackingNotes: "Cycle 10 days on, 6 months off (Russian protocol).",
            fdaStatus: .research,
            summaryMd: "Epithalon is a tetrapeptide researched for telomere lengthening and circadian regulation.",
            goalCategories: ["longevity", "sleep"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 48,
            durationHours: 240,
            dosingFormula: "10000",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 15,
            effectsTimeline: "Day 1-3 (10-day on cycle): vivid dreams reported by most users — the first signal it's working on the pineal / melatonin axis. Week 1: sleep quality improves, circadian rhythm feels more stable. Week 2-4: subjective fatigue drops, night-shift tolerance improves. Labs: Russian studies show telomerase activation and subjective immune markers shifting favorably. Canonical Khavinson protocol: 5-10 mg/day for 10 days, then 3-6 months off, repeat 1-2x yearly.",
            mechanism: "Synthetic tetrapeptide Ala-Glu-Asp-Gly — the active fragment of Epithalamin, a pineal gland polypeptide. Primary mechanism: induces hTERT (telomerase reverse transcriptase) expression in somatic cells that normally have low telomerase — extends replicative capacity past the Hayflick limit in cell culture and elongates telomeres measurably. Secondary effects: restores night-time melatonin rhythm (pineal mimetic), modulates circadian gene expression, regulates cortisol/thyroid axis. Works primarily as a bioregulator signaling peptide rather than via a classical receptor.",
            risks: "Very short half-life (~30 min) — why pulse dosing is the protocol · Generally reported well-tolerated in Russian observational studies, but safety monitoring was not rigorous · Vivid dreams / occasionally disturbing dreams · Mild injection-site irritation · Theoretical cancer concern — telomerase activation is a hallmark of tumor immortalization, so sustained activation in someone with undiagnosed malignancy is biologically concerning · Limited Western-standard RCT data · Can shift cortisol/thyroid — may unmask subclinical endocrine issues · Pregnancy and active cancer contraindicated",
            mitigations: "Strictly pulse-dose — 10 days on, then minimum 3 months off (Khavinson's protocol). Never run continuously. Baseline and annual full-body dermatology check plus age-appropriate cancer screening before each cycle. Baseline thyroid (TSH, free T4) and morning cortisol. Evening dosing aligns with natural pineal activity. Avoid <5 years post-cancer remission, active malignancy, pregnancy, or uncontrolled thyroid disease. Source only with COA — the peptide is easy to synthesize but easy to contaminate. Log dreams/sleep quality during cycles to gauge response."
        ),

        Compound(
            name: "DSIP",
            slug: "dsip",
            halfLifeHrs: 0.3,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["Sleep depth", "Stress modulation"],
            sideEffects: ["Generally well tolerated", "Mild headache"],
            stackingNotes: "Take 30 min before bed for sleep onset support.",
            fdaStatus: .research,
            summaryMd: "DSIP (Delta Sleep-Inducing Peptide) is researched for sleep architecture support and stress response modulation.",
            goalCategories: ["sleep"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 6,
            dosingFormula: "200",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 34,
            effectsTimeline: "Night 1: sleep-onset latency shortens noticeably, more vivid dreams. Week 1: sleep architecture improves — more delta-wave sleep documented on EEG. Week 2-4: stress-modulation effect emerges; anxiety lower, cortisol flatter. Works acutely, no loading needed. Few users run it daily long-term given short half-life — pulse-style use is easier.",
            mechanism: "Delta Sleep-Inducing Peptide — a 9-amino-acid neuropeptide discovered in rabbit brain. Despite the name, it doesn't directly induce delta sleep in a drug-like way — it's a stress-modulating neuropeptide that indirectly promotes better sleep architecture. Mechanism incompletely characterized: modulates HPA axis (flattens cortisol), interacts with opioidergic and GABAergic systems indirectly, may cross blood-brain barrier to influence circadian regulation. Very short half-life (~7-15 min) but durable effects suggest cascade signaling.",
            risks: "Very short half-life — effects are subtle, not drug-like · Mild headache occasionally · Rare vivid / disturbing dreams · Injection-site reactions rare · Generally well-tolerated — among the safest sleep peptides · Theoretical HPA-axis modulation could affect cortisol-dependent conditions (Addison's, Cushing's — both rare) · No FDA approval · Limited Western safety data; Russian origin literature · Unknown in pregnancy",
            mitigations: "Dose 30-60 min before bed subq. 100-300 mcg typical. No tolerance or desensitization documented — can be used as-needed. Pair with good sleep hygiene — DSIP amplifies baseline sleep rather than overriding poor habits. Not a melatonin replacement for circadian shifts (jet lag). Source with COA. Avoid in pregnancy or on sedatives/hypnotics without supervision. Stop for persistent nightmares or morning grogginess > 2 weeks."
        ),

        Compound(
            name: "KPV",
            slug: "kpv",
            halfLifeHrs: 1,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 500,
            benefits: ["Anti-inflammatory", "Gut healing", "Skin"],
            sideEffects: ["Generally well tolerated"],
            stackingNotes: "Combine with BPC-157 for gut protocol.",
            fdaStatus: .research,
            summaryMd: "KPV is a tripeptide fragment of α-MSH researched for anti-inflammatory and immunomodulatory effects.",
            goalCategories: ["immune", "recovery", "skin_hair"],
            administrationRoutes: ["subq", "oral"],
            timeToEffectHours: 1,
            peakEffectHours: 2,
            durationHours: 8,
            dosingFormula: "500",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 32,
            effectsTimeline: "Oral or subq. Week 1: gut symptoms (reflux, loose stools, IBS flares) noticeably calmer. Week 2-4: joint and soft-tissue inflammation down, skin-barrier repair accelerated in dermatitis / rosacea. Week 4-8: immune modulation stable; often combined with BPC-157 in a gut-healing protocol. 30-60 day cycles typical.",
            mechanism: "Tripeptide Lys-Pro-Val — the C-terminal fragment of alpha-MSH (residues 11-13). Distinct from MT1/MT2 mechanism because it retains alpha-MSH's anti-inflammatory activity WITHOUT melanocortin receptor agonism — so no pigmentation, no libido effects, no cardiovascular activation. Mechanism: suppresses NF-kB nuclear translocation in macrophages and T cells → downregulates pro-inflammatory cytokines (TNF-alpha, IL-1, IL-6, IL-8). Also inhibits mast cell degranulation and reduces neutrophil chemotaxis. Orally stable — intestinal absorption sufficient for GI-local effect.",
            risks: "Generally very well-tolerated — one of the gentlest compounds on this list · Mild GI upset in some users · Injection-site reactions rare · Theoretical immune suppression with very high chronic doses · Unknown effect in pregnancy / lactation · Grey-market status — no FDA approval · Vendor purity variable · Contraindicated (theoretically) in active autoimmune flare — KPV suppresses useful immune activity in that window",
            mitigations: "Oral route for GI-specific symptoms (ulcerative colitis, IBS, SIBO-adjacent inflammation) — preserves gut-localized action. Subq for systemic inflammation, skin, or joint use. 250-500 mcg/day typical. Pair with BPC-157 for synergistic gut-repair protocol. Baseline inflammatory markers (hs-CRP, ESR) for tracking. Avoid in active sepsis or infection you want immune system to clear. Source with COA. Minimal labs needed for healthy users."
        ),

        Compound(
            name: "LL-37",
            slug: "ll-37",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 1_000,
            benefits: ["Antimicrobial", "Wound healing", "Anti-biofilm"],
            sideEffects: ["Injection-site reaction", "Mild flushing"],
            stackingNotes: "Researched for chronic Lyme/biofilm protocols.",
            fdaStatus: .research,
            summaryMd: "LL-37 is a human cathelicidin antimicrobial peptide researched for chronic infections and biofilm disruption.",
            goalCategories: ["immune"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 1,
            peakEffectHours: 2,
            durationHours: 6,
            dosingFormula: "500",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 33,
            effectsTimeline: "Week 1-2: fatigue or mild flu-like response common first few doses — the 'cytokine storm' aftermath of biofilm disruption. Week 2-4: chronic-Lyme-symptom users report energy and joint improvements as biofilms break. Week 4-8: antimicrobial effect stabilizes; works best in combination antibiotic / antimicrobial protocols. Cycle 30-60 days then break.",
            mechanism: "37-amino-acid human cathelicidin antimicrobial peptide — the only mature cathelicidin in humans. Cationic amphipathic structure binds negatively charged bacterial membranes and disrupts them directly (pore formation) — effective against Gram-positive, Gram-negative, mycobacteria, fungi, enveloped viruses, and crucially, BIOFILMS (where most conventional antibiotics fail). Also immunomodulatory: chemoattracts neutrophils/monocytes/T cells, neutralizes LPS, modulates TLR signaling, promotes wound healing.",
            risks: "Flu-like symptoms from biofilm breakdown / LPS release ('Herxheimer reaction') · Injection-site reactions · Can over-activate mast cells → histamine-related flushing / hives · Theoretical: cathelicidin is dysregulated in rosacea and some inflammatory skin conditions — LL-37 elevation might worsen those · Autoimmune flare theoretical (cathelicidin involved in lupus, psoriasis pathogenesis) · No FDA approval · Limited chronic-use safety data · Immunogenicity possible",
            mitigations: "Start at 100 mcg to assess Herxheimer tolerance. Pair with binders (activated charcoal, bentonite clay) and hydration to manage LPS release symptoms. Evening dosing so Herx-type malaise happens during sleep. Cycle 30-60 days on, minimum 4 weeks off. Avoid in active rosacea, lupus, psoriasis flares, pregnancy. Best used as adjunct to antimicrobial / antibiotic protocols for chronic infections, not solo. Baseline hs-CRP, ferritin (markers of hidden infection). Stop for severe Herx > 72h, new rash, or respiratory distress."
        ),

        // ── Extended 60-compound catalog (popularity-ranked from Reddit,
        //    Looksmax, vendor catalogs, and biohacker community signal) ──

        Compound(
            name: "IGF-1 LR3",
            slug: "igf-1-lr3",
            halfLifeHrs: 20,
            dosingRangeLowMcg: 20,
            dosingRangeHighMcg: 60,
            benefits: ["Muscle hyperplasia (new muscle cells)", "Enhanced recovery", "Fat metabolism", "Endurance"],
            sideEffects: ["Hypoglycemia", "Joint pain", "Organ growth concerns", "Headache"],
            stackingNotes: "Advanced users only. Reconstitute with acetic acid, not BAC water. Monitor blood glucose.",
            fdaStatus: .research,
            summaryMd: "IGF-1 LR3 (Long R3 IGF-1) is a modified analogue of insulin-like growth factor 1 with extended half-life (~20h vs ~15min for native IGF-1). Researched for muscle hyperplasia and satellite cell activation. Potent — reserved for experienced users.",
            goalCategories: ["growth", "recovery"],
            administrationRoutes: ["subq", "im"],
            timeToEffectHours: 1,
            peakEffectHours: 4,
            durationHours: 24,
            dosingFormula: "40",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 1.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 16,
            effectsTimeline: "Day 1-2: noticeable pump during training, mild hypoglycemia warning signs if under-fed. Week 1-2: recovery between sessions faster, skin fuller. Week 3-4: muscle fullness visible, strength plateau broken. Week 4-6: measurable lean mass. Typical 4-6 week cycles followed by 4-8 weeks off — chronic use raises severe risks. 20-30h half-life, so once-daily dosing holds IGF-1 signal steady rather than pulsed.",
            mechanism: "Modified IGF-1 analogue — glutamic-acid-to-arginine substitution at position 3 plus a 13-amino-acid N-terminal extension. These changes reduce IGF binding protein (IGFBP) affinity >100-fold, so nearly 100% of circulating drug is free and bioactive (vs 1-2% of native IGF-1). Activates IGF-1R tyrosine kinase → PI3K/Akt/mTOR (protein synthesis, anti-apoptosis, GLUT4 glucose uptake) and Ras/MAPK/ERK (cell cycle, proliferation). The IGFBP bypass also removes IGFBP's independent tumor-suppressive activity, which is the core safety problem.",
            risks: "Hypoglycemia — most immediate and potentially fatal (seizures, LOC); LR3's 20-30h half-life prolongs the window · Cancer acceleration — IGF-1R activation is one of the best-characterized oncogenic pathways in biology; epidemiology links elevated IGF-1 to prostate, breast, colorectal, thyroid cancer · Acromegaly-like changes with chronic use (jaw/hand/foot growth, organ enlargement, cardiomyopathy) · Hepatic and cardiac hypertrophy · Joint pain, CTS-like paresthesias · Suppression of endogenous GH/IGF-1 axis · Insulin co-administration has killed bodybuilders — the combination is catastrophic · No human FDA trials; FDA Category 2",
            mitigations: "ADVANCED USERS ONLY. Never combine with exogenous insulin. Eat 30-50g carb + 20g protein within 30 min of injection to pre-empt hypoglycemia. Keep fast-acting glucose (juice, glucose tabs) on-person every hour post-injection for first 6 hours. Start 20 mcg only; never exceed 60 mcg/day. Strict 4-week cycles max, 6-8 weeks off. Full cancer screen baseline (dermatology, colonoscopy, PSA/mammogram, complete metabolic) — any hint of malignancy is absolute contraindication. Echocardiogram baseline and after each cycle if running repeatedly. Monitor fasting glucose, A1c, IGF-1, liver enzymes quarterly. Do not use pre-sleep (overnight hypoglycemia risk). Avoid if family history of prostate/breast/colorectal cancer, diabetes, or cardiomyopathy."
        ),

        Compound(
            name: "Kisspeptin-10",
            slug: "kisspeptin-10",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 500,
            benefits: ["Stimulates GnRH release", "HPG axis support", "Testosterone / LH elevation", "Libido"],
            sideEffects: ["Nausea", "Flushing", "Rapid heartbeat"],
            stackingNotes: "Trending in looksmaxxing circles for hormonal optimization. Individual response highly variable.",
            fdaStatus: .research,
            summaryMd: "Kisspeptin-10 is a decapeptide fragment of kisspeptin that stimulates GnRH release from the hypothalamus, driving the HPG axis. Researched for hypogonadism, fertility, and hormonal rebalancing.",
            goalCategories: ["libido", "growth"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 2,
            dosingFormula: "250",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 17,
            effectsTimeline: "30-90 min post-injection: transient LH/FSH surge, can feel as mild warmth or chest flutter. Week 1-2: morning testosterone modestly improves in HPG-intact men. Week 4: subjective libido, energy, and confidence uptick in responders; non-responders are common (HPG axis must be functional). Week 6-8: labs may show LH up, T up 20-40%. Fades quickly off — not a TRT replacement, more a pulsatile restart. Trending in looksmaxxing circles with unclear long-term data.",
            mechanism: "Decapeptide fragment of kisspeptin-54, the endogenous signal from KISS1 neurons in the hypothalamic arcuate nucleus that governs GnRH release and gates pubertal onset. Binds KISS1R (GPR54) on GnRH neurons → increased GnRH pulse frequency → pituitary LH and FSH surge → testicular T production (men) or ovarian follicle recruitment (women). Works upstream of HCG — stimulates the body's own LH rather than replacing it. Half-life only ~30 minutes, so effects are pulsatile and short.",
            risks: "Nausea, flushing, rapid heartbeat (parallel to GnRH agonist flare) · Transient BP bumps · Anecdotal mood shifts as T rises · Headache · Potential fertility dysregulation if dosed erratically — chronic continuous kisspeptin can paradoxically DOWN-regulate GnRH pulsing (same desensitization seen with GnRH agonists) · Unknown long-term cancer effect via T elevation on any undiagnosed prostate/breast cancer · No large RCTs in healthy men · Grey-market purity highly variable",
            mitigations: "Pulse dosing only — 2-3x weekly max, not daily, to preserve HPG pulse architecture. Baseline + 6-week labs: total T, free T, LH, FSH, estradiol, SHBG, prolactin, PSA (men), hs-CRP. Avoid in prostate cancer history, active breast cancer, uncontrolled cardiovascular disease, or pregnancy. Don't stack with HCG or testosterone — redundant and signal-confusing. Source only from third-party tested vendors (COA). Hold during any unexplained chest pain or palpitation. Re-assess after 8 weeks — if no lab or subjective response, the issue is downstream (testicular or pituitary), kisspeptin won't fix it."
        ),

        Compound(
            name: "5-Amino-1MQ",
            slug: "5-amino-1mq",
            halfLifeHrs: 4,
            dosingRangeLowMcg: 50_000,
            dosingRangeHighMcg: 150_000,
            benefits: ["NNMT inhibition", "NAD+ preservation", "Fat oxidation", "Energy / metabolism"],
            sideEffects: ["GI upset", "Headache", "Mild fatigue"],
            stackingNotes: "Can be taken orally. Often combined with MOTS-c and NAD+ for metabolic stack.",
            fdaStatus: .research,
            summaryMd: "5-Amino-1MQ is a small-molecule NNMT (nicotinamide N-methyltransferase) inhibitor that preserves cellular NAD+ and disinhibits fat metabolism. Popular emerging compound for body composition and energy.",
            goalCategories: ["fat_loss", "longevity"],
            administrationRoutes: ["oral", "subq"],
            timeToEffectHours: 2,
            peakEffectHours: 4,
            durationHours: 12,
            dosingFormula: "75000",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 0,
            storageTemp: "room",
            storageMaxDays: 365,
            recommendedSiteIds: [],
            popularityRank: 18,
            effectsTimeline: "Week 1-2: mild headache as NAD+ rises, some transient nausea. Week 2-4: basal energy noticeably higher, workouts feel easier. Week 4-8: slow steady fat loss without hunger change, especially abdominal. Week 8-12: body composition shifts — lean mass preserved, adipose tissue browning favored. Unlike GLP-1s it doesn't suppress appetite — mechanism is cellular not neural. Cycle 6-8 weeks on, 2-4 weeks off.",
            mechanism: "Small-molecule (not a peptide — quinolinium derivative) selective inhibitor of nicotinamide N-methyltransferase (NNMT). NNMT is overexpressed in obese adipose tissue where it wastes SAM and nicotinamide to produce 1-methylnicotinamide. Inhibiting NNMT → more nicotinamide flows into NAD+ salvage pathway → NAD+ levels rise in adipocytes → SIRT1 and AMPK activate → fat oxidation, mitochondrial biogenesis, and WAT browning. The compound targets the fat cell itself rather than appetite or gut hormones — complementary mechanism to GLP-1s.",
            risks: "No published human trials — safety data is all preclinical/anecdotal · Theoretical SAM/SAH imbalance affecting methylation (DNA, histones, neurotransmitters) with chronic use · Hepatic metabolism — caution in liver disease · Mild headache, transient nausea, blood pressure changes reported anecdotally · Could amplify NAD+-precursor supplements (NMN, NR) effects · Potential hypoglycemia enhancement when stacked with diabetes meds due to improved insulin sensitivity · Pregnancy contraindicated · No cancer signal but also no oncology surveillance data",
            mitigations: "Start at 50 mg/day oral to assess tolerance. Cap at 100-150 mg/day. Take with food to reduce headache/nausea. Cycle 8 weeks on, 2-4 weeks off — avoid chronic continuous use given SAM/methylation concerns. Don't combine with NMN/NR at full doses on same day — separate by 6+ hours. Baseline + 8-week liver enzymes (ALT, AST), basic metabolic panel. Monitor fasting glucose if on insulin or sulfonylureas. Avoid in hepatic impairment, active cancer, pregnancy, or severe metabolic disease without supervision. Hold for persistent headache, RUQ pain, or jaundice."
        ),

        Compound(
            name: "HGH Fragment 176-191",
            slug: "hgh-fragment-176-191",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 500,
            benefits: ["Targeted fat loss", "No water retention", "No GH suppression", "Metabolic enhancement"],
            sideEffects: ["Injection site reaction", "Mild fatigue"],
            stackingNotes: "Best on empty stomach, morning dosing. Parent compound to AOD-9604.",
            fdaStatus: .research,
            summaryMd: "HGH Fragment 176-191 is the C-terminal residues of growth hormone, responsible for GH's lipolytic action without the anabolic or insulin-antagonistic effects. Researched for stubborn fat areas.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.5,
            peakEffectHours: 1,
            durationHours: 4,
            dosingFormula: "400",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 19,
            effectsTimeline: "Week 1: some fatigue in first few days as fat oxidation ramps. Week 2-4: visible reduction in stubborn abdominal and subcutaneous fat, without water retention or hunger change. Week 4-8: typical cut-cycle duration — measurable waist reduction. Unlike full GH or GHRPs, no IGF-1 rise, no insulin resistance, no muscle recomp effect. Best on empty stomach (morning or pre-fasted cardio). Often stacked with Ipamorelin for dual fat-loss + GH axis activation.",
            mechanism: "Synthetic 15-amino-acid fragment corresponding to residues 176-191 of full human growth hormone — the C-terminal end responsible for GH's lipolytic action. Does NOT bind the GH receptor (so no IGF-1 elevation, no anabolic/diabetogenic effects). Instead acts through a distinct, less-characterized lipolytic receptor on adipocytes. Enhances beta-3 adrenergic receptor-mediated lipolysis and inhibits lipogenesis (fat synthesis from carbohydrates) — 'GH's weight-loss effects without GH's side effects.' Short half-life (~30 min) drives the 5-on/2-off daily protocol.",
            risks: "Generally well-tolerated — one of the cleaner compounds on this list · Injection site reactions · Mild fatigue first few days · No FDA approval (failed phase 2b trials for efficacy vs placebo — the effect is real but modest) · Theoretical allergic / immunogenic reactions with chronic use · Because it's a GH fragment, sometimes erroneously assumed GH-like — it's not, but grey-market supply can be contaminated with actual hGH (buy with COA) · Pregnancy contraindicated · Minimal cancer risk theory given no IGF-1 elevation",
            mitigations: "Morning or pre-fasted-cardio dosing on empty stomach maximizes the lipolytic window. 5-days-on, 2-off schedule per FaFa protocol. Start 250 mcg, cap 500 mcg daily. Pair with moderate cardio and protein-forward diet — the mechanism is 'unlock stored fat'; if you don't burn it, it re-deposits. Rotate injection sites (abdomen bilateral). Baseline lipid panel helpful — effect is on adipose, not serum triglycerides directly. Vendor COA mandatory to rule out hGH contamination. Stop if unexplained fatigue > 2 weeks or injection-site lumps (fat atrophy)."
        ),

        Compound(
            name: "Follistatin 344",
            slug: "follistatin-344",
            halfLifeHrs: 24,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["Myostatin inhibition", "Muscle hyperplasia", "Strength gains", "Growth beyond genetic limits"],
            sideEffects: ["Tendon strain risk", "Joint pain", "Headache"],
            stackingNotes: "Extremely potent. Local injection preferred for targeted muscle growth. Short cycles only.",
            fdaStatus: .research,
            summaryMd: "Follistatin 344 is a glycoprotein that binds and neutralizes myostatin, a negative regulator of muscle growth. Researched for hyperplasia (true new muscle cell formation) rather than hypertrophy alone.",
            goalCategories: ["growth"],
            administrationRoutes: ["im", "subq"],
            timeToEffectHours: 24,
            peakEffectHours: 48,
            durationHours: 72,
            dosingFormula: "200",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["glute-im-left", "glute-im-right", "abdomen-subq-left"],
            popularityRank: 20,
            effectsTimeline: "Week 1: injection soreness at site. Week 2-3: strength gains ahead of visible size. Week 4: measurable muscle mass at injected site (local use) or systemic (subq) — hyperplasia signal. Day-to-day recovery noticeably faster. Most users cycle 2-4 weeks only due to potency. Week 5+ without break: tendon/joint overload risk rises as muscle outpaces connective tissue adaptation.",
            mechanism: "339-residue glycoprotein (342/344 refers to the larger isoform) that binds and neutralizes myostatin (GDF-8), the negative regulator of muscle growth. Also binds activin A (another myostatin-family negative regulator) and some BMPs. Blocking myostatin removes the brake on satellite cell activation and muscle fiber proliferation — drives true hyperplasia (new muscle cells) alongside hypertrophy (existing fiber growth). Mechanism is a 'release the brake' rather than 'push the gas.' Half-life ~24h; local IM injection can yield targeted regional growth.",
            risks: "Tendon and ligament strain — muscle grows faster than connective tissue can remodel · Joint pain, especially in rapidly growing muscle groups · Possible cardiac hypertrophy (myocardium is a muscle too) · Organ growth concerns with chronic use · Theoretical cancer risk — myostatin inhibition has complex effects on cell proliferation · Extremely potent — easy to overshoot · Immunogenicity with repeated use · Limited human data · WADA-banned · Hormonal shifts (activin A also regulates reproductive hormones) possible",
            mitigations: "Short cycles only — 2-4 weeks max, then minimum 6 weeks off. Conservative dosing: start 100 mcg/day, cap 300 mcg/day. Local IM injection into a target muscle localizes growth and reduces systemic exposure (cardiac, gonadal). Reduce training volume 20% during cycle — connective tissue cannot keep up with muscle gain rate. Baseline echocardiogram if running >1 cycle. Full cancer screen + hormonal panel (LH, FSH, estradiol, inhibin B) baseline and post-cycle. Avoid in active cancer, cardiac hypertrophy, pregnancy. Stop for any tendon pain, persistent joint swelling, or unexplained dyspnea."
        ),

        Compound(
            name: "NAD+",
            slug: "nad-plus",
            halfLifeHrs: 1,
            dosingRangeLowMcg: 50_000,
            dosingRangeHighMcg: 300_000,
            benefits: ["Cellular energy", "Mental clarity", "Longevity pathway support", "Recovery"],
            sideEffects: ["Flushing", "Chest tightness (infusion)", "Nausea"],
            stackingNotes: "Not a peptide but a staple in biohacking stacks. Slow subq/IM infusions tolerate better than push injections.",
            fdaStatus: .research,
            summaryMd: "NAD+ (nicotinamide adenine dinucleotide) is a coenzyme central to energy metabolism, DNA repair, and sirtuin activation. Injectable NAD+ has become a core longevity protocol component.",
            goalCategories: ["longevity"],
            administrationRoutes: ["subq", "im", "iv"],
            timeToEffectHours: 0.5,
            peakEffectHours: 1,
            durationHours: 8,
            dosingFormula: "100000",
            dosingUnit: "mcg",
            dosingFrequency: "3x_weekly",
            bacWaterMlDefault: 5.0,
            storageTemp: "refrigerated",
            storageMaxDays: 14,
            recommendedSiteIds: ["abdomen-subq-left", "glute-im-left"],
            popularityRank: 21,
            effectsTimeline: "Day 1: subq/IM injection burns sharply for 30-60s then fades. Fatigue or mild nausea rest of day one. Week 1: energy, sleep quality, mental clarity noticeably up in deficient users; healthy users report subtle shifts. Week 2-4: endurance during training improves, recovery faster. Week 6+: cognitive fog lifts especially in post-COVID, chronic fatigue, alcohol recovery, or high-training-load populations. IV route (100-500 mg over 2-4h) more intense but smoother. Effects fade within weeks of stopping.",
            mechanism: "NAD+ (nicotinamide adenine dinucleotide) is a coenzyme required by hundreds of enzymes: electron-transport chain for ATP synthesis, sirtuins (SIRT1-7) for longevity signaling and NF-kB suppression, PARPs for DNA damage repair, CD38/CD157 for cell signaling. NAD+ itself doesn't cross cell membranes — CD38 breaks injected NAD+ into nicotinamide, which cells import and rebuild into NAD+ via salvage pathway. So injectable NAD+ is effectively a slow-release nicotinamide delivery system. Heart muscle is one of the few tissues that can absorb intact NAD+.",
            risks: "Infusion-rate dependent: nausea, chest tightness, flushing, abdominal cramping if IV pushed too fast · Subq/IM burns intensely at injection site (acidic pH ~3.5-4.0 vs body 7.4) · Injection site soreness 24-48h · Sterile abscesses / firm lumps if fluid doesn't disperse · Headache from cellular ramp-up · Paradoxical fatigue 6-12h post · Rare: heart palpitations, BP swings, anaphylaxis · Theoretical insulin sensitivity changes · Cancer treatment interference possible · Interactions with BP meds, anticoagulants, antidepressants",
            mitigations: "Use isotonic bacteriostatic water, not plain BAC, for reconstitution — buffers the acidic pH and cuts the sting. Inject slowly over 30-60s. IM (glute, quad) hurts less than subq. Start 50-100 mg to assess response. For IV: never faster than 100 mg/30 min. Pair with food and hydration pre-injection. Rotate sites daily. Baseline labs: CBC, CMP, fasting glucose. Avoid during active cancer treatment, in pregnancy, on warfarin, or with uncontrolled arrhythmia. Stop for persistent palpitations, severe flushing, or escalating injection pain."
        ),

        Compound(
            name: "Cagrilintide",
            slug: "cagrilintide",
            halfLifeHrs: 168,
            dosingRangeLowMcg: 600,
            dosingRangeHighMcg: 2_400,
            benefits: ["Appetite suppression", "Gastric emptying delay", "Weight loss", "Satiety"],
            sideEffects: ["Nausea", "Constipation", "Injection site reaction"],
            stackingNotes: "Amylin analog. Titrate slowly. Often combined with semaglutide or tirzepatide for stronger weight loss.",
            fdaStatus: .research,
            summaryMd: "Cagrilintide is a long-acting amylin analogue researched for obesity. Delays gastric emptying and enhances satiety. Works synergistically with GLP-1 agonists in combination therapies.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 24,
            durationHours: 168,
            dosingFormula: "clamp(600 + weeksOnCycle * 300, 600, 2400)",
            dosingUnit: "mcg",
            dosingFrequency: "weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 28,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left"],
            popularityRank: 22,
            effectsTimeline: "Week 1-2: mild nausea, constipation, early satiety — gastric emptying delay kicking in. Week 4: appetite suppression stable, weight loss beginning (~1-2%). Week 12-24: ~6-11% weight loss as monotherapy. Week 52-68 (CagriSema with semaglutide): 13-17% weight loss, 73% achieve A1c ≤6.5% in T2D. Weekly titration: 0.25 → 0.5 → 1.0 → 1.7 → 2.4 mg (often paired with matching semaglutide dose).",
            mechanism: "Long-acting amylin analogue with fatty-diacid albumin-binding moiety giving ~7-day half-life (weekly dosing). Amylin is a pancreatic beta-cell co-hormone with insulin. Cagrilintide activates amylin receptors (AMY1/2/3 — calcitonin receptors coupled with RAMP1/2/3) in the area postrema and hypothalamus. Three effects: (1) delayed gastric emptying prolongs satiety, (2) suppressed postprandial glucagon blunts liver glucose dumping, (3) central satiety signaling independent of GLP-1 pathway. Complementary — not redundant — with GLP-1 agonists, hence CagriSema's superior weight loss vs semaglutide monotherapy.",
            risks: "GI side effects in 72.5% (with CagriSema) vs 34% placebo — nausea, vomiting, diarrhea, constipation · Injection-site reactions more prominent than GLP-1s · Aspiration risk during anesthesia (gastric emptying delay — parallel GLP-1 concern) · Hypoglycemia when stacked with insulin / sulfonylureas · Not FDA approved as of early 2026 · No independent CV outcome data yet · Thyroid C-cell tumor signal theoretical when combined with semaglutide (GLP-1 class effect) · Dehydration from prolonged N/V · Pregnancy contraindicated",
            mitigations: "Titrate weekly per protocol — never skip doses. Hold 20-24 days before elective surgery or endoscopy (3+ half-lives clearance). Prioritize fluids and electrolytes during titration to prevent dehydration-induced AKI. Baseline and quarterly A1c, lipase, renal function. Screen for personal/family history of MTC or MEN 2 before stacking with GLP-1s. Dose abdominal subq rotating L/R/thigh. Avoid in gastroparesis, active pancreatitis, severe GI motility disorders. Stop for unrelenting vomiting > 48h, severe abdominal pain, or A1c drop > 1.5 on combined regimen (hypoglycemia risk)."
        ),

        Compound(
            name: "Dihexa",
            slug: "dihexa",
            halfLifeHrs: 4,
            dosingRangeLowMcg: 5_000,
            dosingRangeHighMcg: 15_000,
            benefits: ["Cognitive enhancement", "Memory formation", "Neuroprotection", "Synaptogenesis"],
            sideEffects: ["Headache", "Brain fog initially", "Limited long-term safety data"],
            stackingNotes: "Crosses the blood-brain barrier. Conservative cycling (4 weeks on, 4+ weeks off) due to limited long-term data.",
            fdaStatus: .research,
            summaryMd: "Dihexa is an angiotensin IV analogue researched as a potent nootropic — reportedly orders of magnitude more active than BDNF at promoting new synaptic connections. Experimental; limited human data.",
            goalCategories: ["cognitive"],
            administrationRoutes: ["oral", "subq"],
            timeToEffectHours: 1,
            peakEffectHours: 2,
            durationHours: 8,
            dosingFormula: "10000",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 0,
            storageTemp: "room",
            storageMaxDays: 365,
            recommendedSiteIds: [],
            popularityRank: 23,
            effectsTimeline: "Day 1-3: subtle — some users report 'clearer thinking' within 24-48h oral dose. Week 1-2: memory consolidation and verbal fluency improvements reported; animal data shows synaptogenesis at remarkably low concentrations. Week 4-6: cumulative cognitive effect, particularly spatial memory and learning speed in animal models. Human data nonexistent — all subjective user reports. Community cycles 4 weeks on, 4+ weeks off due to limited long-term safety data.",
            mechanism: "Synthetic hexapeptide analogue of angiotensin IV, developed at Washington State University (Harding/Wright lab). Primary mechanism: potentiates hepatocyte growth factor (HGF) binding to c-Met receptor by facilitating HGF dimerization required for receptor activation. HGF/c-Met signaling drives synaptogenesis, spinogenesis, and neuronal survival. Reportedly ~7 orders of magnitude more potent than BDNF in specific in-vitro synaptogenesis assays (a striking claim — limited to narrow lab conditions). Secondary: IRAP (insulin-regulated aminopeptidase) inhibition modulates neuropeptide availability at synapses. ~38% oral bioavailability, unusual for a peptide.",
            risks: "HGF/c-Met pathway is a well-characterized ONCOGENIC axis — c-Met is a therapy target in many cancers. Long-term / repeated HGF potentiation in someone with undiagnosed malignancy is a real biological concern, not just theoretical · Key 2014 mechanistic paper was retracted for data fabrication — foundational evidence base is weaker than marketing suggests · Headache, brain fog initially as synapses remodel · Limited long-term human safety data · Chronic use effects on motor control, mood, and executive function not characterized · Irreversible synaptic rewiring theoretically possible · No regulatory approval anywhere",
            mitigations: "Conservative 4-weeks-on / 4+-weeks-off cycling given HGF/c-Met cancer link. Full cancer screen baseline and annually: dermatology, PSA/mammogram, colonoscopy as age-appropriate. Absolute contraindication: personal or strong family history of any solid tumor or hematologic malignancy, active or within 5y remission. Start 5 mg oral; rare single dose ceiling 15 mg. Oral route eliminates injection variables. Stop immediately for any new lump, unexplained bleeding, persistent cough, unexplained weight loss, or neurological change. Source only from vendors with published purity data given history of fraudulent supply."
        ),

        Compound(
            name: "PEG-MGF",
            slug: "peg-mgf",
            halfLifeHrs: 48,
            dosingRangeLowMcg: 200,
            dosingRangeHighMcg: 400,
            benefits: ["Localized muscle growth", "Satellite cell activation", "Post-workout repair"],
            sideEffects: ["Injection site soreness", "Hypoglycemia (rare)"],
            stackingNotes: "Inject directly into trained muscles post-workout for targeted hypertrophy.",
            fdaStatus: .research,
            summaryMd: "PEG-MGF (pegylated mechano growth factor) is a splice variant of IGF-1 with an added PEG chain for extended half-life. Researched for localized muscle repair and satellite cell activation.",
            goalCategories: ["growth", "recovery"],
            administrationRoutes: ["im"],
            timeToEffectHours: 6,
            peakEffectHours: 24,
            durationHours: 72,
            dosingFormula: "300",
            dosingUnit: "mcg",
            dosingFrequency: "3x_weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["glute-im-left", "glute-im-right"],
            popularityRank: 26,
            effectsTimeline: "Post-workout injection into trained muscle: mild soreness 24-48h. Week 1-2: local recovery noticeably faster at injected muscle, pump lasts longer. Week 4-6: localized muscle growth visible at injected site vs non-injected control muscle — hyperplasia signal from satellite cell activation. Best for lagging body parts. 4-6 week cycles then 4-8 week break. 48h half-life enables 2-3x weekly dosing rather than daily.",
            mechanism: "Pegylated mechano-growth factor (MGF) — an IGF-1 splice variant (IGF-1Ec in humans) transiently expressed in skeletal muscle after mechanical loading / eccentric damage. Native MGF has very short half-life (~few min); polyethylene glycol conjugation extends it to ~48h. Binds IGF-1 receptor but with distinct kinetics — activates satellite cell proliferation (resident muscle stem cells) more than systemic IGF-1R downstream protein synthesis. Local IM injection into a trained muscle produces targeted hyperplasia whereas subq acts more like low-dose IGF-1 systemically.",
            risks: "Injection-site soreness often pronounced · Hypoglycemia less severe than IGF-1 LR3 but still possible · Cardiac hypertrophy theoretical risk with systemic / chronic use · Joint pain if muscle growth outpaces tendon adaptation · Theoretical cancer concern via IGF-1 pathway on undiagnosed malignancy · Immunogenicity possible — PEG conjugation itself can induce anti-PEG antibodies with chronic use · WADA-banned · No FDA approval; all data is preclinical or anecdotal · Grey-market purity variable",
            mitigations: "Local IM into trained muscle post-workout — limits systemic exposure, maximizes satellite-cell targeting. Cap at 200-400 mcg per injection, 2-3x weekly max. Reduce training volume 15-20% during cycle. Baseline + 6-week fasting glucose, A1c, IGF-1, lipids. Full cancer screen before first cycle. Avoid stacking with IGF-1 LR3 or insulin. Rotate target muscles. Stop for unexplained joint pain > 1 week or new cardiac symptoms."
        ),

        Compound(
            name: "Mazdutide",
            slug: "mazdutide",
            halfLifeHrs: 120,
            dosingRangeLowMcg: 3_000,
            dosingRangeHighMcg: 9_000,
            benefits: ["Significant weight loss", "Glucose control", "Cardiovascular benefit", "Lipid improvement"],
            sideEffects: ["Nausea", "Diarrhea", "Constipation", "Fatigue"],
            stackingNotes: "Dual GLP-1 / glucagon receptor agonist. Promising phase 3 data in Chinese trials.",
            fdaStatus: .research,
            summaryMd: "Mazdutide is a dual GLP-1 / glucagon receptor agonist (IBI362) developed by Innovent. Combines GLP-1 appetite suppression with glucagon's metabolic rate boost.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 24,
            durationHours: 168,
            dosingFormula: "clamp(3000 + weeksOnCycle * 1000, 3000, 9000)",
            dosingUnit: "mcg",
            dosingFrequency: "weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 28,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 29,
            effectsTimeline: "Week 1-2: nausea, constipation, appetite down — classic incretin-class start. Week 4-8: progressive weight loss 4-7%. Week 24 (Phase 2 Chinese trial): 6.7% at 3mg, 10.4% at 4.5mg, 11.3% at 6mg vs +1% placebo. Glucagon activation adds energy-expenditure boost on top of GLP-1 appetite suppression, so subjective energy typically better than pure GLP-1s at matched weight loss. Weekly titration: 0.5 → 1.5 → 3 → 4.5 → 6 mg over 12-16 weeks.",
            mechanism: "Dual GLP-1 / glucagon receptor agonist (IBI362) developed by Innovent Biologics (China). GLP-1 receptor activation: hypothalamic appetite suppression, pancreatic insulin secretion, gastric emptying delay. Glucagon receptor activation: unique component driving hepatic lipolysis (fat burning in liver), increased resting energy expenditure, and MASH (liver fat disease) reversal. Ratio is GLP-1-dominant with modest glucagon activity — avoids the compensatory hyperglycemia that pure glucagon agonism causes. 5-day half-life, weekly dosing.",
            risks: "GI adverse events as GLP-1 class — nausea, vomiting, diarrhea, constipation (dose-dependent) · Higher incidence of upper respiratory tract infections in phase 2 than expected (mechanism unclear) · Potential hyperglycemia from glucagon component in insulin-sensitive users (offset by GLP-1's insulinotropic action but not fully in all individuals) · Injection-site reactions · Gallbladder disease (GLP-1 class effect) · Pancreatitis signal (class effect) · Thyroid C-cell tumor signal in rodents (class effect) · Not FDA-approved — phase 3 ongoing · MTC / MEN 2 contraindication · Pregnancy contraindicated",
            mitigations: "Titrate weekly — never skip dose levels. Protein target 1.6-2.2 g/kg and resistance training to preserve lean mass (same as other GLP-class). Baseline + quarterly A1c, lipase, TSH, calcitonin if MTC risk factors. Avoid in personal / family MTC history, active pancreatitis, gallbladder disease, pregnancy. Hold 1 week before elective surgery / endoscopy. Source carefully given investigational status — COA mandatory. Monitor glucose if diabetic on insulin / sulfonylurea (additive hypoglycemia risk despite glucagon component). Stop for persistent vomiting > 48h or severe upper-quadrant pain."
        ),

        Compound(
            name: "Survodutide",
            slug: "survodutide",
            halfLifeHrs: 168,
            dosingRangeLowMcg: 1_200,
            dosingRangeHighMcg: 6_000,
            benefits: ["Weight loss", "Glucose control", "MASH/liver fat reduction"],
            sideEffects: ["Nausea", "Vomiting", "Diarrhea", "Injection site reaction"],
            stackingNotes: "Dual GLP-1 / glucagon receptor agonist from Boehringer/Zealand. Titrate from 0.3mg weekly.",
            fdaStatus: .research,
            summaryMd: "Survodutide is a dual GLP-1 / glucagon receptor agonist in late-stage trials. Strong phase 2 data for weight loss and MASH (liver fat disease).",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 24,
            durationHours: 168,
            dosingFormula: "clamp(1200 + weeksOnCycle * 600, 1200, 6000)",
            dosingUnit: "mcg",
            dosingFrequency: "weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 28,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 30,
            effectsTimeline: "Week 1-2: strong nausea, dose-dependent; higher GI discontinuation than tirzepatide or semaglutide. Week 4-8: 5-9% weight loss, glycemic control improving. Week 24: liver fat reduction measurable in MASLD trials (one of the best-in-class effects). Week 46: ~19% mean weight loss in Phase 2 obesity trials at top dose. Titration 0.3 → 0.6 → 1.2 → 2.4 → 3.6 → 4.8 mg weekly. ~7 day half-life.",
            mechanism: "Dual GLP-1 / glucagon receptor agonist from Boehringer Ingelheim / Zealand Pharma. Stronger glucagon-receptor agonism than mazdutide, which drives the superior liver-fat reduction (glucagon directly stimulates hepatic lipolysis and fatty-acid oxidation). GLP-1 component provides the appetite suppression and glycemic control. Glucagon component uniquely: increases resting energy expenditure, accelerates hepatic fat clearance (why Phase 2 MASH trial showed ~63% of patients achieving MASH resolution), and raises heart rate modestly.",
            risks: "Higher GI adverse event discontinuation than tirzepatide or semaglutide — nausea, vomiting, diarrhea more pronounced · Injection-site reactions · Resting heart rate elevation (glucagon-mediated) · Potential blood glucose instability — glucagon agonism can offset GLP-1 glucose-lowering · Pancreatitis / gallbladder (GLP-1 class) · Thyroid C-cell signal (class effect) · MASH/MASLD population: effects on cirrhosis progression unknown · Lean-mass loss concerns as with all GLP-class · Phase 3 ongoing · Grey market supply quality varies",
            mitigations: "Slowest titration of this class — 0.3 mg start, escalate only if tolerated 2-4 weeks at each step. Never push past tolerability. Protein target ≥1.6 g/kg + resistance training for body-comp quality. Baseline + 3-month and 6-month: A1c, lipase, calcitonin if MTC risk, liver enzymes, lipid panel, resting HR. Avoid in personal / family MTC, MEN 2, active pancreatitis, decompensated cirrhosis, pregnancy, uncontrolled cardiac arrhythmia. Hold 1 week before elective procedures. Stop for persistent HR elevation > 10 bpm sustained, worsening GI > 72h, or unexplained lipase elevation > 3x ULN."
        ),

        Compound(
            name: "Pentadeca Arginate",
            slug: "pentadeca-arginate",
            halfLifeHrs: 4,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 750,
            benefits: ["Oral-bioavailable tissue repair", "Gut healing", "Joint recovery", "Anti-inflammatory"],
            sideEffects: ["Generally well tolerated", "Mild GI upset"],
            stackingNotes: "BPC-157 arginine salt variant — enhanced oral absorption. Alternative for needle-averse users.",
            fdaStatus: .research,
            summaryMd: "Pentadeca Arginate (PDA) is an arginine salt of BPC-157 with improved oral bioavailability. Retains BPC's healing, tendon-repair, and gut-protective properties while avoiding injection.",
            goalCategories: ["recovery", "immune"],
            administrationRoutes: ["oral", "subq"],
            timeToEffectHours: 1,
            peakEffectHours: 3,
            durationHours: 8,
            dosingFormula: "500",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 35,
            effectsTimeline: "Day 1-3 oral: gut-lining repair starts quickly — reflux, loose stools, IBD symptoms calmer within 48h. Week 2: joint / soft-tissue recovery improving similar to injectable BPC-157. Week 4-6: cumulative healing effect plateaus. Convenient oral alternative for needle-averse users — dose 500-750 mcg 1-2x daily orally. 6-week cycles standard.",
            mechanism: "BPC-157 arginine salt — same 15-amino-acid sequence but formulated with arginine counter-ion for improved oral absorption through the gut wall (raises oral bioavailability from ~10-20% of parent BPC-157 to ~50-60% in some preparations). Retains all three BPC-157 mechanisms: VEGFR2-Akt-eNOS angiogenesis, FAK-paxillin fibroblast migration, and GHR upregulation on tendon/ligament cells. Same efficacy profile as subq BPC with the convenience of oral dosing.",
            risks: "Same angiogenesis → theoretical tumor-acceleration concern as BPC-157 · Mild GI upset at higher oral doses · Unproven whether arginine conjugation changes immunogenicity vs parent BPC-157 · No FDA approval (FDA placed BPC-157 on Section 503A Category 2 in 2023) · Grey-market vendor quality variable — some 'PDA' products are just relabeled BPC-157 without arginine salt · Pregnancy contraindicated · No human RCTs",
            mitigations: "Full cancer screening baseline as with BPC-157. Cycle 6-8 weeks on, 2-4 weeks off. Oral route preserves gut-localized benefit while reducing systemic angiogenic exposure. 250-750 mcg 1-2x daily. Source only from vendors with published COA verifying actual arginine salt formulation. Avoid in active malignancy or within 5y cancer remission. Stop for unexplained lumps, bleeding, or new skin lesions."
        ),

        Compound(
            name: "Cerebrolysin",
            slug: "cerebrolysin",
            halfLifeHrs: 24,
            dosingRangeLowMcg: 5_000,
            dosingRangeHighMcg: 30_000,
            benefits: ["Neurogenesis", "Stroke / TBI recovery", "Cognitive function", "Neuroprotection"],
            sideEffects: ["Injection site reaction", "Headache", "Insomnia (if dosed late)"],
            stackingNotes: "IM administration preferred. Russian/EU-approved for stroke and dementia. Morning dosing avoids insomnia.",
            fdaStatus: .research,
            summaryMd: "Cerebrolysin is a porcine brain-derived neuropeptide preparation researched for stroke recovery, Alzheimer's, and TBI. Approved in Russia and parts of EU/Asia for neurological conditions.",
            goalCategories: ["cognitive"],
            administrationRoutes: ["im", "iv"],
            timeToEffectHours: 24,
            peakEffectHours: 48,
            durationHours: 72,
            dosingFormula: "10000",
            dosingUnit: "mcg",
            dosingFrequency: "5x_weekly",
            bacWaterMlDefault: 0,
            storageTemp: "refrigerated",
            storageMaxDays: 14,
            recommendedSiteIds: ["glute-im-left", "glute-im-right"],
            popularityRank: 36,
            effectsTimeline: "Week 1-2: mild injection-site soreness, slight headache. Week 2-4 (daily or 5x weekly IM course): cognitive clarity, verbal fluency, motivation improving — most dramatic in post-stroke, TBI, or dementia users. Week 4-8: neurogenic effects consolidate. Standard Russian/EU protocol: 5-30 ml (concentration varies) daily IM for 10-20 days, 2-4x yearly. Not chronic daily use.",
            mechanism: "Porcine brain-derived neuropeptide complex produced by controlled enzymatic hydrolysis — contains a mixture of low-molecular-weight active peptides (~15%) and free amino acids (~85%). Active fractions mimic endogenous neurotrophic factors (BDNF, NGF, CNTF, GDNF) and enhance neurogenesis, dendritic arborization, and neuronal survival after ischemia or injury. Approved in Russia, China, Austria, Mexico and other countries for stroke, Alzheimer's, vascular dementia, and TBI. On Russia's List of Vital and Essential Drugs.",
            risks: "Injection-site reactions common · Headache, dizziness · Vertigo · Agitation or insomnia if dosed too late in day · Rare hypersensitivity / urticaria / anaphylaxis · Seizure threshold lowering in susceptible patients (theoretical) · Porcine origin — religious / dietary concerns, allergy risk · IM route only; IV infusion is slow and clinic-only · Not FDA-approved · Chronic-use safety beyond repeated courses not well characterized · Pregnancy category data limited",
            mitigations: "Morning dosing to avoid insomnia. IM administration preferred over IV for non-clinical use. Start at 2-5 ml to assess hypersensitivity; always have epi accessible first dose. Avoid in active seizure disorder, severe renal failure, pregnancy, known porcine allergy. Baseline neurological exam for tracking. Standard 10-20 day course, then 2-4 month break. Stop for rash, facial swelling, sudden BP changes, or new-onset seizures. Source from European pharmacy channels when possible."
        ),

        Compound(
            name: "SS-31",
            slug: "ss-31",
            halfLifeHrs: 2,
            dosingRangeLowMcg: 1_000,
            dosingRangeHighMcg: 5_000,
            benefits: ["Mitochondrial protection", "Cardiolipin stabilization", "Anti-aging", "Reduced oxidative stress"],
            sideEffects: ["Generally well tolerated", "Injection site reaction"],
            stackingNotes: "Stacks well with MOTS-c and NAD+ for mitochondrial longevity protocol.",
            fdaStatus: .research,
            summaryMd: "SS-31 (Elamipretide / MTP-131) is a cell-permeable tetrapeptide that binds cardiolipin on the inner mitochondrial membrane. Researched for mitochondrial dysfunction, heart failure, and aging.",
            goalCategories: ["longevity"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 4,
            peakEffectHours: 12,
            durationHours: 24,
            dosingFormula: "2500",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 37,
            effectsTimeline: "Week 1-2: subtle — some users report reduced exercise-induced soreness. Week 4-6: endurance and recovery measurably improving; mitochondrial function markers (lactate threshold) shift favorably. Week 8-12: consolidated energy benefits. Most pronounced effects in mitochondrial dysfunction populations (heart failure, mitochondrial myopathy, aging) vs healthy users. Daily subq dosing; 6-8 week cycles.",
            mechanism: "Cell-permeable aromatic cationic tetrapeptide (D-Arg-2',6'-Dmt-Lys-Phe-NH2, aka Elamipretide, MTP-131). Selectively binds cardiolipin on the inner mitochondrial membrane — cardiolipin is unique to mitochondria and essential for electron transport chain assembly. Stabilizes ETC supercomplexes, reduces proton leak, decreases mitochondrial ROS production at source, improves ATP synthesis efficiency. Doesn't just scavenge free radicals externally — prevents their generation. In Phase 3 trials for Barth syndrome; discontinued by Stealth for heart failure after mixed Phase 3 results.",
            risks: "Injection-site reactions — common, sometimes pronounced · Mild headache · Generally well-tolerated in Phase 1-3 trials · Phase 3 heart failure efficacy endpoint not met (Stealth's RESTORE trial 2019) — efficacy is real but modest in heart failure population · Limited data in otherwise healthy users · Theoretical: mitochondrial function is context-dependent — effect in cancer cells (which often rewire mitochondrial metabolism) is uncharacterized · No FDA approval · Expensive on grey market · Immunogenicity possible with chronic use",
            mitigations: "Start 1-2 mg subq daily to assess injection-site tolerance. Rotate sites religiously — abdomen L/R, thigh L/R. 6-8 week cycles on, 2-4 weeks off. Baseline labs: CBC, CMP, lipid panel, lactate if mitochondrial disease. Avoid in active cancer, pregnancy, severe renal dysfunction. Best stacked for mitochondrial longevity stack with MOTS-c and NAD+ — distinct mechanisms but complementary. Source from vendors with published COAs given cost and counterfeit incentive. Stop for persistent injection-site lumps, fatigue worsening, or unexplained chest pain."
        ),

        Compound(
            name: "FOXO4-DRI",
            slug: "foxo4-dri",
            halfLifeHrs: 6,
            dosingRangeLowMcg: 5_000,
            dosingRangeHighMcg: 15_000,
            benefits: ["Senolytic (clears senescent cells)", "Anti-aging", "Skin / hair restoration (anecdotal)"],
            sideEffects: ["Injection site reaction", "Fatigue during cycle", "Limited human data"],
            stackingNotes: "Pulse dosing (3-5 days on, then weeks off) — mimics senolytic protocols in animal studies.",
            fdaStatus: .research,
            summaryMd: "FOXO4-DRI (Proxofim) is a synthetic peptide that disrupts the FOXO4-p53 interaction, selectively inducing apoptosis in senescent 'zombie' cells. Core senolytic research compound.",
            goalCategories: ["longevity"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 6,
            peakEffectHours: 24,
            durationHours: 72,
            dosingFormula: "10000",
            dosingUnit: "mcg",
            dosingFrequency: "as_needed",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 38,
            effectsTimeline: "Day 1-5 (pulse protocol): fatigue and malaise typical — cells die when senescent cells are cleared, creates short-term immune cleanup load ('senolytic Herx'). Week 2: energy and recovery often better than pre-cycle in users with high senescent-cell burden (older, chronic stress, post-illness). Week 4+: subjective anti-aging effects (skin, sleep) in responders. Pulse dosing: 5 days on, then weeks/months off — mimics animal protocols. Never chronic.",
            mechanism: "Synthetic proxy-D-retro-inverso peptide (Proxofim) that disrupts the FOXO4-p53 protein-protein interaction. In senescent cells, FOXO4 sequesters p53 in the nucleus preventing p53-induced apoptosis — senescent 'zombie' cells use this mechanism to avoid death while secreting the senescence-associated secretory phenotype (SASP) that drives inflammaging. FOXO4-DRI competitively binds FOXO4, freeing p53 → senescent cells undergo targeted apoptosis while healthy cells remain unaffected. One of the first true SENOLYTIC peptides.",
            risks: "Fatigue / malaise during dosing (apoptotic cell clearance load) · Injection-site reactions · Theoretical immune load from dead cell clearance — inflammatory markers transient rise · Long-term safety entirely uncharacterized in humans · Possible loss of beneficial senescent cells (some wound healing / placental function uses senescence) · Cardiac / hepatic stress if pulse too long · Not FDA-approved · Expensive and counterfeiting common · Pregnancy contraindicated · Active cancer theoretical concern — p53 restoration is tumor-suppressive in most but not all contexts",
            mitigations: "Strict pulse dosing only: 5-7 days on, then MINIMUM 2 months off. Never run chronic. 10 mg 3x weekly during pulse or 5 mg daily for 5 days. Baseline hs-CRP, ferritin, liver enzymes to gauge SASP burden and track response. Hydrate aggressively during pulse to support cell clearance load. Avoid in active cancer, pregnancy, recent MI, uncontrolled autoimmune disease. Start at half-dose first cycle to test tolerance. Source with COA given high counterfeit rate. Stop for persistent fatigue > 2 weeks post-pulse, new rashes, or worsening of any chronic inflammatory condition."
        ),

        Compound(
            name: "Pinealon",
            slug: "pinealon",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["Neuroprotection", "Sleep quality", "Age-related cognitive support"],
            sideEffects: ["Generally mild", "Vivid dreams"],
            stackingNotes: "Russian bioregulator. Cycle 10-20 days on, then months off.",
            fdaStatus: .research,
            summaryMd: "Pinealon is a tripeptide Russian bioregulator (Glu-Asp-Arg) researched for brain tissue regulation and neuroprotection. Paired with Epithalon in anti-aging protocols.",
            goalCategories: ["cognitive", "sleep", "longevity"],
            administrationRoutes: ["subq", "nasal"],
            timeToEffectHours: 0.5,
            peakEffectHours: 2,
            durationHours: 12,
            dosingFormula: "200",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 39,
            effectsTimeline: "Week 1: sleep quality noticeably improves — vivid dreams common. Week 2: cognitive clarity and memory consolidation subjectively sharper. Week 2-4: brain 'calm focus' stable. Russian bioregulator protocol: 10-20 day course, then 2-6 month break. Not a daily chronic compound. Effects overlap with Epithalon for sleep but Pinealon is more cognitive-focused.",
            mechanism: "Synthetic tripeptide Glu-Asp-Arg — a Russian-designed 'bioregulator' peptide in the Khavinson family. Acts on pineal gland tissue and extends to CNS: modulates melatonin synthesis (indirectly via pineal activation), influences gene expression in neurons (bioregulator thesis: small peptides bind DNA and epigenetically regulate tissue-specific gene programs), anti-oxidant in cortex. Unlike Epithalon's telomerase focus, Pinealon is positioned more for neurocognitive support and sleep architecture.",
            risks: "Very limited Western safety data — Russian clinical literature primary source · Vivid or occasionally disturbing dreams · Mild headache · Injection-site or nasal-irritation reactions · Bioregulator mechanism thesis (direct DNA binding by tripeptides) is controversial and not fully validated by Western research · Source quality variable — easy-to-synthesize peptide attracts counterfeits · Theoretical HPA-axis modulation · Unknown in pregnancy / lactation · No FDA approval",
            mitigations: "10-20 day course subq or intranasal, then minimum 2-month break. 100-300 mcg/day typical. Evening dosing pairs with melatonin rhythm. Often stacked with Epithalon for full pineal-longevity protocol — Russian convention. Source with COA. Avoid in pregnancy, lactation, uncontrolled psychiatric conditions. Baseline sleep diary for 2 weeks before starting so effect is visible. Stop for persistent nightmares, morning grogginess > 1 week, or mood destabilization."
        ),

        Compound(
            name: "P-21",
            slug: "p-21",
            halfLifeHrs: 4,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 500,
            benefits: ["Neurogenesis", "BDNF upregulation", "Memory", "Mood"],
            sideEffects: ["Generally well tolerated", "Mild headache"],
            stackingNotes: "Ciliary neurotrophic factor (CNTF) mimetic. Stacks with Semax/Selank for cognitive protocol.",
            fdaStatus: .research,
            summaryMd: "P-21 (P021) is a CNTF-based peptidomimetic researched for hippocampal neurogenesis, BDNF signaling, and cognitive decline. Promising preclinical data for Alzheimer's.",
            goalCategories: ["cognitive"],
            administrationRoutes: ["subq", "nasal"],
            timeToEffectHours: 1,
            peakEffectHours: 4,
            durationHours: 12,
            dosingFormula: "400",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 40,
            effectsTimeline: "Week 1-2: subtle — mood lift and mental clarity emerging. Week 4: memory consolidation and learning speed improving; BDNF signaling is cumulative. Week 6-8: hippocampal neurogenesis animal model endpoints peak around this window. Russian research pedigree; Western data is preclinical only. Cycle 4-8 weeks on, 4 weeks off. Daily subq or intranasal.",
            mechanism: "Synthetic 11-amino-acid peptidomimetic derived from ciliary neurotrophic factor (CNTF) sequence. Mimics CNTF's neurotrophic activity through JAK/STAT3 pathway activation in neurons, driving BDNF upregulation, hippocampal neurogenesis, and synaptic plasticity. CNTF itself caused side effects (weight loss, cachexia) in MS trials — P-21 is the stripped-down fragment that retains neurogenic effect without CNTF's systemic activity. Preclinical Alzheimer's data is promising; no completed human trials.",
            risks: "Very limited human data — all preclinical · Mild headache · Injection-site reactions · Unknown long-term safety · Theoretical: JAK/STAT3 activation has oncogenic potential in some contexts (chronic myeloproliferative) · Mood destabilization possible from BDNF surge in mood-disorder patients · Pregnancy contraindicated · Source purity variable · No regulatory approval anywhere",
            mitigations: "Start 250 mcg/day to assess response. Daily subq (abdomen) or intranasal 2-3x. Cycle 4-8 weeks on, 4 weeks off. Stack works well with Semax (parallel BDNF mechanism) or Cerebrolysin (complementary neurotrophic). Avoid in active cancer (particularly hematologic), pregnancy, uncontrolled mood disorder, or recent stroke (timing of neurogenesis matters). Source with COA. Stop for new-onset mood swings, unexplained bleeding, or persistent headaches > 1 week."
        ),

        Compound(
            name: "Tesofensine",
            slug: "tesofensine",
            halfLifeHrs: 220,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 1_000,
            benefits: ["Appetite suppression", "Weight loss", "Energy / focus"],
            sideEffects: ["Insomnia", "Dry mouth", "Elevated BP / HR", "Constipation"],
            stackingNotes: "Oral. Not a peptide — triple monoamine reuptake inhibitor. Morning dosing to avoid insomnia.",
            fdaStatus: .research,
            summaryMd: "Tesofensine is an oral triple monoamine (serotonin/noradrenaline/dopamine) reuptake inhibitor originally studied for Parkinson's, now researched for obesity with strong weight-loss effects.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["oral"],
            timeToEffectHours: 2,
            peakEffectHours: 8,
            durationHours: 48,
            dosingFormula: "500",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 0,
            storageTemp: "room",
            storageMaxDays: 365,
            recommendedSiteIds: [],
            popularityRank: 43,
            effectsTimeline: "Week 1: strong appetite suppression, noticeable energy/focus lift (monoamine mechanism). Week 2-4: 4-6% weight loss typical. Week 12-24: 9-11% weight loss in Phase 2 obesity trials (stronger than older approved drugs but below GLP-1 class). Insomnia and dry mouth common throughout. Half-life ~7-9 days — single daily morning oral dose.",
            mechanism: "Triple monoamine reuptake inhibitor — blocks serotonin, noradrenaline, AND dopamine reuptake. Originally developed by NeuroSearch for Parkinson's and Alzheimer's; repositioned for obesity after Phase 2 trials showed striking appetite suppression via dopaminergic reward pathway modulation + noradrenergic thermogenic effect. NOT a peptide — small-molecule oral. Centrally acting. Very long half-life (~7-9 days) means chronic daily dosing creates steady state.",
            risks: "Insomnia (dopaminergic/noradrenergic) — dose too late ruins sleep · Dry mouth, constipation · Elevated heart rate and blood pressure (noradrenergic) · Anxiety, agitation, mood instability · Abuse potential (DAT inhibition) · Withdrawal / rebound depression on discontinuation · Cardiovascular concern at higher doses (failed Phase 3 over BP/HR signal) · Not FDA-approved; approved in some other countries; grey-market widely · Contraindicated with MAOIs, SSRIs, stimulants · Pregnancy contraindicated",
            mitigations: "Morning dosing only — before 10 AM — to avoid insomnia. Start 250 mcg, max 500 mcg daily. Monitor BP and resting HR weekly first month; if either sustained > +10 from baseline, discontinue. Avoid combining with other stimulants, SSRIs (serotonin syndrome risk), MAOIs. Not for anyone with psychiatric history, CVD, uncontrolled hypertension, or arrhythmia. Taper slowly to mitigate rebound depression. Baseline BP, HR, ECG if any CV risk factors."
        ),

        Compound(
            name: "Liraglutide",
            slug: "liraglutide",
            halfLifeHrs: 13,
            dosingRangeLowMcg: 600,
            dosingRangeHighMcg: 3_000,
            benefits: ["Weight loss", "Blood sugar control", "Appetite suppression"],
            sideEffects: ["Nausea", "Vomiting", "Diarrhea", "Injection site reaction"],
            stackingNotes: "Original GLP-1 agonist. Daily dosing vs. weekly for semaglutide/tirzepatide.",
            fdaStatus: .approved,
            summaryMd: "Liraglutide is an FDA-approved GLP-1 receptor agonist (Saxenda/Victoza). Shorter half-life than semaglutide (daily dosing), but established long-term safety data.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 4,
            peakEffectHours: 12,
            durationHours: 24,
            dosingFormula: "clamp(600 + weeksOnCycle * 300, 600, 3000)",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 28,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left"],
            popularityRank: 44,
            effectsTimeline: "Week 1: nausea, injection-site reactions common. Week 4 (1.8 mg dose): 2-3% weight loss, A1c dropping. Week 12 (3.0 mg Saxenda dose): 5-8% weight loss. Week 56: 6-10% mean weight loss (Saxenda trials). Daily dosing is the main adherence barrier vs weekly semaglutide/tirzepatide. Titration: 0.6 → 1.2 → 1.8 → 2.4 → 3.0 mg daily over 5 weeks.",
            mechanism: "FDA-approved GLP-1 receptor agonist (Saxenda for obesity, Victoza for T2D). 97% homology to native GLP-1 with a fatty-acid side chain for albumin binding extending half-life to ~13 hours (daily dosing). Same mechanism as semaglutide but shorter-acting: GLP-1R activation on pancreatic beta cells (glucose-dependent insulin), hypothalamus (appetite suppression), and GI smooth muscle (gastric emptying delay). The original GLP-1 class drug with the longest safety track record.",
            risks: "GI side effects — nausea, vomiting, diarrhea, constipation · Pancreatitis signal (GLP-1 class) · Gallbladder disease · Thyroid C-cell tumors in rodents → MTC/MEN 2 contraindication · Injection-site reactions (more common with daily dosing than weekly semaglutide) · Acute gallstone / cholecystitis · Tachycardia (mild) · Hypoglycemia if stacked with insulin/sulfonylurea · Lean mass loss (less than semaglutide/tirzepatide at matched weight loss due to lower total weight loss) · Pregnancy contraindicated",
            mitigations: "Slow titration — increase only when current dose well-tolerated 1+ week. Start 0.6 mg and escalate weekly if no significant nausea. Rotate injection sites (abdomen, thigh, upper arm). Protein ≥1.6 g/kg + resistance training to preserve lean mass. Baseline + quarterly A1c, lipase, calcitonin if MTC risk factors. Hold 1 week pre-elective-surgery. Avoid in personal/family MTC, MEN 2, active pancreatitis, severe gallbladder disease, pregnancy. Stop for persistent vomiting > 48h, severe abdominal pain (rule out pancreatitis), or unrelenting reflux."
        ),

        Compound(
            name: "SLU-PP-332",
            slug: "slu-pp-332",
            halfLifeHrs: 4,
            dosingRangeLowMcg: 500,
            dosingRangeHighMcg: 2_000,
            benefits: ["Exercise mimetic", "Fat oxidation", "Endurance", "Metabolic enhancement"],
            sideEffects: ["Generally mild", "Potential tachycardia at high doses"],
            stackingNotes: "Oral bioavailable. ERR (estrogen-related receptor) agonist activating exercise-like pathways.",
            fdaStatus: .research,
            summaryMd: "SLU-PP-332 is a pan-ERR agonist researched as an exercise mimetic — activates the same metabolic pathways as endurance training, promoting mitochondrial biogenesis and fat oxidation.",
            goalCategories: ["fat_loss", "longevity"],
            administrationRoutes: ["oral"],
            timeToEffectHours: 1,
            peakEffectHours: 4,
            durationHours: 12,
            dosingFormula: "1000",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 0,
            storageTemp: "room",
            storageMaxDays: 365,
            recommendedSiteIds: [],
            popularityRank: 45,
            effectsTimeline: "Week 1-2: subtle — endurance during training noticeably up, less perceived effort. Week 4-6: body composition shifts toward fat oxidation; similar mitochondrial biogenesis markers to exercise training. Week 8-12: measurable improvements in endurance and fat mass. Preclinical only — no human trials. Oral; 1000 mcg daily. Cycle 8-12 weeks on, 4 weeks off.",
            mechanism: "Oral pan-ERR (estrogen-related receptor) agonist — activates ERR-alpha, -beta, and -gamma, orphan nuclear receptors that drive mitochondrial biogenesis and oxidative metabolism genes. These are the same receptors upregulated by exercise. Net effect mimics endurance training adaptation: more mitochondria per muscle cell, higher oxidative capacity, improved fat-burning at rest. 'Exercise mimetic' in the most literal sense — activates the downstream transcriptional program that training causes. Not a peptide — small molecule.",
            risks: "No human data — entirely preclinical · Theoretical cancer concern: ERR signaling is context-dependent oncogenically, upregulated in some aggressive tumors (breast, prostate) · Cardiac effects unknown — exercise-like cardiac remodeling without the protective effects of actual exercise is untested · Could interact with estrogen-related signaling · Unknown hepatic metabolism / toxicology · No regulatory approval anywhere · Grey-market purity variable · Pregnancy contraindicated",
            mitigations: "Experimental — treat as such. Start 250 mcg oral daily; cap at 1 mg. Cycle 8-12 weeks, then 4-6 weeks off. Baseline + quarterly CBC, CMP, liver enzymes. Resistance and aerobic training still required — SLU-PP doesn't replace exercise, it amplifies it (and preliminary data suggests need for exercise stimulus for full effect). Avoid in active cancer, family history of hormone-sensitive cancers (ERR cross-talk with estrogen), pregnancy, cardiac arrhythmia. Source with COA. Stop for any new symptom given absence of human safety data."
        ),

        Compound(
            name: "Melanotan I",
            slug: "melanotan-i",
            halfLifeHrs: 1,
            dosingRangeLowMcg: 500,
            dosingRangeHighMcg: 1_000,
            benefits: ["Skin tanning", "UV protection (research)", "More selective than MT2"],
            sideEffects: ["Nausea (milder than MT2)", "Flushing", "Mole darkening"],
            stackingNotes: "Selective MC1R agonist — cleaner tanning profile than MT2 without libido/appetite side effects.",
            fdaStatus: .research,
            summaryMd: "Melanotan I (Afamelanotide) is a selective MC1R agonist researched for skin protection and pigmentation disorders. Approved in EU as Scenesse for erythropoietic protoporphyria.",
            goalCategories: ["skin_hair"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 1,
            peakEffectHours: 2,
            durationHours: 8,
            dosingFormula: "750",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 46,
            effectsTimeline: "Injection 1-3: mild nausea, flushing, yawning — gentler than MT2. Week 1-2: faint skin darkening begins — slower than MT2 but cleaner onset. Week 4: visible tan without aggressive mole stimulation. Week 8+: maintenance phase at reduced frequency. Cleaner alternative to MT2 for tanning-only goal. Approved as Scenesse (afamelanotide) in EU/US for erythropoietic protoporphyria.",
            mechanism: "Linear 13-amino-acid analogue of alpha-MSH — selective MC1R agonist with minimal activity at MC3R, MC4R, MC5R. This selectivity is the key difference from MT2: pigmentation effect without the libido (MC4R), nausea (MC4R/area postrema), or CV effects. MC1R activation on melanocytes → cAMP → PKA → CREB → MITF → tyrosinase upregulation → eumelanin synthesis. FDA-approved under brand Scenesse for EPP (a rare UV-sensitivity disorder).",
            risks: "Mole darkening still occurs (MC1R activation is pan-melanocyte) — though less dramatic than MT2 · Theoretical melanoma concern as with any chronic melanocyte stimulation · Mild nausea first doses · Injection-site reactions · Facial flushing · Hyperpigmentation of existing freckles/gums · Headache · Rare anaphylaxis · Expensive as Scenesse; grey market less counterfeited than MT2 but still variable · Pregnancy contraindicated",
            mitigations: "Dermatologist baseline skin exam with mole mapping — non-negotiable. Photograph moles before starting. Start 500 mcg to assess tolerance. UV protection still required: MT1-induced tan does NOT replace sunscreen. Cycle rather than chronic use — 4-6 weeks loading, then maintenance at 1-2x weekly. Avoid in family history of melanoma, >50 dysplastic nevi, Fitzpatrick I skin. Annual dermatology follow-up. Stop for any ABCDE mole change, new rash, or persistent hyperpigmentation past baseline."
        ),

        Compound(
            name: "Oxytocin",
            slug: "oxytocin",
            halfLifeHrs: 0.1,
            dosingRangeLowMcg: 10,
            dosingRangeHighMcg: 40,
            benefits: ["Social bonding", "Mood elevation", "Trust / empathy", "Sexual function"],
            sideEffects: ["Generally well tolerated", "Mild nausea", "Emotional lability"],
            stackingNotes: "Very short half-life. Intranasal preferred over subq for acute social/mood effects.",
            fdaStatus: .approved,
            summaryMd: "Oxytocin is an FDA-approved neuropeptide (Pitocin) used for labor induction. Off-label research explores its role in social bonding, mood, and sexual function.",
            goalCategories: ["libido", "cognitive"],
            administrationRoutes: ["subq", "nasal"],
            timeToEffectHours: 0.1,
            peakEffectHours: 0.25,
            durationHours: 1,
            dosingFormula: "20",
            dosingUnit: "mcg",
            dosingFrequency: "as_needed",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 14,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 47,
            effectsTimeline: "Within 5-15 min (intranasal or subq): warmth, calm, social ease emerges. 30-60 min peak — subjective bonding / empathy / trust effects strongest here. 1-2h: wears off. Pulse-use, not daily chronic. Half-life ~3-5 min (subq) / ~10-15 min (intranasal). Use before social situations, intimate contexts, or therapy sessions. Tolerance builds rapidly with frequent dosing.",
            mechanism: "9-amino-acid peptide hormone — identical to endogenous oxytocin. Binds oxytocin receptor (OXTR), a Gq-coupled GPCR present in CNS (hypothalamus, amygdala, nucleus accumbens — social and reward circuits) and periphery (uterus, mammary tissue, cardiac muscle). Central effects: enhanced social recognition, pair bonding, empathy, reduced amygdala fear response, mesolimbic dopamine modulation. Peripheral effects: uterine contraction (why Pitocin is used for labor), milk letdown, modest BP modulation. Intranasal route gives preferential CNS delivery.",
            risks: "Emotional lability — can amplify both positive and negative emotional states · Mild nausea · Tachyphylaxis (tolerance) with frequent dosing — effect fades within days of daily use · Paradoxical anxiety in some users (amygdala over-tune) · Headache · Uterine contractions — absolute contraindication in pregnancy except labor induction under OB supervision · Rare arrhythmia, hyponatremia with high-dose IV · Emotional manipulation by partners using it is a non-trivial safety concern · Not indicated for chronic social anxiety — short-acting only",
            mitigations: "Intranasal route, 10-40 IU per dose as-needed — not daily. Allow at least 2-3 days between doses to prevent tolerance. Avoid in pregnancy (absolutely, outside labor induction), lactation issues, cardiac arrhythmia. Start low (10 IU) to assess mood direction — some users get paradoxical anxiety. Don't use for manipulating others' emotions in dating / negotiation contexts — ethical boundary. Source from compounding pharmacy when possible. Stop for persistent mood destabilization, new-onset anxiety, or cardiac symptoms."
        ),

        Compound(
            name: "AICAR",
            slug: "aicar",
            halfLifeHrs: 1,
            dosingRangeLowMcg: 500,
            dosingRangeHighMcg: 1_000,
            benefits: ["AMPK activation", "Endurance enhancement", "Fat oxidation"],
            sideEffects: ["Transient tachycardia", "Elevated uric acid", "Mild GI upset"],
            stackingNotes: "Exercise mimetic. Often combined with SLU-PP-332 or MOTS-c for metabolic protocols.",
            fdaStatus: .research,
            summaryMd: "AICAR (5-aminoimidazole-4-carboxamide ribonucleotide) activates AMPK — the cellular 'low energy' sensor. Researched as an exercise mimetic for endurance and metabolic flexibility.",
            goalCategories: ["fat_loss", "longevity"],
            administrationRoutes: ["subq", "im"],
            timeToEffectHours: 0.5,
            peakEffectHours: 1,
            durationHours: 4,
            dosingFormula: "750",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 48,
            effectsTimeline: "Week 1: mild increase in exercise endurance, less perceived effort during training. Week 2-4: fat oxidation shifts measurable, slight body-comp changes. Week 6-8: mitochondrial biogenesis consolidating. Subq or IM dosing. 500-1000 mcg daily typical, often paired with SLU-PP-332 or MOTS-c. Preclinical to early clinical evidence base.",
            mechanism: "5-aminoimidazole-4-carboxamide ribonucleotide — an adenosine monophosphate analogue. Directly activates AMP-activated protein kinase (AMPK), the cellular 'low energy' sensor, by mimicking AMP. AMPK downstream: increases GLUT4 glucose uptake, fatty-acid oxidation, mitochondrial biogenesis, autophagy — essentially the transcriptional program of exercise adaptation. Same final pathway as metformin and MOTS-c but acts more directly. Classified as an 'exercise mimetic.' WADA-banned since 2009 for this reason.",
            risks: "Transient tachycardia post-injection (adenosine-like cardiovascular effect) · Elevated uric acid (increased purine metabolism) → gout risk in susceptible users · Mild GI upset · Hypoglycemia at high doses or with diabetic medications · Limited human data · Theoretical cancer concerns: AMPK activation can be tumor-suppressive or permissive depending on context · No FDA approval · WADA-banned · Immunogenicity with chronic use · Expensive · Drug interactions with AMPK-activating drugs (metformin) — additive",
            mitigations: "Start 250-500 mcg to assess cardiovascular response. Monitor HR and BP during first few doses. Baseline + 6-week fasting glucose, A1c, uric acid, liver enzymes. Avoid in gout, arrhythmia, uncontrolled diabetes on insulin/sulfonylurea, pregnancy, active cancer. Don't stack with metformin at full doses — additive AMPK effect. Cycle 6-8 weeks on, 2-4 weeks off. Hydrate well to clear purine byproducts. Stop for palpitations, gout flare, or fatigue worsening."
        ),

        Compound(
            name: "ARA-290",
            slug: "ara-290",
            halfLifeHrs: 0.1,
            dosingRangeLowMcg: 2_000,
            dosingRangeHighMcg: 4_000,
            benefits: ["Neuropathy relief", "Anti-inflammatory", "Tissue protection"],
            sideEffects: ["Generally well tolerated", "Mild injection site reaction"],
            stackingNotes: "Researched for diabetic neuropathy and sarcoidosis pain. Non-hematopoietic EPO analogue.",
            fdaStatus: .research,
            summaryMd: "ARA-290 (Cibinetide) is an 11-amino-acid fragment of erythropoietin with anti-inflammatory and tissue-protective effects but no hematopoietic activity. Researched for neuropathic pain.",
            goalCategories: ["recovery", "immune"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 1,
            peakEffectHours: 4,
            durationHours: 24,
            dosingFormula: "3000",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 49,
            effectsTimeline: "Week 1-2: neuropathic pain symptoms starting to soften in responders. Week 4: measurable improvements in sarcoidosis pain, diabetic neuropathy, chronic inflammatory pain. Week 8-12: cumulative anti-inflammatory tissue-protective effect. Subq daily or QOD. Subtle onset, not dramatic — most useful for chronic neuropathy and inflammatory nerve pain populations.",
            mechanism: "11-amino-acid synthetic peptide (Cibinetide, pHBSP) derived from erythropoietin's B-helix — the active anti-inflammatory / tissue-protective fragment of EPO WITHOUT the hematopoietic (red-cell-stimulating) activity. Binds the heterodimeric innate repair receptor (IRR) comprising EPO-R and CD131 (beta common chain), which is expressed only on stressed or inflamed tissue. Activates PI3K/Akt and JAK2/STAT5 downstream → anti-apoptotic, anti-inflammatory, and tissue-protective effects in injured tissue specifically. Phase 2 data for diabetic neuropathy and sarcoidosis pain.",
            risks: "Generally very well-tolerated — no hematologic effects (key safety feature vs EPO itself) · Mild injection-site reactions · Headache uncommon · Limited long-term safety data · Unknown in pregnancy · Phase 2/3 stalled due to funding, not safety signals · Grey-market status in US · Immunogenicity possible with chronic use · Theoretical: EPO-receptor pathway has complex tumor biology (some cancers express EPO-R)",
            mitigations: "Start 1-2 mg subq to assess tolerance. Daily or QOD dosing. 8-12 week trials reasonable. Baseline CBC (ensure no surprise erythrocytosis from impurity — shouldn't occur but vendor variance matters). Source with COA given specialty compound. Avoid in active cancer (particularly renal cell carcinoma or any EPO-R expressing tumor), pregnancy, uncontrolled hypertension. Best for neuropathy / chronic inflammatory nerve pain populations — not a general wellness compound. Stop for any unexplained erythrocytosis, hypertension, or new neurological symptoms."
        ),

        Compound(
            name: "Gonadorelin",
            slug: "gonadorelin",
            halfLifeHrs: 0.1,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["HPG axis maintenance", "Testicular function", "Fertility support"],
            sideEffects: ["Injection site reaction", "Headache", "Flushing"],
            stackingNotes: "Used as an HCG alternative during TRT to preserve testicular function. Pulsatile dosing (2-3x daily) preferred.",
            fdaStatus: .approved,
            summaryMd: "Gonadorelin is a synthetic GnRH decapeptide that stimulates pituitary LH/FSH release. Used during TRT to preserve endogenous testicular function and fertility.",
            goalCategories: ["libido", "growth"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 2,
            dosingFormula: "200",
            dosingUnit: "mcg",
            dosingFrequency: "3x_daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"],
            popularityRank: 50,
            effectsTimeline: "Within 30-60 min: LH and FSH pulse on labs. Week 1-2: testicular tone / size maintained (key use during TRT). Week 4-8: preserves fertility markers in men on testosterone. Requires pulsatile dosing (2-3x daily) to mimic natural GnRH pulsatility — continuous or infrequent dosing causes paradoxical suppression (same mechanism as GnRH agonists used for prostate cancer).",
            mechanism: "Synthetic decapeptide identical to endogenous gonadotropin-releasing hormone (GnRH / LHRH). Binds pituitary GnRH receptors → LH and FSH release → testicular Leydig cell T production (men) or ovarian follicle recruitment (women). Key pharmacology detail: pulsatile exposure = agonist (stimulates HPG axis); continuous exposure = functional antagonist via receptor desensitization (suppresses HPG axis — how Leuprolide treats prostate cancer). Very short half-life (~4 min IV, ~10-40 min subq) which is WHY pulsatile dosing works.",
            risks: "Must be dosed 2-3x daily, not once — single daily dosing can paradoxically suppress HPG axis (the opposite of intended effect) · Injection-site reactions · Headache · Flushing · Rare anaphylaxis · Mood shifts as T rises · Unknown impact on any undiagnosed hormone-sensitive cancer · Gynecomastia risk if estradiol rises with T · Pregnancy contraindicated · Often counterfeited / underdosed on grey market",
            mitigations: "Dose 2-3x daily pulsatile — 100-200 mcg subq — NOT once daily. Used primarily during TRT to preserve testicular function (alternative to HCG with fewer downsides). Baseline + 6-week total T, free T, LH, FSH, estradiol, PSA (men), CBC. Avoid in prostate cancer history, active breast cancer, pregnancy, uncontrolled cardiovascular disease. Source with COA — common counterfeit target. Stop for unexplained chest pain, severe flushing, or testicular pain. Not a TRT replacement — a TRT adjunct."
        ),

        Compound(
            name: "HCG",
            slug: "hcg",
            halfLifeHrs: 36,
            dosingRangeLowMcg: 250,
            dosingRangeHighMcg: 500,
            benefits: ["Testicular function preservation", "Fertility support", "Endogenous testosterone"],
            sideEffects: ["Gynecomastia risk", "Mood swings", "Acne", "Water retention"],
            stackingNotes: "Mimics LH. Used during TRT or post-cycle to restart HPG axis. 2-3x weekly dosing.",
            fdaStatus: .approved,
            summaryMd: "Human chorionic gonadotropin (HCG) is an FDA-approved LH-mimicking hormone used for fertility, cryptorchidism, and TRT support to preserve testicular size and function.",
            goalCategories: ["libido", "growth"],
            administrationRoutes: ["subq", "im"],
            timeToEffectHours: 6,
            peakEffectHours: 12,
            durationHours: 72,
            dosingFormula: "300",
            dosingUnit: "mcg",
            dosingFrequency: "2x_weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 51,
            effectsTimeline: "Day 3-5: testicular tone/volume returning if shrunk on TRT. Week 1-2: libido, morning erections typically improve. Week 4: fertility markers (sperm count) start to recover if suppressed. Week 8-12: full testicular function restoration possible. Used primarily during/after TRT or steroid cycles to preserve or restart HPG axis. 250-500 IU subq 2-3x weekly (or 500-1000 IU 2x weekly during TRT).",
            mechanism: "Human chorionic gonadotropin — natural peptide hormone produced by placenta. Binds LH receptor on testicular Leydig cells (men) or ovarian thecal cells (women) — mimics LH almost identically. In men: drives Leydig cells to produce testosterone locally in the testis and maintains Sertoli cell function for sperm production. Much longer half-life (~24-36h) than LH itself, so 2-3x weekly dosing gives steady receptor stimulation. FDA-approved for cryptorchidism, hypogonadotropic hypogonadism, and anovulatory infertility.",
            risks: "Gynecomastia risk — HCG stimulates testicular testosterone AND aromatization to estradiol · Mood swings as T/E2 shifts · Acne · Water retention · Headache · Rare but serious: ovarian hyperstimulation syndrome in women · Thromboembolic risk elevated slightly · Long-term use (>6 months continuous) can desensitize Leydig cells → paradoxical testicular dysfunction · HCG-associated hypertension · Pregnancy contraindicated (except fertility) · Often counterfeited on grey market",
            mitigations: "Cycle or pulse dosing — avoid continuous >6 months. On TRT: 500 IU 2x weekly alongside T maintains testicular volume without desensitization. For post-cycle restart: 2000-3000 IU EOD for 2-3 weeks then taper. Monitor estradiol — aromatase inhibitor may be needed. Baseline + 6-week: total T, free T, estradiol, LH, FSH, CBC, hematocrit, PSA (men >40). Avoid in prostate cancer, breast cancer, thromboembolic history, pregnancy (non-fertility). Source from legitimate Rx channel — grey market frequently underdosed. Stop for breast tenderness, severe water retention, or chest pain."
        ),

        Compound(
            name: "Humanin",
            slug: "humanin",
            halfLifeHrs: 2,
            dosingRangeLowMcg: 500,
            dosingRangeHighMcg: 2_000,
            benefits: ["Mitochondrial protection", "Insulin sensitivity", "Neuroprotection", "Longevity signaling"],
            sideEffects: ["Generally well tolerated", "Mild fatigue"],
            stackingNotes: "Mitochondrial-derived peptide (same family as MOTS-c). Stacks well for longevity protocol.",
            fdaStatus: .research,
            summaryMd: "Humanin is a 24-amino-acid mitochondrial-derived peptide researched for neuroprotection, insulin sensitivity, and aging. Declines with age in humans.",
            goalCategories: ["longevity", "cognitive"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 2,
            peakEffectHours: 6,
            durationHours: 24,
            dosingFormula: "1000",
            dosingUnit: "mcg",
            dosingFrequency: "3x_weekly",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 52,
            effectsTimeline: "Week 1-2: subtle — some users report cognitive clarity emerging. Week 4-6: insulin sensitivity markers improve, metabolic flexibility shifts favorably in older users. Week 8-12: cumulative neuroprotective effects. Preclinical-heavy evidence — human data primarily observational. 1-2 mg subq 3x weekly. Cycle 8-12 weeks.",
            mechanism: "24-amino-acid mitochondrial-derived peptide (MDP) encoded in mitochondrial 16S rRNA. Sibling to MOTS-c — both are mitokines signaling from mitochondria to nucleus and other cells. Mechanisms: (1) Anti-apoptotic — binds and inhibits Bax (pro-apoptotic protein) and IGFBP-3, protecting neurons from Alzheimer's amyloid-beta toxicity; (2) Insulin-sensitizing via unclear central mechanism; (3) Metabolic regulation through FPRL1 and a specific Humanin receptor complex. Plasma levels decline with age, linked to metabolic decline.",
            risks: "Very limited human clinical data · Theoretical: mitochondrial signaling effects not fully characterized · Anti-apoptotic activity raises theoretical cancer concern — cancer cells evade apoptosis, and Humanin's Bax inhibition could theoretically promote survival of transformed cells · Mild injection-site reactions · No FDA approval · Cancer drug interaction potential (interferes with apoptotic chemotherapy mechanism) · Grey-market purity variable · Pregnancy unknown · Unknown long-term safety",
            mitigations: "Start 1 mg subq to assess response. 3x weekly dosing aligns with half-life. 8-12 week cycles, then 4-6 weeks off. Full cancer screen baseline — absolute contraindication if active malignancy (anti-apoptotic mechanism). Avoid during chemotherapy (interferes with treatment-induced apoptosis). Stack thoughtfully with MOTS-c — same MDP family, likely synergistic but untested combo. Baseline CBC, CMP, fasting glucose, A1c. Source with COA. Stop for any new lump, unexplained bleeding, or unusual fatigue."
        ),

        Compound(
            name: "Thymalin",
            slug: "thymalin",
            halfLifeHrs: 12,
            dosingRangeLowMcg: 1_000,
            dosingRangeHighMcg: 2_000,
            benefits: ["Immune modulation", "Thymic function restoration", "Age-related immunity"],
            sideEffects: ["Generally mild", "Injection site reaction"],
            stackingNotes: "Russian bioregulator extracted from thymus. Cycle 10 days on, several months off.",
            fdaStatus: .research,
            summaryMd: "Thymalin is a thymus-derived polypeptide complex researched in Russia for immune restoration in aging and chronic illness. Part of the Khavinson bioregulator family.",
            goalCategories: ["immune", "longevity"],
            administrationRoutes: ["im", "subq"],
            timeToEffectHours: 12,
            peakEffectHours: 24,
            durationHours: 72,
            dosingFormula: "1500",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "glute-im-left"],
            popularityRank: 53,
            effectsTimeline: "Week 1-2 (10-day IM course): mild injection-site soreness, immune-panel markers begin shifting. Week 2-4: subjective energy, infection resistance, wound healing improvement in deficient users (elderly, post-illness, chronic stress). Russian bioregulator protocol: 10-day course, then 4-6 months off, repeat 1-2x yearly. Not daily chronic use.",
            mechanism: "Polypeptide complex extracted from bovine or porcine thymus — part of the Khavinson Russian bioregulator family. Thymalin is less characterized chemically than the synthetic tripeptide-based bioregulators (Thymogen, Epithalon) because it's a mixture of thymic polypeptides rather than a single defined molecule. Proposed mechanism: restores thymus-derived T-cell production and maturation in aging or stressed immune systems, modulates cytokine balance, and increases NK cell activity. Russian literature claims immune restoration in elderly and chronic illness populations.",
            risks: "Animal-origin (bovine/porcine) — allergy, TSE/BSE theoretical concern depending on source · Less defined chemical composition than synthetic bioregulators (batch-to-batch variability) · Injection-site reactions · Theoretical autoimmune flare · Immunogenicity with repeated use · Russian-origin literature primary source — Western-standard RCTs absent · No FDA approval · Vendor quality highly variable · Pregnancy unknown · Less clean than Thymosin Alpha-1 for the same use case",
            mitigations: "Consider Thymosin Alpha-1 (synthetic, defined peptide) first for immune modulation — generally more reliable and better characterized. If using Thymalin specifically: source only from vendors with veterinary-grade controlled origin documentation. 10-day IM course 1.5 mg daily, then 4-6 months off. Baseline CBC with differential, lymphocyte subsets, basic allergy screen. Avoid in active autoimmune flare, organ transplant on immunosuppression, pregnancy, known bovine/porcine allergy. Stop for any signs of allergic reaction or unexplained fever."
        ),

        Compound(
            name: "Thymogen",
            slug: "thymogen",
            halfLifeHrs: 1,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["Immune modulation", "T-cell stimulation", "Anti-inflammatory"],
            sideEffects: ["Generally well tolerated", "Mild drowsiness"],
            stackingNotes: "Intranasal form common. Russian bioregulator — shorter synthetic than Thymalin.",
            fdaStatus: .research,
            summaryMd: "Thymogen (Glu-Trp) is a synthetic dipeptide derived from Thymalin research. Stimulates T-cell differentiation and cellular immunity.",
            goalCategories: ["immune"],
            administrationRoutes: ["im", "subq", "nasal"],
            timeToEffectHours: 1,
            peakEffectHours: 4,
            durationHours: 24,
            dosingFormula: "200",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 54,
            effectsTimeline: "Day 1-3 (intranasal): subtle increase in baseline energy, less susceptibility to minor infections. Week 1-2: immune markers shift favorably in deficient populations. Week 2-4: stable immune-support effect. 10-day course standard Russian protocol, then 1-2 month break. Synthetic, defined peptide — more predictable than Thymalin.",
            mechanism: "Synthetic dipeptide Glu-Trp (two amino acids only) — derived from Thymalin research as the minimal bioactive fragment. Despite minimal size, it retains thymic-immunomodulatory activity: stimulates T-cell differentiation (CD3+, CD4+ subsets), enhances cellular immunity, modulates cytokine profile. Proposed mechanism: binds to thymic and CNS receptors, activates transcription of immune-relevant genes. Russian medical literature cites use in chronic infections, post-surgical recovery, and immunodeficiency.",
            risks: "Generally well-tolerated — among the mildest Russian bioregulators · Mild drowsiness (only reported notable effect) · Nasal irritation if intranasal route · Theoretical immune modulation in existing autoimmune flare · No FDA approval · Russian-origin data primary · Supply quality variable · Unknown in pregnancy · Dipeptide is easy to synthesize so cheap — authenticity generally easier to verify than larger peptides",
            mitigations: "Intranasal route most common — 100-300 mcg/day. 10-day courses, then 1-2 months off. Source with COA. Avoid in active autoimmune disease, uncontrolled allergy flare, pregnancy. Minimal labs required for healthy users. Baseline sense of energy / infection frequency for personal tracking. Stop for persistent drowsiness or allergic-type reactions."
        ),

        Compound(
            name: "Adipotide",
            slug: "adipotide",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 500,
            dosingRangeHighMcg: 1_000,
            benefits: ["Targeted adipose tissue reduction", "Weight loss via fat vasculature ablation"],
            sideEffects: ["Kidney stress", "Dehydration", "Not recommended for humans without supervision"],
            stackingNotes: "Experimental only. Monitor kidney function. Short cycles (4 weeks) at minimum effective dose.",
            fdaStatus: .research,
            summaryMd: "Adipotide (FTPP) is a proapoptotic peptide that targets fat tissue vasculature, causing fat cells to be reabsorbed. Primate studies showed rapid fat loss; human safety data limited.",
            goalCategories: ["fat_loss"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 24,
            peakEffectHours: 72,
            durationHours: 168,
            dosingFormula: "750",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 55,
            effectsTimeline: "Week 1-2: injection-site discomfort, mild fatigue. Week 3-4: localized or systemic fat reduction — can be dramatic in primate models. Week 4-6: kidney stress signals emerge if not monitored. Human data severely limited and concerning — designed for cancer-induced cachexia, not cosmetic fat loss. Short cycles only.",
            mechanism: "Proapoptotic peptidomimetic (FTPP: fat-targeted proapoptotic peptide). Two-domain design: one part binds prohibitin on adipose tissue vasculature (adipose-selective targeting), the other (D(KLAKLAK)2 sequence) triggers mitochondrial outer membrane permeabilization → apoptosis of the endothelial cells feeding fat deposits → fat tissue is reabsorbed as it loses blood supply. Originally developed at MD Anderson for obesity treatment based on primate studies showing dramatic fat loss. Essentially, kills fat-tissue vasculature.",
            risks: "KIDNEY STRESS — the defining risk. Primate studies showed renal toxicity, particularly proximal tubule damage, at doses producing visible fat loss. Several human case reports of acute kidney injury · Dehydration amplifies renal risk · Fatigue from apoptotic cleanup load · Compensatory hyperphagia possible on stopping (fat cells mostly gone, but not all mechanisms of fat regain) · Not FDA-approved; human trials stalled over safety · Extremely narrow therapeutic window · Pregnancy contraindicated · Grey-market supply varied · Theoretical: similar apoptotic mechanism could affect other vascular beds",
            mitigations: "Treat as experimental with narrow therapeutic index. Short cycles only — 4 weeks max, NEVER chronic. Start at 500 mcg/day; never exceed 1 mg. Aggressive hydration (2.5-3 L water daily) to protect kidneys. Baseline + weekly during cycle: serum creatinine, eGFR, urine protein/creatinine ratio, CBC. STOP IMMEDIATELY for eGFR drop >10, new proteinuria, or any new flank pain. Avoid in any renal disease (mild CKD included), diabetes, hypertension with nephropathy, pregnancy. Not appropriate for cosmetic fat loss use given risk profile — reserve for intractable obesity under supervision. Safer alternatives (GLP-1s, tirzepatide) should be tried first."
        ),

        Compound(
            name: "Matrixyl",
            slug: "matrixyl",
            halfLifeHrs: 6,
            dosingRangeLowMcg: 1_000,
            dosingRangeHighMcg: 3_000,
            benefits: ["Collagen synthesis", "Fine line reduction", "Skin firmness"],
            sideEffects: ["Generally well tolerated", "Topical irritation (rare)"],
            stackingNotes: "Topical use primary. Often combined with GHK-Cu in advanced skincare serums.",
            fdaStatus: .research,
            summaryMd: "Matrixyl (palmitoyl pentapeptide-4) is a skincare peptide researched for collagen I/III stimulation in the dermis. Well-studied in cosmetic formulations for anti-aging.",
            goalCategories: ["skin_hair"],
            administrationRoutes: ["topical"],
            timeToEffectHours: 168,
            peakEffectHours: 720,
            durationHours: 24,
            dosingFormula: "2000",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 0,
            storageTemp: "room",
            storageMaxDays: 180,
            recommendedSiteIds: [],
            popularityRank: 56,
            effectsTimeline: "Week 2-4 (topical daily): skin smoother, fine lines noticeably softer. Week 8-12: collagen synthesis measurable changes in dermal thickness studies. Week 16+: cumulative anti-aging effect. Not dramatic like tretinoin — modest but real. Best as part of comprehensive skincare not standalone. Topical 3-10% concentration 1-2x daily.",
            mechanism: "Palmitoyl pentapeptide-4 (Pal-KTTKS) — a synthetic pentapeptide derived from the procollagen I C-terminal propeptide, fatty-acid conjugated (palmitoyl) for skin penetration. Binds fibroblast receptors and mimics natural collagen fragment signaling → upregulates type I and III collagen synthesis, fibronectin, glycosaminoglycans, and hyaluronic acid production. Different mechanism from retinoids (which increase cell turnover) — Matrixyl stimulates matrix production directly. Complementary with GHK-Cu (copper peptide) in advanced anti-aging formulations.",
            risks: "Very well-tolerated topically — one of the safest cosmetic peptides · Rare contact dermatitis or irritation · No systemic absorption to speak of · Modest effect (cosmetic peptides generally show 10-30% improvement vs 40-80% for retinoids) · Can take 3-6 months for visible results · Peptide can degrade in light / heat / time if not properly formulated · Not effective for deep wrinkles or photodamage — more for fine lines / early aging · Pregnancy safe (minimal absorption)",
            mitigations: "Apply to clean dry skin 1-2x daily. Works synergistically with GHK-Cu, Matrixyl-3000, and Argireline in layered regimens. Not a replacement for sunscreen, tretinoin, or good sleep — it's an add-on. Stable in opaque packaging (light-sensitive); store cool. Photograph skin baseline to gauge 3-month progress objectively. No labs or special monitoring needed. Stop for any irritation, though rare. Can be combined with retinoids but apply at different times of day (Matrixyl AM, retinoid PM)."
        ),

        Compound(
            name: "CJC-1295 No DAC",
            slug: "cjc-1295-no-dac",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 200,
            benefits: ["Natural GH pulse", "Deeper slow-wave sleep", "Circadian-aligned GH surge", "Recovery", "Fat loss"],
            sideEffects: ["Flushing", "Headache", "Injection site reaction"],
            stackingNotes: "Short-acting CJC variant (Mod GRF 1-29). Dosed pre-bed with Ipamorelin to ride the natural slow-wave-sleep GH pulse — the most popular reason to run this stack.",
            fdaStatus: .research,
            summaryMd: "CJC-1295 without DAC (Mod GRF 1-29) is a short-acting GHRH analogue. Produces a clean GH pulse that mirrors natural pulsatility, and pre-bed dosing with Ipamorelin amplifies the slow-wave-sleep GH surge for noticeably deeper sleep.",
            goalCategories: ["growth", "sleep", "recovery"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 2,
            dosingFormula: "150",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"],
            popularityRank: 57,
            effectsTimeline: "Night 1 (pre-bed dose): deeper slow-wave sleep often immediate. Week 1-2: morning recovery noticeably better, dreams vivid. Week 4: lean mass trending up if training, body-fat trending down. Week 8-12: skin quality, recovery, sleep consolidated. The classic pulsatile GHRH stack component — cleaner than DAC version for long-term physiological use. 100-200 mcg pre-bed, stacked with Ipamorelin 100-300 mcg.",
            mechanism: "Short-acting GHRH analogue — Mod GRF 1-29 with four amino acid substitutions (D-Ala, Gln, Ala, Leu) for protease resistance. Without DAC, half-life is ~30 min — produces a clean GH pulse closely mimicking native GHRH. Activates GHRH receptors on pituitary somatotrophs → cAMP → pulsatile GH synthesis and release. Subject to somatostatin negative feedback (unlike DAC version) — preserves physiological on/off rhythm. Stacks synergistically with Ipamorelin: GHRH + ghrelin receptor co-activation creates larger pulse than either alone.",
            risks: "Flushing, especially facial (mediated by peripheral GHRH receptors) · Headache · Injection site reactions · Minimal water retention vs DAC version · Mild lightheadedness post-dose · Theoretical IGF-1-mediated cancer acceleration on undiagnosed malignancy · Immunogenicity possible with chronic use · Desensitization less concerning than DAC but still possible with chronic use · Not FDA-approved · WADA-banned",
            mitigations: "Pre-bed dosing aligns with natural GH pulse and turns flushing side effect into 'warmth lulling you to sleep.' Stack with Ipamorelin 100-300 mcg at same injection for synergistic pulse. 5-days-on/2-off or 12-weeks-on/4-off cycling. Dose 30+ min fasted — food blunts GH pulse. Baseline + 3-month IGF-1, fasting glucose, A1c. Cancer screening baseline. Keep epi accessible for first 3 doses. Start 100 mcg to test reaction. Stop for persistent flushing > 30 min, chest tightness, or new hand numbness."
        ),

        Compound(
            name: "IGF-1 DES",
            slug: "igf-1-des",
            halfLifeHrs: 0.5,
            dosingRangeLowMcg: 20,
            dosingRangeHighMcg: 75,
            benefits: ["Localized hyperplasia", "Fast-acting muscle growth", "Satellite cell activation"],
            sideEffects: ["Hypoglycemia", "Injection site soreness"],
            stackingNotes: "Inject directly into trained muscles. Shorter and more potent locally than LR3.",
            fdaStatus: .research,
            summaryMd: "IGF-1 DES (1-3) is a truncated IGF-1 variant researched for localized muscle hyperplasia. Shorter half-life than LR3 but more potent at target tissue.",
            goalCategories: ["growth"],
            administrationRoutes: ["im", "subq"],
            timeToEffectHours: 0.5,
            peakEffectHours: 1,
            durationHours: 4,
            dosingFormula: "50",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 1.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["glute-im-left", "glute-im-right"],
            popularityRank: 58,
            effectsTimeline: "30 min post-injection: pump and fullness at injection-site muscle. Day 1-3: localized strength and size at injected muscle noticeably up vs control. Week 2-4: localized hypertrophy and satellite cell activation — used strategically for lagging body parts. Shorter half-life (~30 min) than LR3 so systemic cancer/hypoglycemia risks are lower, but local potency is higher. Inject immediately post-workout directly into trained muscle.",
            mechanism: "Truncated IGF-1 variant — the native tripeptide Gly-Pro-Glu removed from the N-terminus. This modification dramatically reduces affinity for IGFBPs (binding proteins that normally sequester IGF-1) while preserving IGF-1 receptor binding affinity. Result: shorter half-life (~20-30 min vs 20-30h for LR3) but higher local bioactivity at injection site because no IGFBP buffering. Activates IGF-1R → PI3K/Akt (protein synthesis, anti-apoptosis) and MAPK/ERK (satellite cell proliferation). Preferred for targeted local hypertrophy due to its short, concentrated local action vs LR3's systemic chronic elevation.",
            risks: "Hypoglycemia — less severe than LR3 due to short half-life but still real risk at higher doses · Local muscle soreness pronounced · Joint and tendon strain if muscle growth outpaces connective tissue adaptation · Theoretical cancer acceleration via IGF-1R activation on undiagnosed malignancy · Cardiomyocyte hypertrophy risk with systemic use (why local IM is preferred) · No FDA approval · WADA-banned · Grey market purity variable · Acromegaly-like changes with chronic systemic use (uncommon with local protocols) · Insulin co-administration catastrophic (fatalities reported)",
            mitigations: "Local IM injection post-workout only — systemic subq multiplies cancer and acromegaly concerns unnecessarily. Cap at 20-75 mcg per injection, one muscle per day. Eat 20-30g carb + 20g protein within 15 min of injection to preempt hypoglycemia. Keep glucose tabs accessible first hour post-injection. Never combine with exogenous insulin. Full cancer screen baseline (same as LR3). 4-week cycles, 6-8 weeks off. Rotate target muscles — don't hit same muscle repeatedly. Baseline echo if running multiple cycles. Stop for unexplained joint pain, cardiac symptoms, or fasting glucose shift."
        ),

        Compound(
            name: "GHRH",
            slug: "ghrh",
            halfLifeHrs: 0.1,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 200,
            benefits: ["Endogenous GH release", "Sleep quality", "Recovery"],
            sideEffects: ["Flushing", "Headache", "Short-lived effect"],
            stackingNotes: "Native GHRH sequence — rapidly degraded in plasma. Analogues (Sermorelin, Tesamorelin) usually preferred.",
            fdaStatus: .approved,
            summaryMd: "GHRH (Growth Hormone Releasing Hormone) is the native 44-amino-acid hypothalamic peptide that drives pituitary GH secretion. Approved for GH deficiency diagnostics.",
            goalCategories: ["growth"],
            administrationRoutes: ["subq"],
            timeToEffectHours: 0.25,
            peakEffectHours: 0.5,
            durationHours: 1,
            dosingFormula: "150",
            dosingUnit: "mcg",
            dosingFrequency: "daily",
            bacWaterMlDefault: 2.0,
            storageTemp: "refrigerated",
            storageMaxDays: 30,
            recommendedSiteIds: ["abdomen-subq-left"],
            popularityRank: 59,
            effectsTimeline: "15-30 min post-injection: GH pulse on labs (rapid and sharp). Effects largely acute, minutes-to-hours. Week 1-2: sleep quality improves if dosed pre-bed. Week 4-8: recovery shifts. However native GHRH is rarely chosen over analogues (Sermorelin, Tesamorelin, CJC) because its <7 min half-life requires multiple daily injections and bursty delivery. Primarily used as a diagnostic test (GHRH stimulation test) for GH deficiency, not therapy.",
            mechanism: "Endogenous 44-amino-acid hypothalamic peptide (Growth Hormone Releasing Hormone). Binds GHRH receptor on pituitary somatotrophs → Gs / cAMP / PKA → GH synthesis and pulsatile release. The natural upstream signal that drives the GH axis. Rapidly degraded by DPP-IV enzymatic cleavage (why native GHRH isn't practical for chronic therapy and all real-world analogues are DPP-IV resistant). FDA-approved only for diagnostic use (GHRH stimulation test to diagnose adult GH deficiency vs pituitary insufficiency).",
            risks: "Very short effective duration (<7 min half-life) requires frequent injections · Flushing, especially facial · Headache · Mild injection-site reactions · Not practical for chronic therapy — every clinically useful GH secretagogue is a modified GHRH analogue rather than native GHRH · Theoretical IGF-1-mediated cancer concern shared with all GH-axis agents · Immunogenicity rare · Limited grey-market use given superior alternatives exist (Sermorelin, Tesamorelin, CJC variants) · Pregnancy contraindicated",
            mitigations: "Native GHRH has few practical advantages over analogues for chronic use — Sermorelin (29-aa GHRH with identical mechanism but more stable) or CJC-1295 No DAC (modified for protease resistance) are superior choices for therapy. Use GHRH only for diagnostic testing under clinical supervision. If insisting on therapeutic use: 1 mcg/kg subq 3-4x daily to achieve meaningful cumulative effect — impractical most users. Baseline IGF-1, fasting glucose, cancer screening. Avoid in active cancer, pregnancy. Source carefully — rarely counterfeited because demand is low."
        ),

        Compound(
            name: "Argireline",
            slug: "argireline",
            halfLifeHrs: 12,
            dosingRangeLowMcg: 1_000,
            dosingRangeHighMcg: 3_000,
            benefits: ["Expression-line reduction", "Topical anti-aging", "SNAP-25 modulation"],
            sideEffects: ["Generally well tolerated", "Topical irritation (rare)"],
            stackingNotes: "Topical only. Often called 'topical Botox' — inhibits neurotransmitter release in facial muscles.",
            fdaStatus: .research,
            summaryMd: "Argireline (acetyl hexapeptide-3/8) is a topical cosmetic peptide researched for expression-line reduction by partially inhibiting SNAP-25-mediated neurotransmitter release.",
            goalCategories: ["skin_hair"],
            administrationRoutes: ["topical"],
            timeToEffectHours: 72,
            peakEffectHours: 336,
            durationHours: 24,
            dosingFormula: "2000",
            dosingUnit: "mcg",
            dosingFrequency: "2x_daily",
            bacWaterMlDefault: 0,
            storageTemp: "room",
            storageMaxDays: 180,
            recommendedSiteIds: [],
            popularityRank: 60,
            effectsTimeline: "Week 2-4 (topical daily): forehead and crow's-feet fine lines softer. Week 6-8: cumulative expression-line reduction ~10-30% measurable. Week 12+: plateau — continued use maintains, doesn't progressively improve. Modest effect — essentially 'topical mini-Botox' without the injection. Not a replacement for actual botulinum toxin for deeper dynamic lines. Cosmetic peptide, not systemic.",
            mechanism: "Acetyl hexapeptide-3/8 (Ac-Glu-Glu-Met-Gln-Arg-Arg-NH2) — synthetic hexapeptide derived from the SNAP-25 protein. Competes with SNAP-25 for incorporation into the SNARE complex required for neurotransmitter vesicle fusion at neuromuscular junctions. Result: partial, reversible inhibition of acetylcholine release from motor neurons in facial muscles → reduced muscle contraction → softer expression lines. Same final step as botulinum toxin (which cleaves SNAP-25) but Argireline is vastly weaker and acts topically on skin-penetrating extent only.",
            risks: "Very mild — among the safest cosmetic peptides · Modest efficacy relative to retinoids or botulinum · Rare contact dermatitis / local irritation · Theoretical: could reduce skin's response to its own muscle movement over time but reversible · Not effective for static wrinkles (only dynamic expression lines) · Must be formulated and stored properly (peptide degradation in poor packaging) · Pregnancy safe (negligible systemic absorption) · No systemic labs or monitoring needed",
            mitigations: "Apply 2x daily to clean dry skin targeting forehead, between eyes, crow's-feet. Stable formulations require opaque packaging and cool storage. Pair with retinoid PM, Argireline AM (gentler than retinoid so daytime-tolerable). Not a replacement for tretinoin, sunscreen, or Botox for users seeking dramatic results — it's a gentle add-on. Photograph baseline for objective 3-month assessment. Compatible with most skincare actives (GHK-Cu, Matrixyl, niacinamide, hyaluronic acid). Stop only for contact irritation, which is rare."
        ),
    ]

    /// Display names like `CJC-1295 + Ipamorelin` (one vial). For lookups we
    /// use the **first** member so dosing defaults & PK still resolve.
    static let blendDisplaySeparator = " + "

    static func compound(named name: String) -> Compound? {
        let primary = primaryCanonicalName(forProtocolDisplay: name)
        return allCompoundsSeed.first { $0.name == primary || $0.slug == primary }
    }

    /// Canonical names for a blend saved as `A + B + C`, or nil if not a blend.
    static func blendMembers(fromDisplayName name: String) -> [String]? {
        guard name.contains(blendDisplaySeparator) else { return nil }
        let parts = name.components(separatedBy: blendDisplaySeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.count >= 2 ? parts : nil
    }

    /// Single-compound name or first peptide in a blend string.
    static func primaryCanonicalName(forProtocolDisplay name: String) -> String {
        blendMembers(fromDisplayName: name)?.first ?? name
    }

    // Compounds tagged with at least one of the given goal IDs.
    static func compoundsForGoals(_ goalIds: [String]) -> [Compound] {
        let goals = Set(goalIds)
        return allCompoundsSeed.filter { c in
            !c.goalCategories.allSatisfy { !goals.contains($0) }
        }
    }
}
