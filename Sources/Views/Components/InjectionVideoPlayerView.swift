import Foundation
import AVKit
import SwiftUI

/// Maps an injection site's `videoSlug` (declared on `PinSite`) to a
/// remote URL hosted in Supabase Storage. The canonical layout is:
///
///     <SUPABASE_URL>/storage/v1/object/public/videos/<slug>.mp4
///
/// Videos are rendered via Veo from prompts in `data/veo_prompts.yaml`
/// and uploaded by `scripts/generate_veo_videos.ts`. Multiple sites
/// can share one slug (e.g. both `abdomen-subq-left` and
/// `abdomen-subq-right` resolve to `subq-abdomen.mp4` — the clip is
/// side-agnostic, the surrounding UI tells the user which side to use).
///
/// We deliberately fetch over HTTPS (not in-bundle) so:
///   * app binary stays small (videos would add 50+ MB),
///   * we can re-run Veo with better prompts without re-shipping
///     the app,
///   * no platform content review issues in the binary.
///
/// On-device we wrap the URL in `AVPlayer`'s caching URL loader
/// (implicit via AVURLAsset) which caches ranged responses once
/// the user has played a clip, so a second view is instant/offline.
enum InjectionVideoCatalog {

    /// The public Supabase Storage base. Override per-environment if
    /// needed by setting `PEPPER_VIDEO_BASE_URL` in Info.plist, but
    /// the default points at the production bucket we upload to.
    static var baseURL: URL {
        if let override = Bundle.main.object(forInfoDictionaryKey: "PEPPER_VIDEO_BASE_URL") as? String,
           let u = URL(string: override) {
            return u
        }
        // Default production bucket — matches the Supabase project used
        // elsewhere (`SupabaseClient.swift`). When `generate_veo_videos.ts`
        // uploads to the `videos` bucket, files land here.
        return URL(string: "https://sgbszuimvqxzqvmgvyrn.supabase.co/storage/v1/object/public/videos")!
    }

    /// Resolve a `PinSite.videoSlug` to a streaming URL. Returns nil
    /// for sites without a slug yet.
    static func url(for slug: String?) -> URL? {
        guard let slug, !slug.isEmpty else { return nil }
        return baseURL.appendingPathComponent("\(slug).mp4")
    }
}

// MARK: - Player view

/// Looping, muted, auto-play video player used at the top of
/// `PinSiteSheet`. Shows a pulsing shimmer while the clip buffers, and
/// a graceful empty state ("Video coming soon") if the slug hasn't
/// been rendered yet.
struct InjectionVideoPlayerView: View {
    let slug: String?
    /// Aspect ratio of the rendered clip — matches the Veo prompt's
    /// `aspect_ratio` field. Defaults to 9:16 since most body-shot
    /// injection clips are portrait.
    var aspectRatio: CGFloat = 9.0 / 16.0
    var cornerRadius: CGFloat = 18

    @State private var player: AVPlayer?
    @State private var playerStatus: PlayerStatus = .loading

    private enum PlayerStatus {
        case loading        // buffering / network
        case ready          // playing
        case missing        // slug == nil or 404
        case failed         // network / decode error
    }

    var body: some View {
        ZStack {
            background

            if let player, playerStatus == .ready {
                VideoPlayerSurface(player: player)
                    .transition(.opacity)
            } else {
                placeholder
                    .transition(.opacity)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.3), value: playerStatus)
        .task(id: slug) { await loadIfNeeded() }
        .onDisappear {
            player?.pause()
        }
    }

    // MARK: Subviews

    private var background: some View {
        // Subtle gradient backdrop that reads as "video placeholder"
        // without feeling like an error state while buffering.
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.10, blue: 0.12),
                Color(red: 0.06, green: 0.06, blue: 0.08),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    @ViewBuilder
    private var placeholder: some View {
        switch playerStatus {
        case .loading:
            VStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.6))
                Text("Loading guide video…")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        case .missing:
            VStack(spacing: 8) {
                Image(systemName: "video.slash")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.35))
                Text("Video coming soon")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text("This site's instructional clip is still in production.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        case .failed:
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.35))
                Text("Couldn’t load video")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Button("Retry") {
                    Task { await loadIfNeeded(force: true) }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "e11d48"))
                .padding(.top, 2)
            }
        case .ready:
            EmptyView()
        }
    }

    // MARK: Loading

    private func loadIfNeeded(force: Bool = false) async {
        if !force && player != nil && playerStatus == .ready { return }

        guard let url = InjectionVideoCatalog.url(for: slug) else {
            playerStatus = .missing
            return
        }

        playerStatus = .loading

        // HEAD-check first so we can show the "coming soon" state
        // without flashing a broken player. The bucket returns 200
        // when the file exists and 404 otherwise; we don't download
        // the body.
        let exists = await headCheck(url: url)
        guard exists else {
            playerStatus = .missing
            return
        }

        // Build the player. AVPlayerItem status observation is more
        // ergonomic than KVO-as-combine for this simple case, so we
        // poll until either ready or failed up to a 10s deadline.
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = true
        p.actionAtItemEnd = .none

        // Loop forever when the clip ends.
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            p.seek(to: .zero)
            p.play()
        }

        self.player = p

        // Wait for the item to report .readyToPlay (or .failed).
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            switch item.status {
            case .readyToPlay:
                playerStatus = .ready
                p.play()
                return
            case .failed:
                playerStatus = .failed
                return
            default:
                break
            }
            try? await Task.sleep(nanoseconds: 150_000_000)   // 150ms
        }
        // Timeout — treat as failed so the user can retry.
        playerStatus = .failed
    }

    private func headCheck(url: URL) async -> Bool {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 4
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - AVPlayerLayer-backed surface
//
// `VideoPlayer` from AVKit exists but draws player chrome (play/pause/
// AirPlay controls) that we don't want for an ambient looping guide
// clip. We drop to a plain AVPlayerLayer wrapper for a chrome-free
// presentation.
private struct VideoPlayerSurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let v = PlayerContainerView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
