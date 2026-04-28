import SwiftUI

struct ResearchListView: View {
    @EnvironmentObject private var nav: NavigationCoordinator
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            EmbeddedResearchView()
                .navigationTitle("Research")
                .navigationDestination(for: ResearchFamily.self) { family in
                    // Family list reads compounds from the parent via a
                    // lightweight proxy so voice-driven deep-links can push
                    // it without threading the full compound list through.
                    ResearchFamilyRouteView(family: family)
                }
                .navigationDestination(for: Compound.self) { compound in
                    CompoundDetailView(compound: compound)
                        .onAppear {
                            Analytics.capture(.compoundViewed, properties: ["compound": compound.name])
                        }
                }
        }
        .onChange(of: nav.researchWalkthrough?.stage) { _, newStage in
            guard let walk = nav.researchWalkthrough else {
                // Walkthrough cleared — pop back to the hub on next tap.
                return
            }
            switch newStage {
            case .familyHub, .none:
                // Start fresh at the hub if we're not already there.
                if !path.isEmpty { path.removeLast(path.count) }
            case .familyList:
                if path.isEmpty { path.append(walk.primaryFamily) }
            case .detail:
                // Ensure both family + detail are on the stack so Back still
                // returns to the umbrella, matching what the user *saw*.
                if path.isEmpty { path.append(walk.primaryFamily) }
                path.append(walk.compound)
            }
        }
        .onChange(of: nav.researchPushedCompound) { _, newValue in
            // Legacy hook: anything outside the voice walkthrough (e.g. a
            // Pepper tool call) that sets `researchPushedCompound` directly
            // still works — push the detail on top of whatever's there.
            // We don't dedupe: NavigationPath doesn't expose its elements,
            // and re-pushing an identical Hashable value is a no-op in
            // practice since the back button on the existing screen pops
            // first. In testing this hasn't caused stack bloat.
            guard let c = newValue, nav.researchWalkthrough == nil else { return }
            path.append(c)
        }
    }
}

/// Thin wrapper that re-fetches the family's compound list for the family
/// route destination. Keeps the heavy `EmbeddedResearchView` state out of
/// the navigation stack path.
struct ResearchFamilyRouteView: View {
    let family: ResearchFamily
    @State private var compounds: [Compound] = []

    var body: some View {
        ResearchFamilyView(family: family, compounds: compounds)
            .task {
                if compounds.isEmpty {
                    compounds = CompoundCatalog.allCompoundsSeed.filter {
                        ResearchFamily.families(for: $0).contains(family)
                    }
                }
            }
    }
}

