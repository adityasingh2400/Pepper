import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var nav = NavigationCoordinator()
    @Environment(\.modelContext) private var ctx

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $nav.selectedTab) {
                TodayView()
                    .tabItem { Label(NavigationCoordinator.Tab.today.title,
                                     systemImage: NavigationCoordinator.Tab.today.systemImage) }
                    .tag(NavigationCoordinator.Tab.today)

                FoodTabView()
                    .tabItem { Label(NavigationCoordinator.Tab.food.title,
                                     systemImage: NavigationCoordinator.Tab.food.systemImage) }
                    .tag(NavigationCoordinator.Tab.food)

                ProtocolTabView()
                    .tabItem { Label(NavigationCoordinator.Tab.protocol.title,
                                     systemImage: NavigationCoordinator.Tab.protocol.systemImage) }
                    .tag(NavigationCoordinator.Tab.protocol)

                TrackTabView()
                    .tabItem { Label(NavigationCoordinator.Tab.track.title,
                                     systemImage: NavigationCoordinator.Tab.track.systemImage) }
                    .tag(NavigationCoordinator.Tab.track)

                ResearchListView()
                    .tabItem { Label(NavigationCoordinator.Tab.research.title,
                                     systemImage: NavigationCoordinator.Tab.research.systemImage) }
                    .tag(NavigationCoordinator.Tab.research)
            }
            .tint(Color(hex: "9f1239"))
            .task(id: authManager.session?.user.id) {
                guard let userId = authManager.session?.user.id.uuidString else { return }
                await SyncService.shared.bootstrap(userId: userId, context: ctx)
            }
            .environmentObject(nav)

            // Single floating action button.
            //   Tap        → opens AskPepper chat
            //   Long-press → opens voice navigator (with haptic confirmation)
            // One bubble keeps the surface uncluttered and never obscures
            // content unnecessarily, while still exposing the voice mode.
            PepperBubbleButton(
                showPepper: $nav.showPepper,
                onLongPress: { nav.presentVoiceNavigator() }
            )
            .padding(.trailing, 16)
            .padding(.bottom, 96)
            .environmentObject(nav)
        }
        .sheet(isPresented: $nav.showPepper) {
            AskPepperView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(Color.appBackground)
        }
        .fullScreenCover(isPresented: $nav.showVoiceNavigator) {
            VoiceNavigatorView()
                .environmentObject(nav)
                .presentationBackground(.clear)
        }
        .sheet(item: $nav.dosingCalculatorCompound) { compound in
            DosingCalculatorView(compound: compound)
        }
        .sheet(item: $nav.pinningProtocolCompound) { compound in
            PinningProtocolView(compound: compound)
        }
        .onChange(of: nav.showPepper) { _, opened in
            if opened { Analytics.capture(.pepperOpened) }
        }
    }
}

private struct PepperBubbleButton: View {
    @Binding var showPepper: Bool
    /// Triggered when the user holds the bubble. Used to open the voice
    /// navigator. Short tap still opens the chat.
    var onLongPress: (() -> Void)? = nil

    @State private var pulsing = false
    @State private var pressed = false
    @State private var holdProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .fill(Color(hex: "9f1239").opacity(0.22))
                .frame(width: 56, height: 56)
                .scaleEffect(pulsing ? 1.65 : 1.0)
                .opacity(pulsing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.0).repeatForever(autoreverses: false),
                    value: pulsing
                )

            Circle()
                .fill(Color(hex: "9f1239"))
                .frame(width: 56, height: 56)
                .shadow(color: Color(hex: "9f1239").opacity(0.45), radius: pressed ? 6 : 16, x: 0, y: pressed ? 2 : 6)
                .scaleEffect(pressed ? 0.91 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)

            // Long-press progress ring
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(Color.white.opacity(0.95), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: holdProgress)

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .scaleEffect(pressed ? 0.91 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pressed)

            // Tiny voice indicator showing long-press affordance
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "mic.fill")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(Color(hex: "9f1239"))
                        )
                        .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                        .offset(x: 4, y: -2)
                }
                Spacer()
            }
            .frame(width: 56, height: 56)
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.45)
                .onChanged { _ in
                    // Animate the progress ring while held
                    withAnimation(.linear(duration: 0.45)) { holdProgress = 1 }
                }
                .onEnded { _ in
                    holdProgress = 0
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onLongPress?()
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { pressed = false }
                showPepper = true
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pulsing = true }
        }
        .accessibilityLabel("Pepper assistant")
        .accessibilityHint("Tap to chat with Pepper, long-press for voice navigation.")
    }
}
