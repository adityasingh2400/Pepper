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
    /// Maps to a bucket of instructional videos in Supabase Storage —
    /// e.g. `subq-abdomen` -> `videos/subq-abdomen.mp4`. Multiple
    /// PinSites may share the same slug (left/right of same region)
    /// since the technique video is symmetric.
    let videoSlug: String?

    var hotspot: CGPoint { CGPoint(x: hotspotX, y: hotspotY) }

    enum Region: String, Codable, Hashable, CaseIterable {
        case abdomen, thigh, deltoid, glute, tricep, calf, pec, lat
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
            needleLength: "1/2 in",
            videoSlug: "subq-abdomen"
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
            needleLength: "1/2 in",
            videoSlug: "subq-abdomen"
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
            needleLength: "1/2 in",
            videoSlug: "subq-thigh"
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
            needleLength: "1/2 in",
            videoSlug: "subq-thigh"
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
            needleLength: "1 in",
            videoSlug: "im-deltoid"
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
            needleLength: "1 in",
            videoSlug: "im-deltoid"
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
            needleLength: "1.5 in",
            videoSlug: "im-glute"
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
            needleLength: "1.5 in",
            videoSlug: "im-glute"
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
            needleLength: "1/2 in",
            videoSlug: "subq-tricep"
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
            needleLength: "1/2 in",
            videoSlug: "subq-tricep"
        ),

        // ─── Upper chest / pec (SubQ) ─────────────────────────────────
        // Used for low-volume SubQ peptides when abdomen/thigh aren't
        // accessible. Avoid the nipple-line and the muscle belly;
        // target the upper chest fat near the clavicle.
        .init(
            id: "pec-subq-left",
            region: .pec, side: .left, route: .subq,
            displayName: "Upper chest (left)",
            bodyView: .front, hotspotX: 0.44, hotspotY: 0.22,
            techniqueMd: """
            **Subcutaneous — upper chest**

            1. Locate the fleshy area just below the clavicle, a hand-width outside the sternum. Avoid the breast tissue / nipple line.
            2. Clean with alcohol.
            3. Pinch a fold of skin and insert at 45–90°.
            4. Push slowly. Hold 5 s, withdraw, press for 10 s.
            """,
            rotationAdvice: "Stay well lateral to the sternum. Alternate sides each session.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in",
            videoSlug: "subq-upperchest"
        ),
        .init(
            id: "pec-subq-right",
            region: .pec, side: .right, route: .subq,
            displayName: "Upper chest (right)",
            bodyView: .front, hotspotX: 0.56, hotspotY: 0.22,
            techniqueMd: """
            **Subcutaneous — upper chest**

            1. Locate the fleshy area just below the clavicle, lateral to the sternum. Avoid the breast tissue.
            2. Clean with alcohol.
            3. Pinch a fold, insert at 45–90°.
            4. Push slowly, hold 5 s, press 10 s.
            """,
            rotationAdvice: "Alternate sides each session. Avoid the nipple line.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in",
            videoSlug: "subq-upperchest"
        ),

        // ─── Lat (SubQ on mid-back) ───────────────────────────────────
        // Rare but viable alt for lean users who want to rotate off the
        // typical abdomen/thigh rotation. Partner assist recommended.
        .init(
            id: "lat-subq-left",
            region: .lat, side: .left, route: .subq,
            displayName: "Mid back — lat (left)",
            bodyView: .back, hotspotX: 0.36, hotspotY: 0.38,
            techniqueMd: """
            **Subcutaneous — mid back / lat**

            1. Locate the soft tissue over the latissimus, just below the shoulder blade.
            2. A partner or mirror is strongly recommended.
            3. Clean with alcohol.
            4. Pinch a fold and insert at 90°.
            5. Push slowly, hold 5 s, press 10 s.
            """,
            rotationAdvice: "Use only when abdomen / thigh need a rest. Alternate sides each session.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in",
            videoSlug: "subq-lat"
        ),
        .init(
            id: "lat-subq-right",
            region: .lat, side: .right, route: .subq,
            displayName: "Mid back — lat (right)",
            bodyView: .back, hotspotX: 0.64, hotspotY: 0.38,
            techniqueMd: """
            **Subcutaneous — mid back / lat**

            1. Locate the soft tissue over the latissimus, just below the shoulder blade.
            2. Clean with alcohol.
            3. Pinch a fold and insert at 90°.
            4. Push slowly, hold 5 s, press 10 s.
            """,
            rotationAdvice: "Alternate sides each session. Partner assist recommended.",
            pinchRequired: true,
            needleGauge: "29G",
            needleLength: "1/2 in",
            videoSlug: "subq-lat"
        ),

        // ─── Quad / VL IM ────────────────────────────────────────────
        // The vastus lateralis is a very forgiving IM site — big muscle,
        // no major nerves or vasculature in the standard target zone.
        .init(
            id: "thigh-im-left",
            region: .thigh, side: .left, route: .im,
            displayName: "Quad / vastus lateralis (left, IM)",
            bodyView: .front, hotspotX: 0.40, hotspotY: 0.66,
            techniqueMd: """
            **Intramuscular — vastus lateralis (front-outer thigh)**

            1. Sit. Divide the thigh lengthwise into thirds — target the outer middle third, about a handspan above the knee and a handspan below the hip.
            2. Clean with alcohol.
            3. Insert the needle at 90° fully into the muscle.
            4. Aspirate — if blood, withdraw and choose a new spot.
            5. Inject slowly (10–15 s per ml). Hold 5 s, withdraw.
            """,
            rotationAdvice: "Great for larger IM volumes. Alternate legs each session.",
            pinchRequired: false,
            needleGauge: "25G",
            needleLength: "1 in",
            videoSlug: "im-quad"
        ),
        .init(
            id: "thigh-im-right",
            region: .thigh, side: .right, route: .im,
            displayName: "Quad / vastus lateralis (right, IM)",
            bodyView: .front, hotspotX: 0.60, hotspotY: 0.66,
            techniqueMd: """
            **Intramuscular — vastus lateralis**

            1. Target the outer middle third of the thigh.
            2. Clean with alcohol.
            3. Insert at 90° fully into muscle. Aspirate.
            4. Inject slowly, hold 5 s, withdraw.
            """,
            rotationAdvice: "Alternate legs each session.",
            pinchRequired: false,
            needleGauge: "25G",
            needleLength: "1 in",
            videoSlug: "im-quad"
        ),
    ]

    static func find(_ id: String) -> PinSite? {
        all.first(where: { $0.id == id })
    }

    static func sites(for ids: [String]) -> [PinSite] {
        ids.compactMap { find($0) }
    }
}