// MARK: - Research category (family grouping)
//
// Compounds in the catalog carry free-form `goal_categories` tags (e.g.
// "skin_hair", "cognitive"). We roll those up into a small set of curated
// families the user can actually navigate. A compound with multiple tags
// appears in every relevant family — GHK-Cu shows up under both Skin & Hair
// AND Healing, which matches how people actually think about it.
enum ResearchFamily: String, CaseIterable, Identifiable {
    case healing      // recovery, immune, wound/gut repair
    case skin         // skin_hair, pigment, collagen
    case growth       // GH / IGF-1 / performance
    case metabolic    // fat loss, GLP-1s, lipolysis
    case cognitive    // nootropics, focus, BDNF
    case sleep        // sleep architecture, circadian
    case longevity    // mitochondrial, telomere
    case libido       // sexual health
    case other        // uncategorized fallback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .healing:   return "Healing & Recovery"
        case .skin:      return "Skin, Hair & Pigment"
        case .growth:    return "Growth & Performance"
        case .metabolic: return "Metabolic & Fat Loss"
        case .cognitive: return "Cognitive & Nootropic"
        case .sleep:     return "Sleep & Circadian"
        case .longevity: return "Longevity & Mitochondrial"
        case .libido:    return "Libido & Sexual"
        case .other:     return "Other Compounds"
        }
    }

    /// One-line positioning — shown small under the title on each card.
    var subtitle: String {
        switch self {
        case .healing:   return "Tendons, gut, immune, tissue repair"
        case .skin:      return "Collagen, hair growth, pigmentation"
        case .growth:    return "GH secretagogues and IGF-1"
        case .metabolic: return "GLP-1, lipolysis, body composition"
        case .cognitive: return "Focus, memory, anxiolysis, BDNF"
        case .sleep:     return "Deep sleep and circadian rhythm"
        case .longevity: return "Mitochondria, telomeres, aging"
        case .libido:    return "Desire, arousal, sexual function"
        case .other:     return "Uncategorized research peptides"
        }
    }

    /// SF Symbol that reads as the "sign" for the family at a glance.
    var symbol: String {
        switch self {
        case .healing:   return "cross.case.fill"
        case .skin:      return "sparkles"
        case .growth:    return "figure.strengthtraining.traditional"
        case .metabolic: return "flame.fill"
        case .cognitive: return "brain.head.profile"
        case .sleep:     return "moon.stars.fill"
        case .longevity: return "infinity"
        case .libido:    return "heart.fill"
        case .other:     return "flask.fill"
        }
    }

    /// Maps raw `goal_categories` tags off each compound into a family.
    /// Returns `nil` for tags we don't recognize so they fall through to
    /// the name-based override or `.other` via `families(for:)` below.
    static func from(goalTag tag: String) -> ResearchFamily? {
        switch tag {
        case "recovery", "immune":       return .healing
        case "skin_hair":                return .skin
        case "growth":                   return .growth
        case "fat_loss":                 return .metabolic
        case "cognitive":                return .cognitive
        case "sleep":                    return .sleep
        case "longevity":                return .longevity
        case "libido":                   return .libido
        default:                         return nil
        }
    }

    /// Hand-curated fallback families for every compound in the starter
    /// catalog. Used when the DB row has empty `goal_categories` (e.g. older
    /// Supabase rows that predate the v2 metadata seed) and when the seed
    /// catalog lookup misses. Lowercased name keys so voice-captured
    /// variations still resolve.
    ///
    /// Sources: compound_metadata.yaml (authoritative) + pharmacology notes
    /// for the handful of compounds that aren't in the YAML yet (MOTS-c).
    private static let nameOverrides: [String: [ResearchFamily]] = [
        // Healing & recovery
        "bpc-157":          [.healing, .skin],
        "tb-500":           [.healing],
        "ghk-cu":           [.skin, .healing, .longevity],
        "thymosin alpha-1": [.healing],
        "kpv":              [.healing, .skin],
        "ll-37":            [.healing],

        // Growth / GH secretagogues
        "ipamorelin":       [.growth, .sleep, .healing],
        "cjc-1295":         [.growth, .healing],
        "sermorelin":       [.growth, .sleep, .healing],
        "tesamorelin":      [.metabolic, .growth, .cognitive],
        "ghrp-2":           [.growth],
        "ghrp-6":           [.growth],
        "hexarelin":        [.growth, .longevity],
        "mk-677":           [.growth, .sleep],

        // Metabolic / fat loss
        "tirzepatide":      [.metabolic],
        "semaglutide":      [.metabolic],
        "aod-9604":         [.metabolic, .healing],
        "retatrutide":      [.metabolic],

        // Libido / sexual
        "pt-141":           [.libido],
        "melanotan ii":     [.skin, .libido],

        // Cognitive / nootropic
        "selank":           [.cognitive],
        "semax":            [.cognitive],

        // Longevity / mitochondrial
        "mots-c":           [.longevity, .metabolic, .growth],
        "epithalon":        [.longevity, .sleep],

        // Sleep
        "dsip":             [.sleep],
    ]

    /// Every family a compound belongs in, with three-tier fallback:
    ///   1. Whatever `goal_categories` came back from Supabase (if non-empty)
    ///   2. The canonical Swift catalog seed's `goalCategories` for that name
    ///   3. A hand-curated name override (covers every starter compound)
    /// Only truly unknown compounds land in `.other`.
    static func families(for compound: Compound) -> [ResearchFamily] {
        // Tier 1: DB row.
        let primary = compound.goalCategories.compactMap { from(goalTag: $0) }
        if !primary.isEmpty {
            return Array(Set(primary))
        }

        // Tier 2: canonical seed lookup by name or slug (DB row may be stale).
        if let seed = CompoundCatalog.allCompoundsSeed.first(where: {
            $0.name.caseInsensitiveCompare(compound.name) == .orderedSame ||
            $0.slug.caseInsensitiveCompare(compound.slug) == .orderedSame
        }) {
            let seeded = seed.goalCategories.compactMap { from(goalTag: $0) }
            if !seeded.isEmpty {
                return Array(Set(seeded))
            }
        }

        // Tier 3: hand-curated name override.
        let key = compound.name.lowercased()
        if let override = nameOverrides[key] {
            return override
        }
        // Try slug too in case names drift (e.g. "Melanotan II" vs slug).
        if let override = nameOverrides[compound.slug.lowercased()] {
            return override
        }

        return [.other]
    }

    /// Display order for the hub grid — more common families first.
    static let displayOrder: [ResearchFamily] = [
        .healing, .skin, .growth, .metabolic,
        .cognitive, .sleep, .longevity, .libido, .other
    ]
}

