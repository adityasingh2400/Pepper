import SwiftUI

/// "What dose should I take?" sheet for a compound.
///
/// Inputs: bodyweight (kg or lb), vial size, BAC water volume.
/// Outputs:
///   - the recommended dose in mcg (and how it was computed),
///   - the syringe draw in units + mL,
///   - a "Why this dose" explanation that shows the formula and inputs,
///   - a "Show on syringe" diagram for confidence.
///
/// All math runs through `DosingFormula.evaluate(...)` (compound default) and
/// `SyringeMath.draw(...)`. If the compound has no formula we default to the
/// midpoint of its dosing range.
struct DosingCalculatorView: View {
    let compound: Compound

    @Environment(\.dismiss) private var dismiss

    @State private var weightUnit: WeightUnit = .kg
    @State private var weightValue: Double = 80     // sensible default
    @State private var vialMg: Double
    @State private var bacWaterMl: Double
    @State private var showWhyThisDose = false

    enum WeightUnit: String, CaseIterable, Identifiable {
        case kg, lb
        var id: String { rawValue }
        var label: String { rawValue.uppercased() }
    }

    init(compound: Compound) {
        self.compound = compound
        _vialMg = State(initialValue: compound.suggestedVialMg)
        _bacWaterMl = State(initialValue: compound.bacWaterMlDefault ?? 2.0)
    }

    private var weightKg: Double {
        weightUnit == .kg ? weightValue : weightValue * 0.4535924
    }

    private var computedDoseMcg: Double {
        if let formula = compound.dosingFormula {
            let f = DosingFormula(expression: formula)
            let inputs = DosingFormula.Inputs(weightKg: weightKg)
            if let result = try? f.evaluate(with: inputs) {
                return clampToRange(result)
            }
        }
        // Fallback: midpoint of dosing range
        let low  = compound.dosingRangeLowMcg  ?? 100
        let high = compound.dosingRangeHighMcg ?? Swift.max(low, 500)
        return (low + high) / 2
    }

    private func clampToRange(_ value: Double) -> Double {
        let low  = compound.dosingRangeLowMcg
        let high = compound.dosingRangeHighMcg
        var v = value
        if let low  { v = Swift.max(v, low) }
        if let high { v = Swift.min(v, high) }
        return v
    }

    private var concentration: Double {
        guard bacWaterMl > 0 else { return 0 }
        return (vialMg * 1_000) / (bacWaterMl * 100)  // mcg per unit
    }

