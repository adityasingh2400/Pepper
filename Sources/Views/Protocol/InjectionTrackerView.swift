import SwiftUI
import SceneKit
import SwiftData

// MARK: - Body Gender

/// Controls which anatomical mesh + pin-placement map we show. Sourced
/// from the user's `LocalUserProfile.biologicalSex` when available, and
/// overridable via a toggle in the tracker UI. Anatomy is the same for
/// injection-site purposes, but proportions and surface landmarks shift
/// enough that separate pin coords look better than a shared map.
enum BodyGender: String, CaseIterable, Hashable {
    case male, female

    /// Best-guess from the user's profile string. Falls back to male if
    /// the value is missing, "other", or unrecognized — the UI lets the
    /// user flip it either way.
    static func from(profileSex: String?) -> BodyGender {
        switch profileSex?.lowercased() {
        case "female": return .female
        default:       return .male
        }
    }

    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        }
    }
}

// MARK: - Zone Model

struct InjectionZone: Identifiable, Hashable {
    let id: String
    let displayName: String
    /// Position relative to the body root. Coordinate space:
    /// origin between feet, Y up, +Z = front, ±X = left/right.
    /// Values differ slightly per-gender (see `InjectionZone.all(for:)`).
    let position: SIMD3<Float>
    /// Unit vector roughly normal to the body surface at this landmark.
    /// Determines which way the decal-disc faces — e.g. abdomen decals
    /// face +Z (forward), glutes face -Z (back), delts face ±X (side).
    /// Only the direction matters; the disc is always rendered flat to
    /// this normal with a slight push toward / away from the body so it
    /// reads as "pressed onto flesh".
    let surfaceNormal: SIMD3<Float>
    /// Anatomical-region color family. Used to distinguish regions at
    /// a glance — belly vs glute vs thigh vs shoulder each get their
    /// own hue. Recent-use fading is applied on top of this as
    /// desaturation, so the hue identity is preserved even for
    /// "unused" zones.
    let region: ZoneRegion

    static func == (lhs: InjectionZone, rhs: InjectionZone) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Anatomical grouping for color-coding decals on the 3D body.
/// Colors are chosen to be distinguishable at a glance in the dark UI
/// while staying in a muted, medical/clinical palette (no neon).
enum ZoneRegion: Hashable {
    case abdomen
    case upperChest
    case deltoid
    case quad
    case glute
    case lat

    var color: UIColor {
        // Values picked for contrast against the warm skin tone and
        // the near-black background. Tweaked to read as "medical tag"
        // rather than "gaming HUD".
        switch self {
        case .abdomen:    return UIColor(red: 0.94, green: 0.36, blue: 0.45, alpha: 1) // rose
        case .upperChest: return UIColor(red: 0.20, green: 0.72, blue: 0.70, alpha: 1) // teal
        case .deltoid:    return UIColor(red: 0.31, green: 0.60, blue: 0.93, alpha: 1) // blue
        case .quad:       return UIColor(red: 0.96, green: 0.67, blue: 0.25, alpha: 1) // amber
        case .glute:      return UIColor(red: 0.68, green: 0.40, blue: 0.86, alpha: 1) // violet
        case .lat:        return UIColor(red: 0.36, green: 0.78, blue: 0.45, alpha: 1) // green
        }
    }
}

extension InjectionZone {
    // Coordinate space — realistic anatomical mesh, re-oriented to Y-up.
    // After our loader transforms, both meshes share the same space:
    //   Y: 0 at the soles of the feet, ~1.75..1.80 at the top of the head
    //   X: ±0.45 at arm span, ±0.18..0.22 at shoulders, ±0.11..0.14 at hips
    //   Z: +0.14..0.18 front surface (belly/chest), -0.16..-0.20 back
    //
    // Pins sit just *above* the body surface so they remain visible as
    // the mesh rotates under them (they're parented to the body root so
    // they revolve together).