struct EmbeddedResearchView: View {
    @State private var compounds: [Compound] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    /// Compounds filtered by the search bar — used only when the user is
    /// actively searching. An empty query collapses back to the family hub.
    private var searchResults: [Compound] {
        guard !searchText.isEmpty else { return [] }
        let filtered = compounds.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.benefits.joined().localizedCaseInsensitiveContains(searchText)
        }
        // Rank-first sort so "tirz" surfaces Tirzepatide (#1) above unranked
        // hits like "tirzepatide analogue".
        return filtered.sorted { a, b in
            switch (a.popularityRank, b.popularityRank) {
            case let (ra?, rb?): return ra < rb
            case (_?, nil):      return true
            case (nil, _?):      return false
            default:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        }
    }

    /// Families that actually have at least one compound, in display order.
    private var populatedFamilies: [(family: ResearchFamily, compounds: [Compound])] {
        var byFamily: [ResearchFamily: [Compound]] = [:]
        for c in compounds {
            for fam in ResearchFamily.families(for: c) {
                byFamily[fam, default: []].append(c)
            }
        }
        return ResearchFamily.displayOrder.compactMap { fam in
            guard let list = byFamily[fam], !list.isEmpty else { return nil }
            // Rank: prefer lower popularityRank (1 = most popular), then name.
            // Unranked compounds sort to the end in alphabetical order.
            let sorted = list.sorted { a, b in
                switch (a.popularityRank, b.popularityRank) {
                case let (ra?, rb?): return ra < rb
                case (_?, nil):      return true
                case (nil, _?):      return false
                default:
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
            }
            return (fam, sorted)
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Text("Couldn't load compounds")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color.appTextTertiary)
                    Button("Retry") { Task { await load() } }
                        .foregroundColor(Color.appAccent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
            } else if !searchText.isEmpty {
                searchResultsView
            } else {
                familyHubView
            }
        }
        .navigationTitle("Research")
        .searchable(text: $searchText, prompt: "Search compounds")
        .task { await load() }
    }

    // MARK: Hub (curated family cards)

