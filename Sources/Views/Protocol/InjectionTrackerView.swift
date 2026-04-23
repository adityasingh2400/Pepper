import SwiftUI
import SceneKit
import ModelIO
import SwiftData

// MARK: - Zone Model

struct InjectionZone: Identifiable, Hashable {
    let id: String
    let displayName: String
    let position: SIMD3<Float>   // world-space pin position on body

    static func == (lhs: InjectionZone, rhs: InjectionZone) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension InjectionZone {
    // Body mesh: Y -0.95~0.86, X -0.46~0.46, Z -0.14~0.20 (centered at origin)
    static let all: [InjectionZone] = [
        InjectionZone(id: "abdomen_l",  displayName: "Left Abdomen",   position: SIMD3(-0.06, 0.25, 0.18)),
        InjectionZone(id: "abdomen_r",  displayName: "Right Abdomen",  position: SIMD3( 0.06, 0.25, 0.18)),
        InjectionZone(id: "pec_l",      displayName: "Left Pec",       position: SIMD3(-0.12, 0.50, 0.17)),
        InjectionZone(id: "pec_r",      displayName: "Right Pec",      position: SIMD3( 0.12, 0.50, 0.17)),
        InjectionZone(id: "delt_l",     displayName: "Left Delt",      position: SIMD3(-0.38, 0.55, 0.04)),
        InjectionZone(id: "delt_r",     displayName: "Right Delt",     position: SIMD3( 0.38, 0.55, 0.04)),
        InjectionZone(id: "quad_l",     displayName: "Left Quad",      position: SIMD3(-0.11,-0.38, 0.10)),
        InjectionZone(id: "quad_r",     displayName: "Right Quad",     position: SIMD3( 0.11,-0.38, 0.10)),
        InjectionZone(id: "glute_l",    displayName: "Left Glute",     position: SIMD3(-0.11,-0.22,-0.12)),
        InjectionZone(id: "glute_r",    displayName: "Right Glute",    position: SIMD3( 0.11,-0.22,-0.12)),
        InjectionZone(id: "lat_l",      displayName: "Left Lat",       position: SIMD3(-0.20, 0.35,-0.12)),
        InjectionZone(id: "lat_r",      displayName: "Right Lat",      position: SIMD3( 0.20, 0.35,-0.12)),
    ]

    static func zone(for id: String) -> InjectionZone? { all.first { $0.id == id } }

    static func zoneId(forSite site: String) -> String? {
        let map: [String: String] = [
            "left abdomen":  "abdomen_l",  "right abdomen": "abdomen_r",
            "left delt":     "delt_l",     "right delt":    "delt_r",
            "left deltoid":  "delt_l",     "right deltoid": "delt_r",
            "left quad":     "quad_l",     "right quad":    "quad_r",
            "left thigh":    "quad_l",     "right thigh":   "quad_r",
            "left pec":      "pec_l",      "right pec":     "pec_r",
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

    @State private var selectedZone: InjectionZone?

    var recentSiteIds: [String: Date] {
        var result: [String: Date] = [:]
        for log in doseLogs.prefix(120) {
            let id = InjectionZone.zoneId(forSite: log.injectionSite)
                ?? InjectionZone.all.first(where: { $0.displayName.lowercased() == log.injectionSite.lowercased() })?.id
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

                BodySceneView(
                    selectedZone: $selectedZone,
                    recentSites: recentSiteIds
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                ZStack {
                    if let zone = selectedZone {
                        SelectedSiteCard(zone: zone, lastUsed: recentSiteIds[zone.id])
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.horizontal, 16)
                    } else {
                        HStack(spacing: 20) {
                            InjectionLegendDot(color: Color(hex: "e11d48"),             label: "Recent")
                            InjectionLegendDot(color: Color(hex: "e11d48").opacity(0.4), label: "Older")
                            InjectionLegendDot(color: .white.opacity(0.25),             label: "Unused")
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
    }
}

// MARK: - SceneKit View

struct BodySceneView: UIViewRepresentable {
    @Binding var selectedZone: InjectionZone?
    let recentSites: [String: Date]

    func makeCoordinator() -> Coordinator { Coordinator(selectedZone: $selectedZone) }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(red: 0.051, green: 0.051, blue: 0.059, alpha: 1)
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false

        let scene = SCNScene()
        scnView.scene = scene

        // Load OBJ body model
        if let url = Bundle.main.url(forResource: "body", withExtension: "obj"),
           let bodyScene = try? SCNScene(url: url, options: nil) {
            let body = SCNNode()
            for child in bodyScene.rootNode.childNodes { body.addChildNode(child) }
            // Model is in meters, Y-up. Body spans Y: -1.0 to 1.8, center ~0.4
            // Scale 0.85 so T-pose width fits screen; shift down to center
            body.scale    = SCNVector3(1.0, 1.0, 1.0)
            body.position = SCNVector3(0, 0, 0)
            body.name = "body"
            let mat = SCNMaterial()
            mat.diffuse.contents   = UIColor(red: 0.74, green: 0.60, blue: 0.52, alpha: 1)
            mat.roughness.contents = Float(0.78)
            mat.metalness.contents = Float(0.0)
            mat.lightingModel = .physicallyBased
            body.enumerateChildNodes { node, _ in node.geometry?.materials = [mat] }
            scene.rootNode.addChildNode(body)
        }

        // Lighting
        let ambient = SCNNode(); ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.color = UIColor(white: 0.18, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode(); key.light = SCNLight()
        key.light!.type = .directional; key.light!.intensity = 1100
        key.light!.color = UIColor(white: 0.92, alpha: 1)
        key.position = SCNVector3(2, 4, 4); key.look(at: SCNVector3(0, 0.8, 0))
        scene.rootNode.addChildNode(key)

        let fill = SCNNode(); fill.light = SCNLight()
        fill.light!.type = .directional; fill.light!.intensity = 380
        fill.light!.color = UIColor(red: 0.55, green: 0.65, blue: 1.0, alpha: 1)
        fill.position = SCNVector3(-3, 2, -2); fill.look(at: SCNVector3(0, 0.8, 0))
        scene.rootNode.addChildNode(fill)

        // Camera
        let cam = SCNNode(); cam.camera = SCNCamera()
        cam.camera!.fieldOfView = 40
        cam.position = SCNVector3(0, 0, 2.8)
        cam.name = "camera"
        scene.rootNode.addChildNode(cam)

        context.coordinator.scnView = scnView
        refreshPins(scene: scene, recentSites: recentSites, selectedZone: selectedZone)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }
        refreshPins(scene: scene, recentSites: recentSites, selectedZone: selectedZone)
    }

    // MARK: Pins

    private func refreshPins(scene: SCNScene, recentSites: [String: Date], selectedZone: InjectionZone?) {
        scene.rootNode.childNodes.filter { $0.name?.hasPrefix("pin_") == true }.forEach { $0.removeFromParentNode() }
        let now = Date()
        for zone in InjectionZone.all {
            let pin = makePinNode(zone: zone, lastUsed: recentSites[zone.id], now: now, isSelected: selectedZone?.id == zone.id)
            pin.name = "pin_\(zone.id)"
            scene.rootNode.addChildNode(pin)
        }
    }

    private func makePinNode(zone: InjectionZone, lastUsed: Date?, now: Date, isSelected: Bool) -> SCNNode {
        let radius: CGFloat = isSelected ? 0.032 : 0.020
        let sphere = SCNSphere(radius: radius)
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.roughness.contents = Float(0.25)
        mat.metalness.contents = Float(0.1)

        if isSelected {
            mat.diffuse.contents  = UIColor(red: 0.88, green: 0.11, blue: 0.28, alpha: 1)
            mat.emission.contents = UIColor(red: 0.88, green: 0.11, blue: 0.28, alpha: 0.7)
        } else if let used = lastUsed {
            let days = now.timeIntervalSince(used) / 86400
            let alpha = Float(max(0.35, 1.0 - days / 14.0))
            mat.diffuse.contents  = UIColor(red: 0.88, green: 0.11, blue: 0.28, alpha: CGFloat(alpha))
            mat.emission.contents = UIColor(red: 0.88, green: 0.11, blue: 0.28, alpha: CGFloat(alpha * 0.45))
        } else {
            mat.diffuse.contents  = UIColor(white: 1, alpha: 0.30)
            mat.emission.contents = UIColor(white: 0.6, alpha: 0.15)
        }

        sphere.materials = [mat]
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(zone.position.x, zone.position.y, zone.position.z)

        if isSelected {
            let pulse = CABasicAnimation(keyPath: "scale")
            pulse.fromValue = SCNVector3(1, 1, 1)
            pulse.toValue   = SCNVector3(1.5, 1.5, 1.5)
            pulse.duration  = 0.75
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
        private var lastPanX: CGFloat = 0

        init(selectedZone: Binding<InjectionZone?>) { _selectedZone = selectedZone }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let scnView else { return }
            if g.state == .began { lastPanX = 0 }
            let tx = g.translation(in: scnView).x
            let delta = Float(tx - lastPanX) * 0.012
            lastPanX = tx
            scnView.scene?.rootNode.childNode(withName: "body", recursively: false)?
                .runAction(.rotateBy(x: 0, y: CGFloat(delta), z: 0, duration: 0))
            for zone in InjectionZone.all {
                scnView.scene?.rootNode.childNode(withName: "pin_\(zone.id)", recursively: false)?
                    .runAction(.rotateBy(x: 0, y: CGFloat(delta), z: 0, duration: 0))
            }
        }

        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let scnView else { return }
            let pt = g.location(in: scnView)
            let hits = scnView.hitTest(pt, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            for hit in hits {
                if let name = hit.node.name, name.hasPrefix("pin_") {
                    let zoneId = String(name.dropFirst(4))
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedZone = (selectedZone?.id == zoneId) ? nil : InjectionZone.zone(for: zoneId)
                    }
                    return
                }
            }
            withAnimation { selectedZone = nil }
        }
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
                Text(lastUsedText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
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