    /// Male pin map — positions surface-snapped to `body.usdz` mesh
    /// vertices + 3mm outward offset so decals press into the skin
    /// cleanly (see `scripts/` notes or the snapping helper I used).
    static let male: [InjectionZone] = [
        // Lower belly / subq abdomen — two inches lateral + two inches below navel.
        InjectionZone(id: "abdomen_l", displayName: "Left Abdomen",
                      position: SIMD3(-0.031, 1.016, 0.089),
                      surfaceNormal: SIMD3(0, 0, 1), region: .abdomen),
        InjectionZone(id: "abdomen_r", displayName: "Right Abdomen",
                      position: SIMD3( 0.034, 1.016, 0.089),
                      surfaceNormal: SIMD3(0, 0, 1), region: .abdomen),
        // Pecs (upper chest, above nipple line)
        InjectionZone(id: "pec_l",     displayName: "Left Pec",
                      position: SIMD3(-0.058, 1.358, 0.088),
                      surfaceNormal: SIMD3(0, 0, 1), region: .upperChest),
        InjectionZone(id: "pec_r",     displayName: "Right Pec",
                      position: SIMD3( 0.050, 1.357, 0.089),
                      surfaceNormal: SIMD3(0, 0, 1), region: .upperChest),
        // Deltoids — outside of shoulder, normal points laterally.
        InjectionZone(id: "delt_l",    displayName: "Left Delt",
                      position: SIMD3(-0.243, 1.464,-0.060),
                      surfaceNormal: SIMD3(-1, 0, 0), region: .deltoid),
        InjectionZone(id: "delt_r",    displayName: "Right Delt",
                      position: SIMD3( 0.245, 1.464,-0.060),
                      surfaceNormal: SIMD3(1, 0, 0),  region: .deltoid),
        // Quads — front of upper thigh.
        InjectionZone(id: "quad_l",    displayName: "Left Quad",
                      position: SIMD3(-0.091, 0.725, 0.057),
                      surfaceNormal: SIMD3(0, 0, 1), region: .quad),
        InjectionZone(id: "quad_r",    displayName: "Right Quad",
                      position: SIMD3( 0.094, 0.725, 0.057),
                      surfaceNormal: SIMD3(0, 0, 1), region: .quad),
        // Glutes — upper outer quadrant on the back, normal points rearward.
        InjectionZone(id: "glute_l",   displayName: "Left Glute",
                      position: SIMD3(-0.072, 0.912,-0.159),
                      surfaceNormal: SIMD3(0, 0,-1), region: .glute),
        InjectionZone(id: "glute_r",   displayName: "Right Glute",
                      position: SIMD3( 0.074, 0.912,-0.159),
                      surfaceNormal: SIMD3(0, 0,-1), region: .glute),
        // Lats — mid back, below shoulder blade, normal rearward.
        InjectionZone(id: "lat_l",     displayName: "Left Lat",
                      position: SIMD3(-0.114, 1.318,-0.159),
                      surfaceNormal: SIMD3(0, 0,-1), region: .lat),
        InjectionZone(id: "lat_r",     displayName: "Right Lat",
                      position: SIMD3( 0.117, 1.318,-0.159),
                      surfaceNormal: SIMD3(0, 0,-1), region: .lat),
    ]

    /// Female pin map — positions surface-snapped to `body_female.obj`
    /// mesh vertices + 3mm outward offset. T-pose, 1.80m tall. Same
    /// coordinate space as male.
    static let female: [InjectionZone] = [
        // Lower belly / subq abdomen.
        InjectionZone(id: "abdomen_l", displayName: "Left Abdomen",
                      position: SIMD3(-0.042, 1.012, 0.097),
                      surfaceNormal: SIMD3(0, 0, 1), region: .abdomen),
        InjectionZone(id: "abdomen_r", displayName: "Right Abdomen",
                      position: SIMD3( 0.042, 1.012, 0.097),
                      surfaceNormal: SIMD3(0, 0, 1), region: .abdomen),
        // Upper chest (clavicle region, above breast — female IM sites
        // move up to avoid glandular tissue).
        InjectionZone(id: "pec_l",     displayName: "Left Upper Chest",
                      position: SIMD3(-0.083, 1.357, 0.127),
                      surfaceNormal: SIMD3(0, 0, 1), region: .upperChest),
        InjectionZone(id: "pec_r",     displayName: "Right Upper Chest",
                      position: SIMD3( 0.083, 1.357, 0.127),
                      surfaceNormal: SIMD3(0, 0, 1), region: .upperChest),
        // Deltoids — T-pose shoulder cap at y≈1.47, x≈±0.32
        // (shoulder joint, constrained to not drift to the arm).
        InjectionZone(id: "delt_l",    displayName: "Left Delt",
                      position: SIMD3(-0.323, 1.465,-0.088),
                      surfaceNormal: SIMD3(-1, 0, 0), region: .deltoid),
        InjectionZone(id: "delt_r",    displayName: "Right Delt",
                      position: SIMD3( 0.323, 1.465,-0.088),
                      surfaceNormal: SIMD3(1, 0, 0),  region: .deltoid),
        // Quads — front of upper thigh.
        InjectionZone(id: "quad_l",    displayName: "Left Quad",
                      position: SIMD3(-0.109, 0.723, 0.084),
                      surfaceNormal: SIMD3(0, 0, 1), region: .quad),
        InjectionZone(id: "quad_r",    displayName: "Right Quad",
                      position: SIMD3( 0.109, 0.723, 0.084),
                      surfaceNormal: SIMD3(0, 0, 1), region: .quad),
        // Glutes — upper outer quadrant on the back.
        InjectionZone(id: "glute_l",   displayName: "Left Glute",
                      position: SIMD3(-0.075, 0.929,-0.135),
                      surfaceNormal: SIMD3(0, 0,-1), region: .glute),
        InjectionZone(id: "glute_r",   displayName: "Right Glute",
                      position: SIMD3( 0.075, 0.929,-0.135),
                      surfaceNormal: SIMD3(0, 0,-1), region: .glute),
        // Lats — mid back, below shoulder blade.
        InjectionZone(id: "lat_l",     displayName: "Left Lat",
                      position: SIMD3(-0.119, 1.317,-0.086),
                      surfaceNormal: SIMD3(0, 0,-1), region: .lat),
        InjectionZone(id: "lat_r",     displayName: "Right Lat",
                      position: SIMD3( 0.119, 1.317,-0.086),
                      surfaceNormal: SIMD3(0, 0,-1), region: .lat),
    ]