    private var familyHubView: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(populatedFamilies, id: \.family.id) { entry in
                    NavigationLink(value: entry.family) {
                        ResearchFamilyCard(
                            family: entry.family,
                            compoundCount: entry.compounds.count
                        )
                        .pepperAnchor(ResearchSpotlight.family(entry.family))
                    }
                    .buttonStyle(.plain)
                }
                // Bottom inset so the floating mic + Pepper bubble never
                // obscures the last family card.
                Color.clear.frame(height: 96)
            }
            .padding(16)
        }
        .background(Color.appBackground)
    }

    // MARK: Search (flat list across all families)

    @ViewBuilder
    private var searchResultsView: some View {
        if searchResults.isEmpty {
            VStack(spacing: 8) {
                Text("No results for \"\(searchText)\"")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)
                Text("Try a different compound name or benefit.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.appTextTertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(searchResults) { compound in
                        NavigationLink(value: compound) {
                            CompoundRowView(compound: compound)
                        }
                        .buttonStyle(.plain)
                    }
                    Color.clear.frame(height: 96)
                }
                .padding(16)
            }
            .background(Color.appBackground)
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let result: [Compound] = try await Task.detached {
                try await supabase
                    .from("compounds")
                    .select()
                    .order("name")
                    .execute()
                    .value
            }.value
            compounds = mergeWithLocalSeed(dbResults: result)
        } catch {
            // Fall back to the full local seed so the Research tab still
            // works offline or when Supabase is unreachable / not seeded.
            errorMessage = nil
            compounds = CompoundCatalog.allCompoundsSeed
        }
        isLoading = false
    }

    /// Merges Supabase results with the local 60-compound catalog. DB rows
    /// win on matching name/slug (so metadata can be hot-fixed server-side
    /// without an app update), but any field the DB row is missing (e.g. a
    /// legacy row with no `popularity_rank` or empty `goal_categories`) is
    /// backfilled from the canonical seed. Compounds missing from the DB
    /// are appended so the hub always shows the full 60-compound catalog.
    private func mergeWithLocalSeed(dbResults: [Compound]) -> [Compound] {
        let seedByKey: [String: Compound] = {
            var map: [String: Compound] = [:]
            for s in CompoundCatalog.allCompoundsSeed {
                map[s.name.lowercased()] = s
                map[s.slug.lowercased()] = s
            }
            return map
        }()

        var merged: [Compound] = dbResults.map { db in
            guard let seed = seedByKey[db.name.lowercased()]
                   ?? seedByKey[db.slug.lowercased()] else { return db }
            // DB metadata wins where non-empty; seed backfills where it isn't.
            return Compound(
                id: db.id,
                name: db.name,
                slug: db.slug,
                halfLifeHrs: db.halfLifeHrs ?? seed.halfLifeHrs,
                dosingRangeLowMcg: db.dosingRangeLowMcg ?? seed.dosingRangeLowMcg,
                dosingRangeHighMcg: db.dosingRangeHighMcg ?? seed.dosingRangeHighMcg,
                benefits: db.benefits.isEmpty ? seed.benefits : db.benefits,
                sideEffects: db.sideEffects.isEmpty ? seed.sideEffects : db.sideEffects,
                stackingNotes: db.stackingNotes ?? seed.stackingNotes,
                fdaStatus: db.fdaStatus,
                summaryMd: db.summaryMd ?? seed.summaryMd,
                goalCategories: db.goalCategories.isEmpty ? seed.goalCategories : db.goalCategories,
                administrationRoutes: db.administrationRoutes.isEmpty ? seed.administrationRoutes : db.administrationRoutes,
                timeToEffectHours: db.timeToEffectHours ?? seed.timeToEffectHours,
                peakEffectHours: db.peakEffectHours ?? seed.peakEffectHours,
                durationHours: db.durationHours ?? seed.durationHours,
                dosingFormula: db.dosingFormula ?? seed.dosingFormula,
                dosingUnit: db.dosingUnit ?? seed.dosingUnit,
                dosingFrequency: db.dosingFrequency ?? seed.dosingFrequency,
                bacWaterMlDefault: db.bacWaterMlDefault ?? seed.bacWaterMlDefault,
                storageTemp: db.storageTemp ?? seed.storageTemp,
                storageMaxDays: db.storageMaxDays ?? seed.storageMaxDays,
                needleGaugeDefault: db.needleGaugeDefault ?? seed.needleGaugeDefault,
                needleLengthDefault: db.needleLengthDefault ?? seed.needleLengthDefault,
                recommendedSiteIds: db.recommendedSiteIds.isEmpty ? seed.recommendedSiteIds : db.recommendedSiteIds,
                popularityRank: db.popularityRank ?? seed.popularityRank,
                effectsTimeline: db.effectsTimeline ?? seed.effectsTimeline,
                mechanism: db.mechanism ?? seed.mechanism,
                risks: db.risks ?? seed.risks,
                mitigations: db.mitigations ?? seed.mitigations
            )
        }

        let existingKeys = Set(merged.flatMap { [$0.name.lowercased(), $0.slug.lowercased()] })
        for seed in CompoundCatalog.allCompoundsSeed {
            let seedKeys = [seed.name.lowercased(), seed.slug.lowercased()]
            if seedKeys.contains(where: existingKeys.contains) { continue }
            merged.append(seed)
        }
        return merged
    }
}

