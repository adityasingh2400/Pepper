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
        .init(canonical: "BPC-157",          category: .healing, aliases: ["bpc", "b p c", "bpc 157", "bpc157"]),
        .init(canonical: "TB-500",           category: .healing, aliases: ["tb", "tb 500", "tb500", "thymosin beta"]),
        .init(canonical: "GHK-Cu",           category: .healing, aliases: ["ghk", "g h k", "ghk copper", "copper peptide"]),
        .init(canonical: "Thymosin Alpha-1", category: .healing, aliases: ["thymosin alpha", "thymosin", "ta1"]),

        // GH secretagogues
        .init(canonical: "Ipamorelin",       category: .ghSecretagogue, aliases: ["ipa", "ipamorelan"]),
        .init(canonical: "CJC-1295",         category: .ghSecretagogue, aliases: ["cjc", "c j c", "cjc 1295", "cjc1295"]),
        .init(canonical: "Sermorelin",       category: .ghSecretagogue, aliases: ["sermorlin"]),
        .init(canonical: "Tesamorelin",      category: .ghSecretagogue, aliases: ["tesa", "tesamorelan"]),
        .init(canonical: "GHRP-2",           category: .ghSecretagogue, aliases: ["ghrp 2", "ghrp two", "ghrp2"]),
        .init(canonical: "GHRP-6",           category: .ghSecretagogue, aliases: ["ghrp 6", "ghrp six", "ghrp6"]),
        .init(canonical: "Hexarelin",        category: .ghSecretagogue, aliases: ["hex"]),
        .init(canonical: "MK-677",           category: .ghSecretagogue, aliases: ["mk", "m k", "mk 677", "ibutamoren"]),

        // Metabolic / fat loss
        .init(canonical: "Tirzepatide",      category: .fatLoss, aliases: ["tirz", "mounjaro", "zepbound"]),
        .init(canonical: "Semaglutide",      category: .fatLoss, aliases: ["sema", "ozempic", "wegovy", "rybelsus"]),
        .init(canonical: "AOD-9604",         category: .fatLoss, aliases: ["aod", "a o d", "aod9604"]),
        .init(canonical: "Retatrutide",      category: .fatLoss, aliases: ["reta"]),

        // Other / cognitive / sexual
        .init(canonical: "PT-141",           category: .other, aliases: ["pt", "p t", "pt 141", "bremelanotide"]),
        .init(canonical: "Melanotan II",     category: .other, aliases: ["melanotan", "mt2", "mt 2", "tan peptide"]),
        .init(canonical: "Selank",           category: .other, aliases: []),
        .init(canonical: "Semax",            category: .other, aliases: []),
        .init(canonical: "Epithalon",        category: .other, aliases: ["epitalon"]),
        .init(canonical: "DSIP",             category: .other, aliases: ["d s i p"]),
        .init(canonical: "KPV",              category: .other, aliases: ["k p v"]),
        .init(canonical: "LL-37",            category: .other, aliases: ["l l 37"]),
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

    static func match(in text: String) -> [String] {
        let haystack = normalize(text)
        guard !haystack.isEmpty else { return [] }
        var hits: [String] = []
        for entry in all {
            let candidates = [entry.canonical] + entry.aliases
            for c in candidates {
                let needle = normalize(c)
                guard !needle.isEmpty else { continue }
                if haystack.range(of: "\\b\(NSRegularExpression.escapedPattern(for: needle))\\b",
                                  options: .regularExpression) != nil {
                    hits.append(entry.canonical)
                    break
                }
            }
        }
        return hits
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left", "thigh-subq-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "glute-im-left", "glute-im-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"]
        ),

        // ── GH secretagogues ───────────────────────────────────────────────

        Compound(
            name: "Ipamorelin",
            slug: "ipamorelin",
            halfLifeHrs: 2,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 300,
            benefits: ["GH release", "Improved sleep quality", "Lean muscle support", "Fat loss"],
            sideEffects: ["Mild hunger increase", "Water retention", "Headache"],
            stackingNotes: "Commonly stacked with CJC-1295 for amplified GH pulse.",
            fdaStatus: .research,
            summaryMd: "Ipamorelin is a selective ghrelin mimetic that stimulates GH without significantly affecting cortisol or prolactin.",
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left", "thigh-subq-right"]
        ),

        Compound(
            name: "CJC-1295",
            slug: "cjc-1295",
            halfLifeHrs: 168,
            dosingRangeLowMcg: 100,
            dosingRangeHighMcg: 200,
            benefits: ["Sustained GH elevation", "Improved recovery", "Increased IGF-1"],
            sideEffects: ["Water retention", "Fatigue", "Injection site reaction"],
            stackingNotes: "Pairs with Ipamorelin for amplified GH pulses.",
            fdaStatus: .research,
            summaryMd: "CJC-1295 (with DAC) is a long-acting GHRH analogue. The DAC complex extends half-life to ~7 days.",
            goalCategories: ["growth", "recovery"],
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"]
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
            recommendedSiteIds: []
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left", "thigh-subq-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right", "thigh-subq-left", "thigh-subq-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "abdomen-subq-right"]
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
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left", "thigh-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left"]
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
            recommendedSiteIds: ["abdomen-subq-left"]
        ),
    ]

    static func compound(named name: String) -> Compound? {
        allCompoundsSeed.first { $0.name == name || $0.slug == name }
    }

    // Compounds tagged with at least one of the given goal IDs.
    static func compoundsForGoals(_ goalIds: [String]) -> [Compound] {
        let goals = Set(goalIds)
        return allCompoundsSeed.filter { c in
            !c.goalCategories.allSatisfy { !goals.contains($0) }
        }
    }
}