    static func all(for gender: BodyGender) -> [InjectionZone] {
        switch gender {
        case .male:   return male
        case .female: return female
        }
    }

    static func zone(for id: String, gender: BodyGender) -> InjectionZone? {
        all(for: gender).first { $0.id == id }
    }

    /// Maps a 3D tracker zone id to the richer `PinSite` catalog entry
    /// (defined in `Models/PinSite.swift`) used by the instruction
    /// sheet. The PinSite carries the step-by-step markdown, needle
    /// specs, rotation advice, and video slug.
    ///
    /// `abdomen/quad/glute/delt` default to the SubQ variant for L-side
    /// and IM for the deltoid/glute because that's how the zones get
    /// used in practice. We could make this per-compound later (the
    /// user's dosing log knows the route) — for now it's a safe map.
    var pinSiteId: String? {
        switch id {
        case "abdomen_l":  return "abdomen-subq-left"
        case "abdomen_r":  return "abdomen-subq-right"
        case "pec_l":      return "pec-subq-left"
        case "pec_r":      return "pec-subq-right"
        case "delt_l":     return "deltoid-im-left"
        case "delt_r":     return "deltoid-im-right"
        case "quad_l":     return "thigh-subq-left"     // subq default; IM alt exists
        case "quad_r":     return "thigh-subq-right"
        case "glute_l":    return "glute-im-left"
        case "glute_r":    return "glute-im-right"
        case "lat_l":      return "lat-subq-left"
        case "lat_r":      return "lat-subq-right"
        default: return nil
        }
    }

    var pinSite: PinSite? {
        guard let pid = pinSiteId else { return nil }
        return PinSiteCatalog.find(pid)
    }

    static func zoneId(forSite site: String) -> String? {
        let map: [String: String] = [
            "left abdomen":  "abdomen_l",  "right abdomen": "abdomen_r",
            "left delt":     "delt_l",     "right delt":    "delt_r",
            "left deltoid":  "delt_l",     "right deltoid": "delt_r",
            "left quad":     "quad_l",     "right quad":    "quad_r",
            "left thigh":    "quad_l",     "right thigh":   "quad_r",
            "left pec":      "pec_l",      "right pec":     "pec_r",
            "left upper chest": "pec_l",   "right upper chest": "pec_r",
            "left glute":    "glute_l",    "right glute":   "glute_r",
            "left lat":      "lat_l",      "right lat":     "lat_r",
        ]
        return map[site.lowercased()]
    }
}

// MARK: - Main View

struct InjectionTrackerView: View {
    @EnvironmentObject private var authManager: AuthManager

    @Query(sort: \LocalDoseLog.dosedAt, order: .reverse)
    private var doseLogs: [LocalDoseLog]

    @Query private var profiles: [CachedUserProfile]

    @State private var selectedZone: InjectionZone?
    @State private var gender: BodyGender?
    /// When non-nil, presents the full step-by-step injection guide sheet
    /// with instructional video + technique markdown. Tapping the flyout
    /// card (or directly on a pin a second time) sets this.
    @State private var guideSite: PinSite?

    /// Resolved gender — user's explicit toggle wins, otherwise profile, otherwise male.
    private var activeGender: BodyGender {
        gender ?? BodyGender.from(profileSex: profiles.first?.biologicalSex)
    }

    var recentSiteIds: [String: Date] {
        var result: [String: Date] = [:]
        let zones = InjectionZone.all(for: activeGender)
        for log in doseLogs.prefix(120) {
            let id = InjectionZone.zoneId(forSite: log.injectionSite)
                ?? zones.first(where: { $0.displayName.lowercased() == log.injectionSite.lowercased() })?.id
            if let id, result[id] == nil { result[id] = log.dosedAt }
        }
        return result
    }

    var body: some View {
        ZStack {
            Color(hex: "0d0d0f").ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Drag to rotate · tap a site")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 10)

                genderToggle
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                BodySceneView(
                    selectedZone: $selectedZone,
                    recentSites: recentSiteIds,
                    gender: activeGender
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                ZStack {
                    if let zone = selectedZone {
                        Button {
                            if let site = zone.pinSite {
                                guideSite = site
                            }
                        } label: {
                            SelectedSiteCard(zone: zone, lastUsed: recentSiteIds[zone.id])
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                    } else {
                        // Region color key — matches the decals on the body.
                        // Each anatomical zone family has its own hue; recency
                        // is indicated by the decal's saturation/glow (not
                        // listed here to keep the legend readable).
                        HStack(spacing: 10) {
                            InjectionLegendDot(color: Color(ZoneRegion.abdomen.color),    label: "Abs")
                            InjectionLegendDot(color: Color(ZoneRegion.upperChest.color), label: "Chest")
                            InjectionLegendDot(color: Color(ZoneRegion.deltoid.color),    label: "Delt")
                            InjectionLegendDot(color: Color(ZoneRegion.quad.color),       label: "Quad")
                            InjectionLegendDot(color: Color(ZoneRegion.glute.color),      label: "Glute")
                            InjectionLegendDot(color: Color(ZoneRegion.lat.color),        label: "Lat")
                        }
                        .transition(.opacity)
                    }
                }
                .frame(height: selectedZone != nil ? 80 : 44)
                .padding(.bottom, 20)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedZone?.id)
            }
        }
        .navigationTitle("Injection Sites")
        .navigationBarTitleDisplayMode(.inline)
        // Full instructional sheet (video + step-by-step technique)
        // pops when the user taps the SelectedSiteCard flyout.
        .sheet(item: $guideSite) { site in
            PinSiteSheet(site: site)
        }
        // When the user flips gender, the previously selected zone id
        // might not be present in the other map — clear it so we don't
        // dangle a stale selection.
        .onChange(of: activeGender) { _, newGender in
            if let sel = selectedZone,
               InjectionZone.zone(for: sel.id, gender: newGender) == nil {
                selectedZone = nil
            }
        }
    }