// MARK: - Curated family card
//
// Rich wine-cream treatment: deep maroon gradient base, soft cream emblem
// seal holding the family's SF Symbol, cream title + subtitle + count.
// Matte, thick-feeling, not neon — matches the app's warm cream/maroon
// palette without shouting.
struct ResearchFamilyCard: View {
    let family: ResearchFamily
    let compoundCount: Int

    // Deep wine gradient — darker than the app's accent maroon (#9f1239) so
    // the cream emblem reads as the focal point rather than competing.
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "5a1528"), Color(hex: "3d0d1a")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Cream emblem fill — matches appBackground in light mode for a baked-in
    // feel (no jarring pure-white highlight on a dark card).
    private var emblemFill: Color { Color(hex: "f5ead9") }
    private var emblemStroke: Color { Color(hex: "c9a67a").opacity(0.55) }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(emblemFill)
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(emblemStroke, lineWidth: 1)
                    .frame(width: 56, height: 56)
                Image(systemName: family.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "5a1528"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(family.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "f5ead9"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(family.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "e8d5bc").opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(compoundCount) compound\(compoundCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "1c0a10"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: "e8d5bc").opacity(0.9)))
                    .padding(.top, 2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "e8d5bc").opacity(0.7))
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .background(gradient)
        .overlay(
            // Subtle cream rim — the "thick" feel the user asked for.
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: "c9a67a").opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: Color(hex: "3d0d1a").opacity(0.25), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Family drill-down
//
// Presents just the compounds in one family, with a compact contextual
// header so the user knows where they are after tapping a card.
struct ResearchFamilyView: View {
    let family: ResearchFamily
    let compounds: [Compound]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ResearchFamilyHeader(family: family, compoundCount: compounds.count)
                    .padding(.bottom, 4)

                ForEach(compounds) { compound in
                    NavigationLink(value: compound) {
                        CompoundRowView(compound: compound)
                            .pepperAnchor(ResearchSpotlight.compoundRow(compound))
                    }
                    .buttonStyle(.plain)
                }
                Color.clear.frame(height: 96)
            }
            .padding(16)
        }
        .background(Color.appBackground)
        .navigationTitle(family.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ResearchFamilyHeader: View {
    let family: ResearchFamily
    let compoundCount: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appAccentTint)
                    .frame(width: 40, height: 40)
                Image(systemName: family.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(family.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Color.appTextSecondary)
                Text("\(compoundCount) compound\(compoundCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appTextMeta)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct CompoundRowView: View {
    let compound: Compound

    private var pkSummary: String? {
        if let dur = compound.durationHours {
            return "Active \(PeptideTimeline.formatHours(dur))"
        }
        if let h = compound.halfLifeHrs {
            return "T½ \(PeptideTimeline.formatHours(h))"
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(compound.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                    FDABadge(status: compound.fdaStatus)
                }
                Text(compound.benefits.prefix(2).joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextTertiary)
                    .lineLimit(1)
                if let pk = pkSummary {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 9, weight: .bold))
                        Text(pk)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color.appAccent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.appAccentTint))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.appTextMeta)
        }
        .padding(14)
        .background(Color.appCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
    }
}

