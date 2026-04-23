import Foundation

// Goal categories shown on the new onboarding multi-select.
// Mirrored from Supabase `goal_categories`; this static list is the offline fallback.
struct GoalCategory: Codable, Identifiable, Hashable {
    let id: String
    let display: String
    let description: String
    let icon: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, display, description, icon
        case sortOrder = "sort_order"
    }
}

enum GoalCategoryCatalog {
    static let all: [GoalCategory] = [
        .init(id: "recovery",  display: "Recovery & Healing",   description: "Tendons, joints, gut, post-injury repair",     icon: "bandage.fill",                  sortOrder: 1),
        .init(id: "growth",    display: "Muscle & Growth",      description: "GH pulse, lean mass, IGF-1",                   icon: "figure.strengthtraining.traditional", sortOrder: 2),
        .init(id: "fat_loss",  display: "Fat Loss",             description: "Appetite, GLP-1, lipolysis",                   icon: "flame.fill",                    sortOrder: 3),
        .init(id: "longevity", display: "Longevity",            description: "Cellular health, mitochondrial, telomere",     icon: "leaf.fill",                     sortOrder: 4),
        .init(id: "cognitive", display: "Cognitive",            description: "Focus, memory, mood, neuroprotection",         icon: "brain.head.profile",            sortOrder: 5),
        .init(id: "libido",    display: "Libido & Performance", description: "Sexual function, energy",                      icon: "flame.circle.fill",             sortOrder: 6),
        .init(id: "skin_hair", display: "Skin & Hair",          description: "Collagen, copper peptides, regeneration",      icon: "sparkles",                      sortOrder: 7),
        .init(id: "immune",    display: "Immune Support",       description: "Antimicrobial, immune modulation",             icon: "shield.lefthalf.filled",        sortOrder: 8),
        .init(id: "sleep",     display: "Sleep",                description: "Deep sleep, GH pulse, recovery",               icon: "moon.stars.fill",               sortOrder: 9),
    ]

    static func find(_ id: String) -> GoalCategory? {
        all.first(where: { $0.id == id })
    }

    static func sorted(_ ids: [String]) -> [GoalCategory] {
        ids.compactMap(find).sorted { $0.sortOrder < $1.sortOrder }
    }
}
