import SwiftUI

/// Toggle between the front and back view of a stylized human body
/// and let the user tap injection sites laid out as hotspots.
///
/// Hotspot coordinates come from `PinSite.hotspotX/Y` (normalized 0..1).
/// We don't ship a real anatomical illustration here — we render a
/// schematic body with primitive shapes so the feature works offline
/// and on every device, while staying very legible. When/if we add a
/// real PNG/SVG asset we just drop it in the `Image("body-front")`
/// fallback below.
struct AnatomicalBodyView: View {
    let sites: [PinSite]
    let highlightSiteIds: Set<String>
    var onSelect: (PinSite) -> Void = { _ in }

    @State private var bodyView: PinSite.BodyView = .front

    private var visibleSites: [PinSite] {
        sites.filter { $0.bodyView == bodyView }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(PinSite.BodyView.allCases, id: \.self) { view in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            bodyView = view
                        }
                    } label: {
                        Text(view.rawValue.capitalized)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(bodyView == view ? .white : Color.appTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(bodyView == view ? Color.appAccent : Color.appCardElevated)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)

            GeometryReader { geo in
                ZStack {
                    BodySilhouette(view: bodyView)
                        .stroke(Color.appBorder, lineWidth: 1.5)
                        .background(
                            BodySilhouette(view: bodyView)
                                .fill(Color.appCardElevated.opacity(0.6))
                        )
                        .padding(.vertical, 4)

                    ForEach(visibleSites) { site in
                        let isHot = highlightSiteIds.contains(site.id)
                        Hotspot(isHighlighted: isHot)
                            .position(
                                x: geo.size.width  * site.hotspotX,
                                y: geo.size.height * site.hotspotY
                            )
                            .onTapGesture {
                                onSelect(site)
                            }
                    }
                }
            }
            .aspectRatio(0.45, contentMode: .fit)   // tall, body-shaped frame
            .padding(.horizontal, 16)

            HStack(spacing: 14) {
                BodyLegendDot(color: Color.appAccent, label: "Recommended")
                BodyLegendDot(color: Color.appTextMeta.opacity(0.5), label: "Other site")
            }
            .padding(.top, 4)
        }
    }
}

private struct Hotspot: View {
    let isHighlighted: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            if isHighlighted {
                Circle()
                    .stroke(Color.appAccent.opacity(0.5), lineWidth: 1)
                    .frame(width: pulse ? 36 : 22, height: pulse ? 36 : 22)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
            }
            Circle()
                .fill(isHighlighted ? Color.appAccent : Color.appTextMeta.opacity(0.6))
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
        }
        .contentShape(Rectangle().inset(by: -12))   // generous tap target
        .onAppear { if isHighlighted { pulse = true } }
    }
}

private struct BodyLegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.appTextTertiary)
        }
    }
}

// MARK: - Stylized human silhouette

/// Schematic body shape composed from primitives — head, torso, arms, legs.
/// Drawn in a 100x222 viewbox and scaled to the parent frame.
private struct BodySilhouette: Shape {
    let view: PinSite.BodyView

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Pixel coords inside a 100 x 222 viewbox, scaled to rect
        func p(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: w * (x / 100), y: h * (y / 222))
        }

        // Head
        path.addEllipse(in: CGRect(
            x: w * 0.42, y: h * 0.012,
            width: w * 0.16, height: h * 0.085
        ))

        // Neck
        path.move(to: p(46, 22))
        path.addLine(to: p(54, 22))
        path.addLine(to: p(56, 30))
        path.addLine(to: p(44, 30))
        path.closeSubpath()

        // Torso (slightly trapezoidal, narrower waist)
        path.move(to: p(28, 30))
        path.addLine(to: p(72, 30))
        path.addLine(to: p(76, 42))
        path.addLine(to: p(74, 78))     // waist
        path.addLine(to: p(70, 110))    // hips
        path.addLine(to: p(30, 110))    // hips
        path.addLine(to: p(26, 78))     // waist
        path.addLine(to: p(24, 42))
        path.closeSubpath()

        // Left arm
        path.move(to: p(28, 30))
        path.addLine(to: p(20, 38))
        path.addLine(to: p(14, 78))
        path.addLine(to: p(10, 110))
        path.addLine(to: p(18, 110))
        path.addLine(to: p(22, 78))
        path.addLine(to: p(28, 42))
        path.closeSubpath()

        // Right arm (mirror)
        path.move(to: p(72, 30))
        path.addLine(to: p(80, 38))
        path.addLine(to: p(86, 78))
        path.addLine(to: p(90, 110))
        path.addLine(to: p(82, 110))
        path.addLine(to: p(78, 78))
        path.addLine(to: p(72, 42))
        path.closeSubpath()

        // Hips/glute area (slight bump on back view)
        if view == .back {
            path.addEllipse(in: CGRect(
                x: w * 0.30, y: h * 0.46,
                width: w * 0.40, height: h * 0.10
            ))
        }

        // Left leg
        path.move(to: p(30, 110))
        path.addLine(to: p(46, 110))
        path.addLine(to: p(45, 220))
        path.addLine(to: p(34, 220))
        path.closeSubpath()

        // Right leg
        path.move(to: p(54, 110))
        path.addLine(to: p(70, 110))
        path.addLine(to: p(66, 220))
        path.addLine(to: p(55, 220))
        path.closeSubpath()

        return path
    }
}

// MARK: - Pin site sheet

/// Detail sheet that appears when the user taps a hotspot in
/// `AnatomicalBodyView`. Shows the full technique markdown and lets the user
/// jump back to the compound's pinning protocol.
struct PinSiteSheet: View {
    let site: PinSite
    var onUseSite: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    techniqueCard
                    if let advice = site.rotationAdvice {
                        infoCard(title: "Rotation", icon: "arrow.triangle.2.circlepath", text: advice)
                    }
                    needleCard
                    if onUseSite != nil {
                        Button {
                            onUseSite?()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Use this site")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appAccent)
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle(site.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 10) {
            Image(systemName: site.route == .subq ? "drop.fill" : "syringe.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(site.route.label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)
                Text("\(site.region.rawValue.capitalized)\(site.side.map { " · " + $0.rawValue.capitalized } ?? "")")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextTertiary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 0.5))
    }

    private var techniqueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TECHNIQUE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.appTextMeta)
                .kerning(1.1)
            Text(.init(site.techniqueMd))
                .font(.system(size: 13))
                .foregroundColor(Color.appTextSecondary)
                .lineSpacing(4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 0.5))
    }

    private var needleCard: some View {
        HStack(spacing: 14) {
            if let g = site.needleGauge {
                stat(label: "Needle", value: g)
            }
            if let l = site.needleLength {
                stat(label: "Length", value: l)
            }
            stat(label: "Pinch", value: site.pinchRequired ? "Yes" : "No")
        }
    }

    private func infoCard(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundColor(Color.appAccent)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.appTextMeta)
                    .kerning(1.1)
            }
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.appTextSecondary)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCard)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 0.5))
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.appTextMeta)
                .kerning(0.7)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color.appTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.appInputBackground)
        .cornerRadius(10)
    }
}

#if DEBUG
#Preview("Body view") {
    let sites = PinSiteCatalog.all
    return AnatomicalBodyView(
        sites: sites,
        highlightSiteIds: ["abdomen-subq-left", "thigh-subq-right"],
        onSelect: { _ in }
    )
    .padding()
    .background(Color.appBackground)
}
#endif