struct CompoundDetailView: View {
    let compound: Compound
    @State private var showDosingCalculator = false
    @State private var showPinningProtocol  = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(compound.name)
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(Color.appTextPrimary)
                        Spacer()
                        FDABadge(status: compound.fdaStatus)
                    }
                    if let summary = compound.summaryMd {
                        Text(summary)
                            .font(.system(size: 14))
                            .foregroundColor(Color.appTextSecondary)
                            .lineSpacing(4)
                    }
                    HStack(spacing: 8) {
                        if let low = compound.dosingRangeLowMcg, let high = compound.dosingRangeHighMcg {
                            metaPill(systemImage: "syringe", text: "\(Int(low))–\(Int(high)) mcg")
                        }
                        if let freq = compound.dosingFrequency {
                            metaPill(systemImage: "calendar", text: freq.capitalized)
                        }
                        if let temp = compound.storageTemp {
                            metaPill(systemImage: "thermometer", text: temp.capitalized)
                        }
                    }
                }
                .padding(16)
                .background(Color.appCard)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))

                // Pharmacokinetic timeline
                if compound.timeline.hasAnyData {
                    PeptideTimelineView(timeline: compound.timeline, mode: .expanded)
                }

                // Action row: dosing calc + pinning protocol
                HStack(spacing: 10) {
                    actionTile(
                        title: "Dosing\nCalculator",
                        systemImage: "function",
                        accent: Color.appAccent
                    ) {
                        showDosingCalculator = true
                    }
                    .pepperAnchor("compound.action.dosing")
                    actionTile(
                        title: "Pinning\nProtocol",
                        systemImage: "drop.triangle.fill",
                        accent: Color(hex: "0f766e")
                    ) {
                        showPinningProtocol = true
                    }
                    .pepperAnchor("compound.action.pinning")
                }

                // Four curated wine-cream research nodes — the canonical
                // structure for every compound in the catalog:
                //   1. Effects (daily life + timeline)
                //   2. Mechanism (biology / pathways / what it inhibits)
                //   3. Risks (what can actually go wrong)
                //   4. Risk Mitigations (concrete, actionable pairings)
                ResearchNodeCard(
                    node: .effects,
                    content: compound.effectsTimeline,
                    fallback: compound.benefits.isEmpty
                        ? nil
                        : compound.benefits.joined(separator: " · ")
                )

                ResearchNodeCard(
                    node: .mechanism,
                    content: compound.mechanism,
                    fallback: compound.summaryMd
                )
                .pepperAnchor("compound.node.mechanism")

                ResearchNodeCard(
                    node: .risks,
                    content: compound.risks,
                    fallback: compound.sideEffects.isEmpty
                        ? nil
                        : compound.sideEffects.joined(separator: " · ")
                )

                ResearchNodeCard(
                    node: .mitigations,
                    content: compound.mitigations,
                    fallback: compound.stackingNotes
                )

                Text("For educational and research purposes only. Not medical advice.")
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextMeta)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                // Bottom inset so the floating action stack
                // (mic + Pepper bubble) never obscures the last section.
                Color.clear.frame(height: 96)
            }
            .padding(16)
        }
        .background(Color.appBackground)
        .navigationTitle(compound.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDosingCalculator) {
            DosingCalculatorView(compound: compound)
        }
        .sheet(isPresented: $showPinningProtocol) {
            PinningProtocolView(compound: compound)
        }
    }

    private func metaPill(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(Color.appTextSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(Color.appInputBackground)
            )
    }

    private func actionTile(
        title: String,
        systemImage: String,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accent)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.appCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Research detail node (wine-cream card)
//
// One of four nodes shown on every compound's detail page: Effects,
// Mechanism, Risks, Risk Mitigations. Matches the hub's wine/cream
// aesthetic but inverted — cream card body, wine emblem — so the hub
// stays the star and the detail page reads as "inside" a node.
enum ResearchNodeKind: String, CaseIterable {
    case effects, mechanism, risks, mitigations

