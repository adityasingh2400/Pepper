import SwiftUI

struct ResearchListView: View {
    @EnvironmentObject private var nav: NavigationCoordinator

    var body: some View {
        NavigationStack {
            EmbeddedResearchView()
                .navigationTitle("Research")
                .navigationDestination(item: $nav.researchPushedCompound) { compound in
                    CompoundDetailView(compound: compound)
                        .onAppear {
                            Analytics.capture(.compoundViewed, properties: ["compound": compound.name])
                        }
                }
        }
    }
}

struct EmbeddedResearchView: View {
    @State private var compounds: [Compound] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    var filtered: [Compound] {
        if searchText.isEmpty { return compounds }
        return compounds.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.benefits.joined().localizedCaseInsensitiveContains(searchText)
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
            } else if filtered.isEmpty {
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
                        ForEach(filtered) { compound in
                            NavigationLink(destination: CompoundDetailView(compound: compound).onAppear {
                                Analytics.capture(.compoundViewed, properties: ["compound": compound.name])
                            }) {
                                CompoundRowView(compound: compound)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .background(Color.appBackground)
            }
        }
        .navigationTitle("Research")
        .searchable(text: $searchText, prompt: "Search compounds")
        .task { await load() }
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
            compounds = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct CompoundRowView: View {
    let compound: Compound

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
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
                    actionTile(
                        title: "Pinning\nProtocol",
                        systemImage: "drop.triangle.fill",
                        accent: Color(hex: "0f766e")
                    ) {
                        showPinningProtocol = true
                    }
                }

                // Benefits
                if !compound.benefits.isEmpty {
                    InfoSection(title: "Benefits") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(compound.benefits, id: \.self) { benefit in
                                Label(benefit, systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.appTextSecondary)
                            }
                        }
                    }
                }

                // Side effects
                if !compound.sideEffects.isEmpty {
                    InfoSection(title: "Side Effects") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(compound.sideEffects, id: \.self) { effect in
                                Label(effect, systemImage: "info.circle")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.appTextSecondary)
                            }
                        }
                    }
                }

                // Stacking notes
                if let notes = compound.stackingNotes {
                    InfoSection(title: "Stacking Notes") {
                        Text(notes)
                            .font(.system(size: 13))
                            .foregroundColor(Color.appTextSecondary)
                    }
                }

                Text("For educational and research purposes only. Not medical advice.")
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextMeta)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
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
