import SwiftUI

/// Step-by-step pinning protocol for a compound.
///
/// Walks the user through:
///   1. Recommended sites (with technique)
///   2. Reconstitution math (`SyringeMath.suggest`)
///   3. Draw + inject checklist
///   4. Aftercare + rotation
///
/// We surface the first recommended pin site by default but let the user pick
/// any site from the compound's recommendation list. This lives behind the
/// "Pinning Protocol" action tile on `CompoundDetailView`.
struct PinningProtocolView: View {
    let compound: Compound

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSite: PinSite?

    private var recommendations: [(PinSite, Bool)] {
        // (site, isPrimary). The order in `recommendedSiteIds` defines preference.
        compound.recommendedSiteIds.enumerated().compactMap { (idx, id) in
            guard let site = PinSiteCatalog.find(id) else { return nil }
            return (site, idx == 0)
        }
    }

    private var defaultSite: PinSite? {
        selectedSite ?? recommendations.first?.0 ?? PinSiteCatalog.all.first
    }

    private var bacSuggestion: SyringeMath.Suggestion {
        compound.bacSuggestion()
    }

    @State private var presentedSite: PinSite?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    bodyCard
                    sitePickerCard
                    reconstitutionCard
                    if let site = defaultSite {
                        techniqueCard(site: site)
                        aftercareCard(site: site)
                    }
                    safetyCard
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Pinning Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $presentedSite) { site in
                PinSiteSheet(site: site, onUseSite: {
                    selectedSite = site
                })
            }
        }
    }

    private var bodyCard: some View {
        sectionCard(title: "Body map", systemImage: "figure.stand") {
            AnatomicalBodyView(
                sites: PinSiteCatalog.all,
                highlightSiteIds: Set(compound.recommendedSiteIds),
                onSelect: { presentedSite = $0 }
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Cards

    private var sitePickerCard: some View {
        sectionCard(title: "Where to inject", systemImage: "scope") {
            if recommendations.isEmpty {
                Text("This compound doesn't have a curated site list yet. Below is the most common practice for similar peptides.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextTertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recommendations, id: \.0.id) { (site, isPrimary) in
                            sitePill(site: site, isPrimary: isPrimary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            if let site = defaultSite {
                HStack(spacing: 8) {
                    Image(systemName: site.route == .subq ? "drop.fill" : "syringe.fill")
                        .foregroundColor(Color.appAccent)
                    Text(site.route.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.appTextSecondary)
                    Spacer()
                    if let g = site.needleGauge, let l = site.needleLength {
                        Text("\(g) · \(l)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.appTextTertiary)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func sitePill(site: PinSite, isPrimary: Bool) -> some View {
        let isSelected = (defaultSite?.id == site.id)
        return Button {
            selectedSite = site
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(isPrimary ? Color.appAccent : Color.appTextMeta.opacity(0.4))
                    .frame(width: 6, height: 6)
                Text(site.displayName)
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(isSelected ? Color.appAccent : Color.appCardElevated)
            )
            .foregroundColor(isSelected ? .white : Color.appTextPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.appBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var reconstitutionCard: some View {
        sectionCard(title: "Reconstitute", systemImage: "drop.triangle.fill") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(formatNumber(compound.suggestedVialMg)) mg vial")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", bacSuggestion.bacWaterMl)) mL BAC water")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color.appAccent)
                }

                HStack(spacing: 12) {
                    statTile(label: "Concentration", value: "\(Int(bacSuggestion.mcgPerUnit)) mcg/u")
                    statTile(label: "Comfortable", value: bacSuggestion.comfortable ? "Yes" : "Marginal")
                }

                Text(bacSuggestion.rationale)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextTertiary)
                    .lineSpacing(2)
            }
        }
    }

    private func techniqueCard(site: PinSite) -> some View {
        sectionCard(title: "Inject", systemImage: "list.number") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: site.bodyView == .front ? "person.fill" : "person.crop.rectangle.fill")
                        .foregroundColor(Color.appAccent)
                    Text(site.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                    Spacer()
                }
                Text(.init(site.techniqueMd))
                    .font(.system(size: 13))
                    .foregroundColor(Color.appTextSecondary)
                    .lineSpacing(4)
            }
        }
    }

    private func aftercareCard(site: PinSite) -> some View {
        sectionCard(title: "Aftercare", systemImage: "leaf.fill") {
            VStack(alignment: .leading, spacing: 8) {
                Label("Press a clean swab on the site for ~10 seconds. No massage.", systemImage: "checkmark.circle.fill")
                    .labelStyle(checklistStyle())
                if let advice = site.rotationAdvice {
                    Label(advice, systemImage: "arrow.triangle.2.circlepath")
                        .labelStyle(checklistStyle())
                }
                Label("Log this dose in Pepper to keep your rotation map up to date.", systemImage: "square.and.pencil")
                    .labelStyle(checklistStyle())
            }
        }
    }

    private var safetyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(.orange)
                Text("Safety check")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.appTextSecondary)
            }
            Text("Stop and consult a clinician if you develop unexpected swelling, hives, lightheadedness, or chest tightness within minutes of an injection.")
                .font(.system(size: 12))
                .foregroundColor(Color.appTextTertiary)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.18), lineWidth: 0.5)
        )
    }

    // MARK: - Helpers

    private func sectionCard<C: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.1)
                Spacer()
            }
            .foregroundColor(Color.appTextMeta)
            content()
        }
        .padding(16)
        .background(Color.appCard)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.appTextMeta)
                .kerning(0.8)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color.appTextPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.appInputBackground)
        .cornerRadius(12)
    }

    private func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

private struct checklistStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon
                .foregroundColor(Color.appAccent)
                .font(.system(size: 12))
            configuration.title
                .font(.system(size: 13))
                .foregroundColor(Color.appTextSecondary)
        }
    }
}