    var title: String {
        switch self {
        case .effects:     return "Effects & Timeline"
        case .mechanism:   return "How It Works"
        case .risks:       return "Risks"
        case .mitigations: return "Risk Mitigations"
        }
    }

    var symbol: String {
        switch self {
        case .effects:     return "sparkles"
        case .mechanism:   return "atom"
        case .risks:       return "exclamationmark.triangle.fill"
        case .mitigations: return "shield.lefthalf.filled"
        }
    }

    /// Empty-state copy shown until the compound's research content lands.
    var placeholder: String {
        switch self {
        case .effects:
            return "Research notes coming soon."
        case .mechanism:
            return "Mechanism-of-action notes coming soon."
        case .risks:
            return "Risk profile notes coming soon."
        case .mitigations:
            return "Risk mitigation notes coming soon."
        }
    }
}

struct ResearchNodeCard: View {
    let node: ResearchNodeKind
    /// Primary content from the compound's dedicated field (effectsTimeline
    /// / mechanism / risks / mitigations). When nil/empty, `fallback` is
    /// used — this keeps compounds we haven't deep-researched yet from
    /// showing blank cards during the rollout.
    let content: String?
    let fallback: String?

    private var resolvedBody: String {
        if let b = content?.trimmingCharacters(in: .whitespacesAndNewlines), !b.isEmpty {
            return b
        }
        if let f = fallback?.trimmingCharacters(in: .whitespacesAndNewlines), !f.isEmpty {
            return f
        }
        return node.placeholder
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "5a1528"), Color(hex: "3d0d1a")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var creamFill: Color   { Color(hex: "f5ead9") }
    private var creamStroke: Color { Color(hex: "c9a67a").opacity(0.55) }
    private var wineInk: Color     { Color(hex: "5a1528") }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: emblem + title in wine gradient strip.
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(creamFill)
                        .frame(width: 36, height: 36)
                    Circle()
                        .stroke(creamStroke, lineWidth: 1)
                        .frame(width: 36, height: 36)
                    Image(systemName: node.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(wineInk)
                }
                Text(node.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "f5ead9"))
                    .kerning(0.3)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(gradient)

            // Body — paragraph text split on " · " or "\n" into bullets
            // when the content looks like a list, otherwise one prose block.
            bodyContent
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .padding(.top, 2)
        }
        .background(Color.appCard)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "c9a67a").opacity(0.22), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: Color(hex: "3d0d1a").opacity(0.10), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private var bodyContent: some View {
        let text = resolvedBody
        let bullets = splitIntoBullets(text)
        if bullets.count >= 2 {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(.system(size: 13))
                            .foregroundColor(Color.appTextSecondary)
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } else {
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.appTextSecondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Splits "A · B · C" or "A\nB\nC" into ["A","B","C"]. Returns a
    /// single-element array when the text doesn't look like a list so
    /// the renderer falls back to prose.
    private func splitIntoBullets(_ s: String) -> [String] {
        let dotSplit = s.components(separatedBy: " · ")
        if dotSplit.count >= 2 { return dotSplit.map { $0.trimmingCharacters(in: .whitespaces) } }
        let nl = s.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if nl.count >= 2 { return nl }
        return [s]
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.appTextMeta)
                .kerning(1.2)
            content
        }
        .padding(16)
        .background(Color.appCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct FDABadge: View {
    let status: Compound.FDAStatus

    var label: String {
        switch status {
        case .approved: return "FDA Approved"
        case .grey:     return "Grey Market"
        case .research: return "Research"
        }
    }

    var color: Color {
        switch status {
        case .approved: return Color(hex: "166534")
        case .grey:     return Color(hex: "92400e")
        case .research: return Color(hex: "1e40af")
        }
    }

    var bg: Color {
        switch status {
        case .approved: return Color(hex: "dcfce7")
        case .grey:     return Color(hex: "fef3c7")
        case .research: return Color(hex: "dbeafe")
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .cornerRadius(20)
    }
}