    /// Small segmented toggle at the top of the view so the user can
    /// switch the displayed anatomy without editing their profile.
    private var genderToggle: some View {
        HStack(spacing: 4) {
            ForEach(BodyGender.allCases, id: \.self) { g in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        gender = g
                    }
                } label: {
                    Text(g.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(activeGender == g ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(activeGender == g
                                      ? Color(hex: "e11d48").opacity(0.85)
                                      : Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 240)
    }
}

// MARK: - SceneKit View

struct BodySceneView: UIViewRepresentable {
    @Binding var selectedZone: InjectionZone?
    let recentSites: [String: Date]
    let gender: BodyGender

    func makeCoordinator() -> Coordinator { Coordinator(selectedZone: $selectedZone) }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(red: 0.051, green: 0.051, blue: 0.059, alpha: 1)
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false

        let scene = SCNScene()
        scnView.scene = scene

        // Lighting — aimed at body center (~y=1.0)
        let ambient = SCNNode(); ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.color = UIColor(white: 0.22, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode(); key.light = SCNLight()
        key.light!.type = .directional; key.light!.intensity = 1100
        key.light!.color = UIColor(white: 0.95, alpha: 1)
        key.position = SCNVector3(2, 4, 4); key.look(at: SCNVector3(0, 1.0, 0))
        scene.rootNode.addChildNode(key)

        let fill = SCNNode(); fill.light = SCNLight()
        fill.light!.type = .directional; fill.light!.intensity = 420
        fill.light!.color = UIColor(red: 0.55, green: 0.65, blue: 1.0, alpha: 1)
        fill.position = SCNVector3(-3, 2, -2); fill.look(at: SCNVector3(0, 1.0, 0))
        scene.rootNode.addChildNode(fill)

        // Rim light behind, so the silhouette reads against the dark bg
        let rim = SCNNode(); rim.light = SCNLight()
        rim.light!.type = .directional; rim.light!.intensity = 300
        rim.light!.color = UIColor(red: 1.0, green: 0.85, blue: 0.80, alpha: 1)
        rim.position = SCNVector3(0, 1.5, -3); rim.look(at: SCNVector3(0, 1.0, 0))
        scene.rootNode.addChildNode(rim)

        // Camera — frame the full body (y 0..1.80) with a little padding
        let cam = SCNNode(); cam.camera = SCNCamera()
        cam.camera!.fieldOfView = 40
        cam.camera!.zNear = 0.05
        cam.camera!.zFar  = 20
        cam.position = SCNVector3(0, 0.95, 3.2)
        cam.name = "camera"
        scene.rootNode.addChildNode(cam)

        context.coordinator.scnView = scnView
        installBody(in: scene, gender: gender, coordinator: context.coordinator)
        context.coordinator.startAutoRotate()

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }

        // Gender swap — rebuild the body mesh + pins when the user toggles.
        if context.coordinator.currentGender != gender {
            installBody(in: scene, gender: gender, coordinator: context.coordinator)
        }

        guard let body = context.coordinator.bodyNode else { return }
        refreshPins(body: body, gender: gender, recentSites: recentSites, selectedZone: selectedZone)

        // Pause the revolve while a site is selected so the user can read the card
        if selectedZone != nil {
            context.coordinator.stopAutoRotate()
        } else {
            context.coordinator.startAutoRotate()
        }
    }

    // MARK: Body install / swap

    /// Removes the previous body node (if any) and installs a fresh one
    /// for the requested gender. Preserves the current Y rotation so the
    /// user's drag position survives a gender toggle.
    private func installBody(in scene: SCNScene, gender: BodyGender, coordinator: Coordinator) {
        let previousYaw = coordinator.bodyNode?.eulerAngles.y ?? 0
        coordinator.stopAutoRotate()
        scene.rootNode.childNodes
            .filter { $0.name == "body" }
            .forEach { $0.removeFromParentNode() }

        let body = BodyMeshLoader.loadNode(gender: gender)
        body.name = "body"
        body.eulerAngles.y = previousYaw
        scene.rootNode.addChildNode(body)

        coordinator.bodyNode = body
        coordinator.currentGender = gender

        refreshPins(body: body, gender: gender, recentSites: recentSites, selectedZone: selectedZone)
    }

    // MARK: Pins

    private func refreshPins(body: SCNNode, gender: BodyGender, recentSites: [String: Date], selectedZone: InjectionZone?) {
        body.childNodes.filter { $0.name?.hasPrefix("pin_") == true }.forEach { $0.removeFromParentNode() }
        let now = Date()
        for zone in InjectionZone.all(for: gender) {
            let pin = makePinNode(zone: zone, lastUsed: recentSites[zone.id], now: now, isSelected: selectedZone?.id == zone.id)
            pin.name = "pin_\(zone.id)"
            body.addChildNode(pin)
        }
    }

    /// Builds a zone indicator as a flattened dome embedded in the body
    /// surface. The dome is oriented so its flat axis aligns with the
    /// zone's surface normal, and positioned so only the cap protrudes
    /// past the body mesh — reading as a colored patch "pressed onto"
    /// the flesh rather than a floating bubble. The body mesh occludes
    /// the hidden half naturally via depth-testing.
    /// Builds a decal node for a zone: a flat plane oriented to face
    /// along the zone's surface normal, with a soft radial gradient
    /// texture so the edges blend into skin rather than cutting off at
    /// a hard circle boundary. The plane uses `.constant` lighting
    /// (pure emission, no shading) so it reads as a painted spotlight
    /// on the skin rather than a 3D bubble — wraps around body
    /// curvature naturally via its oriented facing.
    private func makePinNode(zone: InjectionZone, lastUsed: Date?, now: Date, isSelected: Bool) -> SCNNode {
        let baseRadius: CGFloat = isSelected ? 0.055 : 0.042

        // The plane is 1:1 square; the gradient texture provides the
        // circular shape via alpha falloff.
        let side = baseRadius * 2
        let plane = SCNPlane(width: side, height: side)

        let mat = SCNMaterial()
        // `.constant` = no lighting applied; emission is rendered as-is.
        // This is what makes the patch read as painted color rather
        // than lit geometry.
        mat.lightingModel = .constant
        mat.isDoubleSided = false
        // Read depth so the body mesh occludes decals on the far side
        // during rotation; don't write depth so overlapping decals blend.
        mat.readsFromDepthBuffer  = true
        mat.writesToDepthBuffer   = false
        // Blending mode: straight alpha so the gradient edge fades into
        // the body color beneath.
        mat.blendMode = .alpha
        mat.transparency = 1

        // Compute the final color + intensity based on recency / selection.
        let regionColor = zone.region.color
        var decalColor = regionColor
        var coreAlpha: CGFloat = 0.85   // center-of-disc opacity

        if isSelected {
            decalColor = regionColor
            coreAlpha = 1.0
        } else if let used = lastUsed {
            let days = now.timeIntervalSince(used) / 86400
            let freshness = max(0, 1.0 - days / 14.0)
            // Recent = strong color; older = fades out.
            coreAlpha = CGFloat(0.4 + 0.55 * freshness)
        } else {
            // Never used — reduced intensity so resting state isn't loud.
            coreAlpha = 0.55
        }

        // Build the radial-gradient texture (cached per color+alpha key
        // so we don't burn CPU on every refresh).
        mat.diffuse.contents = PinDecalTexture.image(color: decalColor, coreAlpha: coreAlpha)
        // Emission mirrors diffuse so the color stays vivid even when
        // the body's own lighting dims the area — again: painted
        // spotlight, not shaded geometry.
        mat.emission.contents = PinDecalTexture.image(color: decalColor,
                                                      coreAlpha: coreAlpha * (isSelected ? 0.9 : 0.55))

        plane.firstMaterial = mat
        let node = SCNNode(geometry: plane)

        // Orient the plane so its local +Z (the face the texture is on
        // for SCNPlane) points along the surface normal. SCNPlane faces
        // +Z by default; we need it to face `normal`, so we rotate +Z
        // to match `normal`.
        let n = simd_normalize(zone.surfaceNormal)
        let zAxis = SIMD3<Float>(0, 0, 1)
        let dot = simd_dot(zAxis, n)
        if dot < 0.999 && dot > -0.999 {
            let axis = simd_normalize(simd_cross(zAxis, n))
            let angle = acos(dot)
            node.simdOrientation = simd_quatf(angle: angle, axis: axis)
        } else if dot <= -0.999 {
            // Normal points straight back (-Z): rotate 180° around Y.
            node.simdOrientation = simd_quatf(angle: .pi, axis: SIMD3(0, 1, 0))
        }
        // else: dot ≈ 1, normal already +Z, no rotation needed.

        // Sit 1mm above the surface along the normal — close enough to
        // read as "on the skin" but out of the mesh to avoid z-fighting.
        let lift: Float = 0.001
        node.position = SCNVector3(
            zone.position.x + n.x * lift,
            zone.position.y + n.y * lift,
            zone.position.z + n.z * lift
        )

        if isSelected {
            // Gentle breathing pulse — scales the whole node (plane) so
            // the decal grows and shrinks like a soft glow.
            let pulse = CABasicAnimation(keyPath: "scale")
            pulse.fromValue = SCNVector3(1, 1, 1)
            pulse.toValue   = SCNVector3(1.35, 1.35, 1.35)
            pulse.duration  = 0.85
            pulse.autoreverses = true
            pulse.repeatCount  = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            node.addAnimation(pulse, forKey: "pulse")
        }
        return node
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject {
        @Binding var selectedZone: InjectionZone?
        weak var scnView: SCNView?
        weak var bodyNode: SCNNode?
        /// Gender currently rendered — compared in `updateUIView` to detect
        /// a toggle and trigger a mesh swap.
        var currentGender: BodyGender?
        private var lastPanX: CGFloat = 0
        private var isAutoRotating = false
        private var isUserDragging = false

        init(selectedZone: Binding<InjectionZone?>) { _selectedZone = selectedZone }

        func startAutoRotate() {
            guard !isAutoRotating, !isUserDragging, let body = bodyNode else { return }
            isAutoRotating = true
            // Slow revolve — full rotation every 20s
            let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 20)
            body.runAction(.repeatForever(spin), forKey: "autoRotate")
        }

        func stopAutoRotate() {
            guard isAutoRotating else { return }
            isAutoRotating = false
            bodyNode?.removeAction(forKey: "autoRotate")
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let scnView, let body = bodyNode else { return }
            switch g.state {
            case .began:
                isUserDragging = true
                stopAutoRotate()
                lastPanX = 0
            case .ended, .cancelled, .failed:
                isUserDragging = false
                if selectedZone == nil { startAutoRotate() }
                return
            default:
                break
            }
            let tx = g.translation(in: scnView).x
            let delta = Float(tx - lastPanX) * 0.012
            lastPanX = tx
            body.eulerAngles.y += delta
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let scnView, let gender = currentGender else { return }
            let pt = g.location(in: scnView)
            let hits = scnView.hitTest(pt, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            for hit in hits {
                if let name = hit.node.name, name.hasPrefix("pin_") {
                    let zoneId = String(name.dropFirst(4))
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedZone = (selectedZone?.id == zoneId)
                            ? nil
                            : InjectionZone.zone(for: zoneId, gender: gender)
                    }
                    return
                }
            }
            withAnimation { selectedZone = nil }
        }
    }
}

// MARK: - Body Mesh Loader
//
// Loads a realistic anatomical mesh from a bundled USDZ:
//   .male   → body.usdz          (required — ships with the app)
//   .female → body_female.usdz   (optional — ships if the file is
//              added to the app bundle; loader falls back to male when
//              the file is missing so the tracker never goes blank)
//
// Both USDZs are authored in Blender with Z-up and a few extraneous
// prims (a cube floor, the export camera, export lights, a dome light,
// separate eye meshes we don't need as interactive geometry). This
// loader:
//   1. Reads the USDZ into a throwaway scene
//   2. Extracts only the body-geometry prims (nodes whose name contains
//      "body" or "geo_body" — eyes, teeth, etc. ride along as children
//      of the body mesh in the USDZ)
//   3. Rotates -90° around X to convert Z-up → Y-up (SceneKit convention)
//   4. Applies a single PBR skin material so lighting looks consistent
//   5. Re-centers so feet sit on y=0 and the body is centered on x=0
//
// After transforming, the resulting node has bounds (in root-local space):
//   X: ±0.45, Y: 0..1.80, Z: ±0.16
// (matches the `InjectionZone.position` coordinate space above)
private enum BodyMeshLoader {
    /// Bundled resource name (without extension) for a given gender.
    /// We intentionally keep the male file named just "body" to stay
    /// backward-compatible with the original pre-gender-toggle code
    /// path and avoid renaming the existing asset in the Xcode project.
    private static func resourceName(for gender: BodyGender) -> String {
        switch gender {
        case .male:   return "body"
        case .female: return "body_female"
        }
    }

    /// File extensions to try, in priority order. USDZ first because
    /// our male mesh is USDZ; OBJ second for the current female mesh.
    /// GLB would be easy to add if needed.
    private static let extensions = ["usdz", "obj"]

    /// Collapses the mesh import into a single node with a consistent
    /// material, re-oriented to Y-up and resting on y=0. Falls back to
    /// the male mesh if the requested gender's asset is missing.
    static func loadNode(gender: BodyGender) -> SCNNode {
        if let node = tryLoad(baseName: resourceName(for: gender)) {
            return node
        }
        // Graceful fallback — use the male mesh rather than an empty view
        // while the other gender's asset is pending in the bundle.
        if gender != .male, let node = tryLoad(baseName: resourceName(for: .male)) {
            #if DEBUG
            print("[InjectionTracker] \(resourceName(for: gender)) not found; falling back to male mesh.")
            #endif
            return node
        }
        assertionFailure("No body mesh could be loaded from bundle")
        return SCNNode()
    }

    /// Walks the extension list trying to find a matching bundle
    /// resource. Each candidate is parsed into a SceneKit scene and
    /// normalized into a uniform coordinate space.
    private static func tryLoad(baseName: String) -> SCNNode? {
        for ext in extensions {
            guard let url = Bundle.main.url(forResource: baseName, withExtension: ext),
                  let scene = try? SCNScene(url: url, options: [
                      .checkConsistency: true,
                      .flattenScene: false,
                  ])
            else { continue }

            if let node = normalize(scene: scene) {
                return node
            }
        }
        return nil
    }

    /// Applies coordinate-system fixup, material override, and
    /// re-centering on a loaded scene. Returns nil if no body geometry
    /// was found.
    private static func normalize(scene: SCNScene) -> SCNNode? {
        // Outer node: this is what we hand back; scene-level rotation
        // animations spin around its Y axis.
        let root = SCNNode()

        // `orient` is an inner node we apply one-time fixups to (rotation
        // + translation). Pins are added as children of `root`, so they
        // use a clean anatomical coordinate space unaffected by these
        // fixups.
        let orient = SCNNode()
        root.addChildNode(orient)

        // Pull body geometry out of the loaded scene and discard any
        // non-body prims (Blender cameras, lights, reference cubes).
        for child in scene.rootNode.childNodes {
            collectBodyMeshes(from: child, into: orient)
        }
        if !orient.childNodes.contains(where: { hasGeometry(in: $0) }) {
            for child in scene.rootNode.childNodes {
                copyAllGeometry(from: child, into: orient)
            }
        }
        if !orient.childNodes.contains(where: { hasGeometry(in: $0) }) {
            return nil       // caller will try the next extension
        }

        // Apply a single consistent skin material so lighting behaves
        // regardless of what shaders the source file shipped with.
        let skin = SCNMaterial()
        skin.lightingModel      = .physicallyBased
        skin.diffuse.contents   = UIColor(red: 0.83, green: 0.68, blue: 0.58, alpha: 1)
        skin.roughness.contents = Float(0.72)
        skin.metalness.contents = Float(0.02)
        root.enumerateHierarchy { node, _ in
            if let geo = node.geometry {
                geo.materials = [skin]
            }
        }

        // Detect up-axis empirically from bounding box shape, rather
        // than trusting the file format. A human body is always tallest
        // in its up-axis; whichever axis has the largest extent is up.
        // This works for both our USDZ (Z-up) and OBJ (Y-up) meshes
        // without special-casing file extensions.
        let raw = root.boundingBox
        let dx = raw.max.x - raw.min.x
        let dy = raw.max.y - raw.min.y
        let dz = raw.max.z - raw.min.z

        if dz > dy && dz > dx {
            // Z-up → Y-up. Rotate -90° around X:
            //   (x, y, z) → (x, z, -y)
            // This puts the height on +Y (head up). For our particular
            // USDZ files, the body is also authored with -Y as forward,
            // which becomes +Z (facing the camera) after this rotation.
            orient.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        }
        // else: Y-up already (typical OBJ export from Blender). No rotation.

        // Center on x=0 and z=0; plant feet on y=0.
        // We use the post-rotation bbox so centering is correct.
        let (minBB, maxBB) = root.boundingBox
        if maxBB.y > minBB.y {
            let centerX = (minBB.x + maxBB.x) * 0.5
            let centerZ = (minBB.z + maxBB.z) * 0.5
            orient.position.x -= centerX
            orient.position.y -= minBB.y
            orient.position.z -= centerZ
        }

        return root
    }

    /// Recursively walks `src`, copying any node whose lineage name
    /// hints it's part of the body mesh into `dst`. Preserves transforms.
    private static func collectBodyMeshes(from src: SCNNode, into dst: SCNNode) {
        let name = (src.name ?? "").lowercased()

        // Skip export-time junk: cameras, lights, the reference cube,
        // and anything that explicitly isn't body geometry.
        if src.camera != nil || src.light != nil {
            return
        }
        if name == "cube" || name == "camera" || name.contains("light") {
            return
        }

        if name.contains("body") || name.contains("geo_body") || name.contains("geo-body") {
            // Take the whole subtree — eyes/teeth ride along with the
            // main mesh as children in the Blender export.
            let clone = src.clone()
            dst.addChildNode(clone)
            return
        }

        for child in src.childNodes {
            collectBodyMeshes(from: child, into: dst)
        }
    }

    /// Fallback: copy everything geometry-bearing (excluding cameras/lights).
    private static func copyAllGeometry(from src: SCNNode, into dst: SCNNode) {
        if src.camera != nil || src.light != nil { return }
        if src.geometry != nil {
            dst.addChildNode(src.clone())
            return
        }
        for child in src.childNodes {
            copyAllGeometry(from: child, into: dst)
        }
    }

    private static func hasGeometry(in node: SCNNode) -> Bool {
        if node.geometry != nil { return true }
        for c in node.childNodes where hasGeometry(in: c) { return true }
        return false
    }
}

// MARK: - Selected Site Card

struct SelectedSiteCard: View {
    let zone: InjectionZone
    let lastUsed: Date?

    private var lastUsedText: String {
        guard let d = lastUsed else { return "Never used" }
        let days = Calendar.current.dateComponents([.day], from: d, to: .now).day ?? 0
        if days == 0 { return "Used today" }
        if days == 1 { return "Used yesterday" }
        return "Used \(days) days ago"
    }

    private var rec: (text: String, color: Color) {
        guard let d = lastUsed else { return ("Good to use", Color(hex: "22c55e")) }
        let days = Calendar.current.dateComponents([.day], from: d, to: .now).day ?? 0
        if days < 2  { return ("Rest recommended", Color(hex: "f97316")) }
        if days < 5  { return ("Usable",            Color(hex: "eab308")) }
        return ("Good to use", Color(hex: "22c55e"))
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(lastUsedText)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    Text("·")
                        .foregroundColor(.white.opacity(0.3))
                    HStack(spacing: 3) {
                        Text("Tap for guide")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "e11d48"))
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(rec.color).frame(width: 8, height: 8)
                Text(rec.text)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(rec.color)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "e11d48").opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Legend

private struct InjectionLegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Pin decal texture generator
//
// Builds a small radial-gradient image for use as an SCNPlane's diffuse
// texture. The gradient is fully opaque tinted color at center, fading
// to fully transparent at the edge — which gives each decal a soft
// circular glow that blends into the body surface, rather than a
// hard-edged disc.
//
// Textures are cached by (color hex, coreAlpha bucketed to 0.05)
// because pins re-render on every `updateUIView` and we don't want
// to burn CPU re-drawing identical gradients. At ~12 pins * ~4 unique
// alpha states the cache stays tiny.
//
// `@MainActor`: decal textures are only ever built from inside SwiftUI /
// SceneKit view updates, which run on the main actor anyway. This is
// the least-invasive way to satisfy Swift 6 strict concurrency rules
// about the shared cache.
@MainActor
private enum PinDecalTexture {
    private static var cache: [String: UIImage] = [:]
    private static let size = CGSize(width: 128, height: 128)

    /// Returns a cached (or freshly drawn) radial-gradient image.
    /// - Parameter color: the hue at the disc's center.
    /// - Parameter coreAlpha: opacity at the center (0..1); the
    ///   gradient always fades to 0 at the edge.
    static func image(color: UIColor, coreAlpha: CGFloat) -> UIImage {
        // Bucket alpha to avoid cache churn from tiny numerical noise
        // (e.g. freshness = 0.6123 vs 0.6124 shouldn't be separate entries).
        let bucketedAlpha = (coreAlpha * 20).rounded() / 20
        let key = cacheKey(color: color, alpha: bucketedAlpha)
        if let hit = cache[key] { return hit }

        let img = draw(color: color, coreAlpha: bucketedAlpha)
        cache[key] = img
        return img
    }

    private static func cacheKey(color: UIColor, alpha: CGFloat) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return "\(Int(r * 255))_\(Int(g * 255))_\(Int(b * 255))_\(Int(alpha * 100))"
    }

    private static func draw(color: UIColor, coreAlpha: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)

            // Four-stop gradient: bright core, soft shoulder, faint halo,
            // transparent edge. This gives the decal a glow-like quality
            // rather than a flat colored disc.
            let cs = CGColorSpaceCreateDeviceRGB()
            let colors: [CGColor] = [
                UIColor(red: r, green: g, blue: b, alpha: coreAlpha).cgColor,
                UIColor(red: r, green: g, blue: b, alpha: coreAlpha * 0.70).cgColor,
                UIColor(red: r, green: g, blue: b, alpha: coreAlpha * 0.25).cgColor,
                UIColor(red: r, green: g, blue: b, alpha: 0).cgColor,
            ]
            let stops: [CGFloat] = [0.0, 0.45, 0.80, 1.0]
            guard let gradient = CGGradient(
                colorsSpace: cs,
                colors: colors as CFArray,
                locations: stops
            ) else { return }

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2

            cg.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter:   center, endRadius:   radius,
                options: []
            )
        }
    }
}

