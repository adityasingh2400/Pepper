import Foundation
import CoreGraphics

// Anatomical injection site. Coordinates are normalized 0..1 over the body image.
struct PinSite: Codable, Identifiable, Hashable {
    let id: String
    let region: Region
    let side: Side?
    let route: Route
    let displayName: String
    let bodyView: BodyView
    let hotspotX: Double
    let hotspotY: Double
    let techniqueMd: String
    let rotationAdvice: String?
    let pinchRequired: Bool
    let needleGauge: String?
    let needleLength: String?

    var hotspot: CGPoint { CGPoint(x: hotspotX, y: hotspotY) }

    enum Region: String, Codable, Hashable, CaseIterable {
        case abdomen, thigh, deltoid, glute, tricep, calf
    }

    enum Side: String, Codable, Hashable, CaseIterable {
        case left, right
    }

    enum Route: String, Codable, Hashable, CaseIterable {
        case subq, im

        var label: String {
            switch self {
            case .subq: return "Subcutaneous"
            case .im:   return "Intramuscular"
            }
        }
    }

    enum BodyView: String, Codable, Hashable, CaseIterable {
        case front, back
    }
}

// Recommendation linking a compound to a pin site, with a preference rank.
struct CompoundPinRecommendation: Codable, Hashable {
    let pinSiteId: String
    let preference: Int    // 0 = primary, 1 = secondary, 2 = avoid
    let rationale: String?

    var isPrimary: Bool { preference == 0 }
}

// MARK: - Bundled catalog of pin sites
// All anatomical coordinates are normalized to a body image rendered with the
// torso centered and arms relaxed at the sides. Front view = facing camera.

