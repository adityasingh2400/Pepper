import SwiftUI

/// Multi-select grid of *peptide goals* (recovery, longevity, fat loss, …)
/// shown after the user opts into a peptide protocol during onboarding.
///
/// The selected goal IDs flow back to the picker as recommended compounds.
struct OnboardingGoalsView: View {
    @Binding var selected: Set<String>
    var onContinue: () -> Void
    var onSkip: () -> Void = {}

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(GoalCategoryCatalog.all) { goal in
                        GoalTile(
                            goal: goal,
                            isSelected: selected.contains(goal.id),
                            toggle: { toggle(goal.id) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            Spacer(minLength: 0)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(action: onContinue) {
                    HStack {
                        Text(selected.isEmpty ? "Skip" : "Continue")
                        if !selected.isEmpty {
                            Text("(\(selected.count))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selected.isEmpty ? Color.appTextMeta : Color.appAccent)
                    .cornerRadius(14)
                }
                if !selected.isEmpty {
                    Button(action: onSkip) {
                        Text("Skip — show me everything")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.appTextTertiary)
                    }
                    .padding(.bottom, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What are you optimizing for?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.appTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Pick all that apply. We'll surface the most relevant compounds first.")
                .font(.system(size: 14))
                .foregroundColor(Color.appTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func toggle(_ id: String) {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        if selected.contains(id) { selected.remove(id) }
        else { selected.insert(id) }
    }
}

private struct GoalTile: View {
    let goal: GoalCategory
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: goal.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color.appAccent)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(
                                isSelected
                                    ? Color.white.opacity(0.15)
                                    : Color.appAccentTint
                            )
                        )
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                Text(goal.display)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color.appTextPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(goal.description)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? Color.white.opacity(0.85) : Color.appTextTertiary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background(isSelected ? Color.appAccent : Color.appCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.appAccent : Color.appBorder,
                            lineWidth: isSelected ? 2 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var sel: Set<String> = ["recovery"]
    return OnboardingGoalsView(selected: $sel, onContinue: {})
        .background(Color.appBackground)
}
#endif