    private var draw: SyringeMath.Draw {
        SyringeMath.draw(mcg: computedDoseMcg, mcgPerUnit: concentration)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    weightCard
                    vialCard
                    doseCard
                    syringeCard
                    Button {
                        showWhyThisDose = true
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("Why this dose?")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appAccent)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Dosing Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showWhyThisDose) {
                WhyThisDoseSheet(
                    compound: compound,
                    weightKg: weightKg,
                    computedDoseMcg: computedDoseMcg,
                    concentration: concentration,
                    draw: draw
                )
            }
        }
    }

    // MARK: - Cards

    private var weightCard: some View {
        sectionCard(title: "Bodyweight", systemImage: "figure.stand") {
            VStack(spacing: 14) {
                HStack {
                    Text(formatNumber(weightValue))
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                    Text(weightUnit.label.lowercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.appTextTertiary)
                    Spacer()
                    Picker("Unit", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases) { u in
                            Text(u.label).tag(u)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 110)
                }

                Slider(
                    value: $weightValue,
                    in: weightUnit == .kg ? 35...200 : 80...440,
                    step: 1
                )
                .tint(Color.appAccent)
            }
        }
    }

    private var vialCard: some View {
        sectionCard(title: "Vial", systemImage: "drop.fill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Total mg")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.appTextSecondary)
                    Spacer()
                    Stepper(value: $vialMg, in: 1...30, step: 1) {
                        Text("\(formatNumber(vialMg)) mg")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.appTextPrimary)
                    }
                    .labelsHidden()
                    Text("\(formatNumber(vialMg)) mg")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .monospacedDigit()
                }
                HStack {
                    Text("BAC water")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.appTextSecondary)
                    Spacer()
                    Stepper(value: $bacWaterMl, in: 0.5...10, step: 0.5) {
                        Text("\(String(format: "%.1f", bacWaterMl)) mL")
                    }
                    .labelsHidden()
                    Text("\(String(format: "%.1f", bacWaterMl)) mL")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appTextPrimary)
                        .monospacedDigit()
                }
                Divider().overlay(Color.appDivider)
                HStack {
                    Text("Concentration")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.appTextTertiary)
                    Spacer()
                    Text("\(String(format: "%.0f", concentration)) mcg / unit")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appAccent)
                        .monospacedDigit()
                }
            }
        }
    }

    private var doseCard: some View {
        sectionCard(title: "Recommended dose", systemImage: "function") {
            HStack(alignment: .firstTextBaseline) {
                Text(formatNumber(computedDoseMcg.rounded()))
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(Color.appAccent)
                    .monospacedDigit()
                Text(compound.dosingUnit ?? "mcg")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.appTextTertiary)
                Spacer()
                if let freq = compound.dosingFrequency {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Schedule")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.appTextMeta)
                            .kerning(0.7)
                        Text(freq.capitalized)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.appTextSecondary)
                    }
                }
            }
        }
    }

    private var syringeCard: some View {
        sectionCard(title: "Draw on insulin syringe", systemImage: "syringe.fill") {
            VStack(spacing: 14) {
                SyringeDiagramView(unitsToDraw: draw.unitsRounded, maxUnits: 100, accent: Color.appAccent)
                    .frame(height: 56)
                HStack(spacing: 16) {
                    statTile(label: "Units", value: draw.unitsLabel)
                    statTile(label: "Volume", value: String(format: "%.2f mL", draw.mL))
                }
                if draw.isOutOfRange {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(draw.unitsRounded > 100
                             ? "Draw exceeds 100 units. Add more BAC water or split into two injections."
                             : "Draw is below 1 unit — too small to measure on a 100u syringe. Reduce BAC water for a more concentrated mix.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
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
                .font(.system(size: 18, weight: .bold, design: .rounded))
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

// MARK: - Syringe diagram

/// Lightweight visual of a 100-unit insulin syringe with a fill indicator
/// at `unitsToDraw / maxUnits`. No image asset required.
struct SyringeDiagramView: View {
    let unitsToDraw: Double
    let maxUnits: Double
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let width  = geo.size.width
            let height = geo.size.height
            let barrelWidth = width - 48        // leave room for plunger + needle
            let pct = Swift.max(0, Swift.min(1, unitsToDraw / maxUnits))
            let fillWidth = barrelWidth * pct

            ZStack(alignment: .leading) {
                // Plunger (left)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.appTextTertiary.opacity(0.6))
                    .frame(width: 14, height: height * 0.7)
                    .offset(x: 0)

                // Barrel
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.appCardElevated)
                    .frame(width: barrelWidth, height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .offset(x: 16)

                // Tick marks every 10 units
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.appTextMeta.opacity(0.5))
                            .frame(width: 1, height: height * 0.45)
                    }
                    Spacer()
                }
                .frame(width: barrelWidth, height: height)
                .offset(x: 16)

                // Liquid fill
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.4), accent.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: height * 0.7)
                    .offset(x: 16)

                // Needle (right tip)
                Path { p in
                    p.move(to: CGPoint(x: 16 + barrelWidth, y: height / 2))
                    p.addLine(to: CGPoint(x: width, y: height / 2))
                }
                .stroke(Color.appTextSecondary, lineWidth: 2)

                // Units label floating above the fill
                Text("\(formatUnits(unitsToDraw))u")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(accent)
                    )
                    .offset(x: 16 + Swift.max(0, fillWidth - 28), y: -height / 2 + 4)
            }
        }
    }

    private func formatUnits(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

// MARK: - Why this dose

struct WhyThisDoseSheet: View {
    let compound: Compound
    let weightKg: Double
    let computedDoseMcg: Double
    let concentration: Double
    let draw: SyringeMath.Draw

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    explainer(
                        icon: "function",
                        title: "Formula",
                        body: compound.dosingFormula
                            ?? "No published per-weight formula. We default to the midpoint of the labelled dosing range."
                    )

                    explainer(
                        icon: "person.fill",
                        title: "Your inputs",
                        body: "Bodyweight: \(String(format: "%.0f", weightKg)) kg"
                    )

                    explainer(
                        icon: "equal",
                        title: "Result",
                        body: "Recommended dose: **\(String(format: "%.0f", computedDoseMcg)) mcg**\n"
                            + "Concentration: **\(String(format: "%.0f", concentration)) mcg / unit**\n"
                            + "Draw: **\(draw.unitsLabel)** (\(String(format: "%.2f", draw.mL)) mL)"
                    )

                    if let low = compound.dosingRangeLowMcg, let high = compound.dosingRangeHighMcg {
                        explainer(
                            icon: "ruler",
                            title: "Safety guard",
                            body: "Result is clamped into the published range \(Int(low))–\(Int(high)) mcg per dose."
                        )
                    }

                    Text("This is not medical advice. The Pepper team curated these formulas from peer-reviewed sources, but you are responsible for verifying any dose with a clinician.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.appTextMeta)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Why this dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func explainer(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(Color.appAccent)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.1)
                    .foregroundColor(Color.appTextMeta)
            }
            Text(.init(body))
                .font(.system(size: 14))
                .foregroundColor(Color.appTextPrimary)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
    }
}