// MARK: - UIColor helpers for decal tinting
//
// Small utility extensions used by `makePinNode` to:
//   - desaturate a region hue toward skin tone as injection sites age
//   - reduce emission intensity without affecting diffuse hue
// Both are component-wise linear blends; we deliberately stay in
// sRGB (not linear) space because that matches how UIColor's
// getRed(_:...) reports components and how SceneKit reads
// `diffuse.contents` when given a UIColor.
private extension UIColor {
    /// Linear blend between two colors in sRGB space. `t=0` returns
    /// self unchanged; `t=1` returns the other color. Alpha channels
    /// are blended identically.
    func mixed(with other: UIColor, t: CGFloat) -> UIColor {
        let tc = max(0, min(1, t))
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red:   r1 + (r2 - r1) * tc,
            green: g1 + (g2 - g1) * tc,
            blue:  b1 + (b2 - b1) * tc,
            alpha: a1 + (a2 - a1) * tc
        )
    }

    /// Multiply RGB components by a scalar (clamped to [0, 1]) while
    /// preserving alpha. Used to build a muted "emission" glow from the
    /// same hue as `diffuse` without re-declaring the color.
    func multiplied(by scalar: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red:   max(0, min(1, r * scalar)),
            green: max(0, min(1, g * scalar)),
            blue:  max(0, min(1, b * scalar)),
            alpha: a
        )
    }
}
