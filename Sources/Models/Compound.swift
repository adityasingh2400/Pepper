import Foundation

// MARK: - Compound (decoder-friendly, all v2 fields optional for forward compat)

struct Compound: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let slug: String
    let halfLifeHrs: Double?
    let dosingRangeLowMcg: Double?
    let dosingRangeHighMcg: Double?
    let benefits: [String]
    let sideEffects: [String]
    let stackingNotes: String?
    let fdaStatus: FDAStatus
    let summaryMd: String?

    // v1.5 metadata
    let goalCategories: [String]
    let administrationRoutes: [String]
    let timeToEffectHours: Double?
    let peakEffectHours: Double?
    let durationHours: Double?
    let dosingFormula: String?
    let dosingUnit: String?
    let dosingFrequency: String?
    let bacWaterMlDefault: Double?
    let storageTemp: String?
    let storageMaxDays: Int?
    let needleGaugeDefault: String?
    let needleLengthDefault: String?
    let recommendedSiteIds: [String]

    enum FDAStatus: String, Codable, Hashable {
        case research, grey, approved
    }

    enum CodingKeys: String, CodingKey {
        case id, name, slug, benefits
        case halfLifeHrs        = "half_life_hrs"
        case dosingRangeLowMcg  = "dosing_range_low_mcg"
        case dosingRangeHighMcg = "dosing_range_high_mcg"
        case sideEffects        = "side_effects"
        case stackingNotes      = "stacking_notes"
        case fdaStatus          = "fda_status"
        case summaryMd          = "summary_md"
        case goalCategories     = "goal_categories"
        case administrationRoutes = "administration_routes"
        case timeToEffectHours  = "time_to_effect_hours"
        case peakEffectHours    = "peak_effect_hours"
        case durationHours      = "duration_hours"
        case dosingFormula      = "dosing_formula"
        case dosingUnit         = "dosing_unit"
        case dosingFrequency    = "dosing_frequency"
        case bacWaterMlDefault  = "bac_water_ml_default"
        case storageTemp        = "storage_temp"
        case storageMaxDays     = "storage_max_days"
        case needleGaugeDefault = "needle_gauge_default"
        case needleLengthDefault = "needle_length_default"
        case recommendedSiteIds = "recommended_site_ids"
    }

    init(
        id: UUID = UUID(),
        name: String,
        slug: String,
        halfLifeHrs: Double? = nil,
        dosingRangeLowMcg: Double? = nil,
        dosingRangeHighMcg: Double? = nil,
        benefits: [String] = [],
        sideEffects: [String] = [],
        stackingNotes: String? = nil,
        fdaStatus: FDAStatus = .research,
        summaryMd: String? = nil,
        goalCategories: [String] = [],
        administrationRoutes: [String] = ["subq"],
        timeToEffectHours: Double? = nil,
        peakEffectHours: Double? = nil,
        durationHours: Double? = nil,
        dosingFormula: String? = nil,
        dosingUnit: String? = "mcg",
        dosingFrequency: String? = "daily",
        bacWaterMlDefault: Double? = 2.0,
        storageTemp: String? = "refrigerated",
        storageMaxDays: Int? = 30,
        needleGaugeDefault: String? = "29G",
        needleLengthDefault: String? = "1/2 inch",
        recommendedSiteIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.halfLifeHrs = halfLifeHrs
        self.dosingRangeLowMcg = dosingRangeLowMcg
        self.dosingRangeHighMcg = dosingRangeHighMcg
        self.benefits = benefits
        self.sideEffects = sideEffects
        self.stackingNotes = stackingNotes
        self.fdaStatus = fdaStatus
        self.summaryMd = summaryMd
        self.goalCategories = goalCategories
        self.administrationRoutes = administrationRoutes
        self.timeToEffectHours = timeToEffectHours
        self.peakEffectHours = peakEffectHours
        self.durationHours = durationHours
        self.dosingFormula = dosingFormula
        self.dosingUnit = dosingUnit
        self.dosingFrequency = dosingFrequency
        self.bacWaterMlDefault = bacWaterMlDefault
        self.storageTemp = storageTemp
        self.storageMaxDays = storageMaxDays
        self.needleGaugeDefault = needleGaugeDefault
        self.needleLengthDefault = needleLengthDefault
        self.recommendedSiteIds = recommendedSiteIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id                   = try c.decode(UUID.self, forKey: .id)
        self.name                 = try c.decode(String.self, forKey: .name)
        self.slug                 = try c.decode(String.self, forKey: .slug)
        self.halfLifeHrs          = try c.decodeIfPresent(Double.self, forKey: .halfLifeHrs)
        self.dosingRangeLowMcg    = try c.decodeIfPresent(Double.self, forKey: .dosingRangeLowMcg)
        self.dosingRangeHighMcg   = try c.decodeIfPresent(Double.self, forKey: .dosingRangeHighMcg)
        self.benefits             = (try? c.decode([String].self, forKey: .benefits)) ?? []
        self.sideEffects          = (try? c.decode([String].self, forKey: .sideEffects)) ?? []
        self.stackingNotes        = try c.decodeIfPresent(String.self, forKey: .stackingNotes)
        self.fdaStatus            = (try? c.decode(FDAStatus.self, forKey: .fdaStatus)) ?? .research
        self.summaryMd            = try c.decodeIfPresent(String.self, forKey: .summaryMd)
        self.goalCategories       = (try? c.decode([String].self, forKey: .goalCategories)) ?? []
        self.administrationRoutes = (try? c.decode([String].self, forKey: .administrationRoutes)) ?? ["subq"]
        self.timeToEffectHours    = try c.decodeIfPresent(Double.self, forKey: .timeToEffectHours)
        self.peakEffectHours      = try c.decodeIfPresent(Double.self, forKey: .peakEffectHours)
        self.durationHours        = try c.decodeIfPresent(Double.self, forKey: .durationHours)
        self.dosingFormula        = try c.decodeIfPresent(String.self, forKey: .dosingFormula)
        self.dosingUnit           = try c.decodeIfPresent(String.self, forKey: .dosingUnit) ?? "mcg"
        self.dosingFrequency      = try c.decodeIfPresent(String.self, forKey: .dosingFrequency) ?? "daily"
        self.bacWaterMlDefault    = try c.decodeIfPresent(Double.self, forKey: .bacWaterMlDefault) ?? 2.0
        self.storageTemp          = try c.decodeIfPresent(String.self, forKey: .storageTemp) ?? "refrigerated"
        self.storageMaxDays       = try c.decodeIfPresent(Int.self, forKey: .storageMaxDays) ?? 30
        self.needleGaugeDefault   = try c.decodeIfPresent(String.self, forKey: .needleGaugeDefault) ?? "29G"
        self.needleLengthDefault  = try c.decodeIfPresent(String.self, forKey: .needleLengthDefault) ?? "1/2 inch"
        self.recommendedSiteIds   = (try? c.decode([String].self, forKey: .recommendedSiteIds)) ?? []
    }
}

// MARK: - Hand-curated catalog (offline source of truth, mirrored to Supabase)

extension Compound {
    static let seedData: [Compound] = CompoundCatalog.allCompoundsSeed
}