enum PinSiteCatalog {
    static let all: [PinSite] = [
        // Abdomen subq — favorite for GLP-1s, BPC, growth peptides
        .init(
            id: "abdomen-subq-left",
            region: .abdomen, side: .left, route: .subq,
            displayName: "Lower abdomen (left)",
            bodyView: .front, hotspotX: 0.42, hotspotY: 0.46,
            techniqueMd: """
            **Subcutaneous — abdomen**

            1. Wash hands and clean a 2-inch circle 1–2 inches left of the navel with alcohol.
            2. Pinch a fold of skin between thumb and index finger.
            3. Insert needle at 90° (45° if you are very lean).
            4. Push plunger slowly. Hold for 5 seconds before withdrawing.
            5. Press a fresh swab on the site for 10 seconds. No massage.
            """,
            rotationAdvice: "Stay 1 inch away from the navel. Rotate at least 1 inch from the previous site each session.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in"
        ),
        .init(
            id: "abdomen-subq-right",
            region: .abdomen, side: .right, route: .subq,
            displayName: "Lower abdomen (right)",
            bodyView: .front, hotspotX: 0.58, hotspotY: 0.46,
            techniqueMd: """
            **Subcutaneous — abdomen**

            1. Wash hands and clean a 2-inch circle 1–2 inches right of the navel with alcohol.
            2. Pinch a fold of skin between thumb and index finger.
            3. Insert needle at 90° (45° if very lean).
            4. Push plunger slowly. Hold for 5 seconds before withdrawing.
            5. Press a fresh swab on the site for 10 seconds. No massage.
            """,
            rotationAdvice: "Stay 1 inch away from the navel. Rotate at least 1 inch from the previous site each session.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in"
        ),
        // Thigh subq — comfortable, good for early users
        .init(
            id: "thigh-subq-left",
            region: .thigh, side: .left, route: .subq,
            displayName: "Outer thigh (left)",
            bodyView: .front, hotspotX: 0.40, hotspotY: 0.66,
            techniqueMd: """
            **Subcutaneous — thigh**

            1. Sit and locate the outer middle third of the thigh (handspan above the knee, handspan below the hip).
            2. Clean the area with alcohol.
            3. Pinch a fold of skin and insert at 90°.
            4. Push slowly, hold 5 seconds, withdraw.
            """,
            rotationAdvice: "Alternate legs every dose. Avoid the inner thigh (vasculature).",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in"
        ),
        .init(
            id: "thigh-subq-right",
            region: .thigh, side: .right, route: .subq,
            displayName: "Outer thigh (right)",
            bodyView: .front, hotspotX: 0.60, hotspotY: 0.66,
            techniqueMd: """
            **Subcutaneous — thigh**

            1. Sit and locate the outer middle third of the thigh.
            2. Clean with alcohol, pinch a fold of skin.
            3. Insert at 90°, push slowly, hold 5 s, withdraw.
            """,
            rotationAdvice: "Alternate legs every dose. Avoid the inner thigh.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in"
        ),
        // Deltoid IM — used for testosterone esters, melanotan, some GH
        .init(
            id: "deltoid-im-left",
            region: .deltoid, side: .left, route: .im,
            displayName: "Deltoid (left, IM)",
            bodyView: .front, hotspotX: 0.27, hotspotY: 0.27,
            techniqueMd: """
            **Intramuscular — deltoid**

            1. Locate the thickest part of the deltoid: 3 finger-widths below the acromion (top of the shoulder).
            2. Relax the arm at your side. Clean with alcohol.
            3. Insert needle at 90°, fully into the muscle. Aspirate by pulling back on the plunger; if blood appears, withdraw and try a new site.
            4. Inject slowly (10–15 seconds per ml). Hold 5 s, withdraw.
            """,
            rotationAdvice: "Not for volumes >1 ml. Alternate shoulders each session.",
            pinchRequired: false,
            needleGauge: "25G",
            needleLength: "1 in"
        ),
        .init(
            id: "deltoid-im-right",
            region: .deltoid, side: .right, route: .im,
            displayName: "Deltoid (right, IM)",
            bodyView: .front, hotspotX: 0.73, hotspotY: 0.27,
            techniqueMd: """
            **Intramuscular — deltoid**

            1. Locate the thickest part of the deltoid: 3 finger-widths below the acromion.
            2. Relax the arm at your side. Clean with alcohol.
            3. Insert needle at 90°, fully into the muscle. Aspirate; if blood appears, withdraw and try a new site.
            4. Inject slowly (10–15 seconds per ml). Hold 5 s, withdraw.
            """,
            rotationAdvice: "Not for volumes >1 ml. Alternate shoulders each session.",
            pinchRequired: false,
            needleGauge: "25G",
            needleLength: "1 in"
        ),
        // Glute IM — preferred for larger IM volumes
        .init(
            id: "glute-im-left",
            region: .glute, side: .left, route: .im,
            displayName: "Upper outer glute (left, IM)",
            bodyView: .back, hotspotX: 0.36, hotspotY: 0.50,
            techniqueMd: """
            **Intramuscular — ventrogluteal / upper-outer quadrant**

            1. Imagine dividing one buttock into 4 quadrants. Inject only into the **upper outer** quadrant — this avoids the sciatic nerve.
            2. Clean with alcohol.
            3. Insert at 90° fully into the muscle. Aspirate; if blood appears, withdraw and choose a new site.
            4. Inject slowly. Hold 5 s, withdraw.
            """,
            rotationAdvice: "Best for volumes 1–3 ml. Alternate sides each session.",
            pinchRequired: false,
            needleGauge: "23G",
            needleLength: "1.5 in"
        ),
        .init(
            id: "glute-im-right",
            region: .glute, side: .right, route: .im,
            displayName: "Upper outer glute (right, IM)",
            bodyView: .back, hotspotX: 0.64, hotspotY: 0.50,
            techniqueMd: """
            **Intramuscular — upper-outer quadrant**

            1. Inject only into the **upper outer** quadrant.
            2. Clean with alcohol.
            3. Insert at 90°, aspirate, inject slowly, hold 5 s.
            """,
            rotationAdvice: "Best for volumes 1–3 ml. Alternate sides each session.",
            pinchRequired: false,
            needleGauge: "23G",
            needleLength: "1.5 in"
        ),
        // Tricep subq — useful for lean users, less common
        .init(
            id: "tricep-subq-left",
            region: .tricep, side: .left, route: .subq,
            displayName: "Back of upper arm (left)",
            bodyView: .back, hotspotX: 0.27, hotspotY: 0.30,
            techniqueMd: """
            **Subcutaneous — back of arm**

            1. Sit. Locate the loose skin behind the upper arm, between the shoulder and elbow.
            2. Have a partner pinch a fold (or use your other arm if dexterous).
            3. Insert at 90°, push slowly, hold 5 s.
            """,
            rotationAdvice: "Switch arms each session.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in"
        ),
        .init(
            id: "tricep-subq-right",
            region: .tricep, side: .right, route: .subq,
            displayName: "Back of upper arm (right)",
            bodyView: .back, hotspotX: 0.73, hotspotY: 0.30,
            techniqueMd: """
            **Subcutaneous — back of arm**

            1. Sit. Locate the loose skin behind the upper arm, between the shoulder and elbow.
            2. Pinch a fold of skin.
            3. Insert at 90°, push slowly, hold 5 s.
            """,
            rotationAdvice: "Switch arms each session.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in"
        ),
    ]

    static func find(_ id: String) -> PinSite? {
        all.first(where: { $0.id == id })
    }

    static func sites(for ids: [String]) -> [PinSite] {
        ids.compactMap { find($0) }
    }
}
