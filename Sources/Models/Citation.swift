import Foundation

// A single peer-reviewed source attached to a compound + topic.
// Topics: "dosing", "safety", "mechanism", "efficacy", "weight_loss",
// "recovery", "longevity", "cognitive", "libido", "skin", "preclinical".
struct Citation: Codable, Identifiable, Hashable {
    let id: UUID
    let compoundId: UUID?
    let pubmedId: String?
    let doi: String?
    let title: String
    let authors: String?
    let year: Int?
    let journal: String?
    let url: String?
    let topic: String?
    let relevance: String?
    let evidenceGrade: EvidenceGrade

    enum EvidenceGrade: String, Codable, Hashable, CaseIterable {
        case a            // RCT / meta-analysis
        case b            // cohort
        case c            // case series
        case preclinical
        case unknown

        var displayLabel: String {
            switch self {
            case .a:           return "RCT"
            case .b:           return "Cohort"
            case .c:           return "Case study"
            case .preclinical: return "Preclinical"
            case .unknown:     return "Other"
            }
        }

        var colorHex: String {
            switch self {
            case .a:           return "10b981"  // green
            case .b:           return "3b82f6"  // blue
            case .c:           return "f59e0b"  // amber
            case .preclinical: return "8b5cf6"  // violet
            case .unknown:     return "6b7280"  // gray
            }
        }
    }

    var citationLine: String {
        var parts: [String] = []
        if let authors, !authors.isEmpty {
            // Trim long author lists ("Doe J, Smith K, et al. (2020). Title.")
            let short = authors.split(separator: ",").prefix(2).joined(separator: ",")
            parts.append(authors.contains(",") ? "\(short), et al" : authors)
        }
        if let year { parts.append("(\(year))") }
        var line = parts.joined(separator: " ")
        if !line.isEmpty { line += ". " }
        line += title
        if let journal, !journal.isEmpty {
            line += ". \(journal)"
        }
        return line
    }

    enum CodingKeys: String, CodingKey {
        case id, title, authors, year, journal, url, topic, relevance
        case compoundId     = "compound_id"
        case pubmedId       = "pubmed_id"
        case doi
        case evidenceGrade  = "evidence_grade"
    }

    init(
        id: UUID = UUID(),
        compoundId: UUID? = nil,
        pubmedId: String? = nil,
        doi: String? = nil,
        title: String,
        authors: String? = nil,
        year: Int? = nil,
        journal: String? = nil,
        url: String? = nil,
        topic: String? = nil,
        relevance: String? = nil,
        evidenceGrade: EvidenceGrade = .unknown
    ) {
        self.id = id
        self.compoundId = compoundId
        self.pubmedId = pubmedId
        self.doi = doi
        self.title = title
        self.authors = authors
        self.year = year
        self.journal = journal
        self.url = url
        self.topic = topic
        self.relevance = relevance
        self.evidenceGrade = evidenceGrade
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id            = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.compoundId    = try c.decodeIfPresent(UUID.self, forKey: .compoundId)
        self.pubmedId      = try c.decodeIfPresent(String.self, forKey: .pubmedId)
        self.doi           = try c.decodeIfPresent(String.self, forKey: .doi)
        self.title         = try c.decode(String.self, forKey: .title)
        self.authors       = try c.decodeIfPresent(String.self, forKey: .authors)
        self.year          = try c.decodeIfPresent(Int.self, forKey: .year)
        self.journal       = try c.decodeIfPresent(String.self, forKey: .journal)
        self.url           = try c.decodeIfPresent(String.self, forKey: .url)
        self.topic         = try c.decodeIfPresent(String.self, forKey: .topic)
        self.relevance     = try c.decodeIfPresent(String.self, forKey: .relevance)
        let g = try c.decodeIfPresent(String.self, forKey: .evidenceGrade)?.lowercased()
        self.evidenceGrade = g.flatMap { EvidenceGrade(rawValue: $0) } ?? .unknown
    }
}
