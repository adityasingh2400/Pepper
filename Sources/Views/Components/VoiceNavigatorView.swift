import SwiftUI

/// Floating overlay that lets the user say "open BPC" / "go to today" /
/// "calculate dose for tirzepatide" and have the app navigate instantly.
///
/// Visuals:
///   - Dim background
///   - Centered card with a fat mic, live transcript, and a recently-detected
///     intent badge so the user gets feedback while talking.
///   - Auto-dismisses ~1.2 s after a successful navigation, after the TTS
///     confirmation finishes.
struct VoiceNavigatorView: View {
    @EnvironmentObject private var nav: NavigationCoordinator
    @StateObject private var voice = VoiceRecognitionService()
    @ObservedObject private var tts = ElevenLabsTTSService.shared

    @Environment(\.dismiss) private var dismiss
    @State private var lastIntent: VoiceIntent?
    @State private var ringPulse = false
    @State private var ttsId = UUID()

    var body: some View {
        ZStack {
            // Soft animated radial backdrop so the user feels the focus shift.
            backgroundLayer

            VStack(spacing: 16) {
                Spacer()
                card
                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 24)

            // Top-right cancel chip
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .black))
                            Text("Close")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(Color.white.opacity(0.18))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                Spacer()
            }
        }
        .task {
            await voice.start(contextualStrings: navigationVocabulary())
            ringPulse = true
        }
        .onDisappear {
            voice.stop()
            tts.stop()
        }
        .onChange(of: voice.transcript) { _, newValue in
            handleTranscript(newValue)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            // Subtle accent radial bloom that breathes with the audio level
            RadialGradient(
                colors: [Color.appAccent.opacity(0.35), .clear],
                center: .center,
                startRadius: 50,
                endRadius: 360
            )
            .ignoresSafeArea()
            .scaleEffect(0.85 + CGFloat(voice.audioLevel) * 0.4)
            .animation(.easeOut(duration: 0.18), value: voice.audioLevel)
            .opacity(voice.isListening ? 0.9 : 0.4)
        }
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 18) {
            micButton

            VStack(spacing: 6) {
                Text(headline)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                if let badge = intentBadge {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.appAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.appAccentTint))
                }
                if !voice.transcript.isEmpty {
                    Text("\u{201C}" + voice.transcript + "\u{201D}")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .lineLimit(3)
                }
                if let err = voice.state.errorMessage {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.orange)
                }
            }

            Text("Try \u{201C}open Tirzepatide,\u{201D} \u{201C}calculator for BPC,\u{201D} or \u{201C}log a dose.\u{201D}")
                .font(.system(size: 11))
                .foregroundColor(Color.appTextTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.appCard)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.appBorder, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
    }

    private var micButton: some View {
        ZStack {
            Circle()
                .stroke(Color.appAccent.opacity(0.45), lineWidth: 2)
                .frame(width: ringPulse ? 130 : 96, height: ringPulse ? 130 : 96)
                .opacity(ringPulse ? 0 : 0.8)
                .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: ringPulse)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appAccent, Color.appAccent.opacity(0.7)],
                        center: .center,
                        startRadius: 0, endRadius: 60
                    )
                )
                .frame(width: 96, height: 96)
                .scaleEffect(voice.isListening ? 1 + CGFloat(voice.audioLevel) * 0.18 : 1)
                .animation(.easeOut(duration: 0.12), value: voice.audioLevel)
                .shadow(color: Color.appAccent.opacity(0.6), radius: 18, y: 6)

            Image(systemName: voice.isListening ? "waveform" : "mic.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var headline: String {
        if tts.playingId != nil { return "On it." }
        if voice.isListening { return voice.transcript.isEmpty ? "I'm listening." : "Got it." }
        if let msg = voice.state.errorMessage { return msg }
        return "Tap the mic and tell me where to go."
    }

    private var intentBadge: String? {
        guard let intent = lastIntent else { return nil }
        switch intent {
        case .openTab(let tab):                   return "→ \(tab.title)"
        case .openCompound(let c):                return "→ \(c.name)"
        case .openDosingCalculator(let c):        return "→ Calculator · \(c.name)"
        case .openPinningProtocol(let c):         return "→ Pinning · \(c.name)"
        case .logDose:                            return "→ Quick-log dose"
        case .askPepper:                          return "→ Ask Pepper"
        case .unknown:                            return nil
        }
    }

    // MARK: - Transcript handler

    private func handleTranscript(_ transcript: String) {
        let intent = VoiceIntent.detect(in: transcript)
        // Don't keep firing on the same intent
        if intent == lastIntent { return }

        switch intent {
        case .unknown:
            return
        default:
            break
        }

        lastIntent = intent
        voice.stop()
        ttsId = UUID()
        tts.toggle(intent.spokenConfirmation, id: ttsId)

        // Slight delay so the user sees confirmation, then route + dismiss.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            execute(intent)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                dismiss()
            }
        }
    }

    private func execute(_ intent: VoiceIntent) {
        switch intent {
        case .openTab(let tab):
            nav.switchTab(tab)
        case .openCompound(let compound):
            nav.openCompound(compound)
        case .openDosingCalculator(let compound):
            nav.openCompound(compound)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                nav.presentDosingCalculator(for: compound)
            }
        case .openPinningProtocol(let compound):
            nav.openCompound(compound)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                nav.presentPinningProtocol(for: compound)
            }
        case .logDose:
            nav.presentQuickDoseLog()
        case .askPepper(let prompt):
            nav.presentPepper()
            // Drop the prompt into AskPepper via NotificationCenter so the
            // existing assistant view can pick it up.
            NotificationCenter.default.post(
                name: .pepperSeedPrompt,
                object: nil,
                userInfo: ["prompt": prompt]
            )
        case .unknown:
            break
        }
    }

    private func navigationVocabulary() -> [String] {
        var v = CompoundCatalog.speechVocabulary
        v.append(contentsOf: [
            "Today", "Food", "Protocol", "Track", "Research",
            "open", "go to", "show me", "calculator", "calculate",
            "pinning protocol", "log a dose", "log dose",
            "ask pepper", "where do I inject"
        ])
        return v
    }
}

extension Notification.Name {
    static let pepperSeedPrompt = Notification.Name("pepper.seedPrompt")
}

/// Floating mic that summons the voice navigator. Sits next to the Pepper
/// bubble in `MainTabView`. Smaller than the Pepper bubble on purpose — it's
/// a secondary action, so the visual weight tilts toward "ask Pepper".
struct FloatingMicButton: View {
    @EnvironmentObject private var nav: NavigationCoordinator
    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { pressed = false }
                nav.presentVoiceNavigator()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appCard, Color.appCard.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.18), radius: pressed ? 3 : 10, y: pressed ? 1 : 4)
                    .overlay(
                        Circle().stroke(Color.appBorder.opacity(0.8), lineWidth: 0.5)
                    )
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appAccent)
            }
            .scaleEffect(pressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Voice navigator")
        .accessibilityHint("Tap and speak to navigate the app, e.g. open BPC-157")
    }
}
