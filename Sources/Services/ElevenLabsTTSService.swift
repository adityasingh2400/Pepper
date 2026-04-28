import AVFoundation
import Foundation

/// Plays Pepper's responses using ElevenLabs TTS.
/// Singleton because only one message should ever be speaking at a time globally.
@MainActor
final class ElevenLabsTTSService: NSObject, ObservableObject {

    static let shared = ElevenLabsTTSService()

    @Published private(set) var playingId: UUID?
    @Published private(set) var loadingId: UUID?
    @Published private(set) var lastError: String?
    /// Live output level while Pepper is speaking (0..1). Driven by
    /// AVAudioPlayer's audio metering. UI can subscribe to animate the
    /// voice-navigator mouth in sync with what Pepper actually says.
    @Published private(set) var playbackLevel: Float = 0

    private var player: AVAudioPlayer?
    private var fetchTask: Task<Void, Never>?
    private var meterTimer: Timer?

    /// In-memory cache so re-tapping a message doesn't refetch the mp3.
    private var audioCache: [UUID: Data] = [:]

    private let session = URLSession(configuration: {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 30
        return c
    }())

    /// Fast-path speak: go straight through the prerecorded-audio disk
    /// cache (which holds the hot-set phrase catalog). Skips the live
    /// network fetch entirely when the phrase has been prewarmed, which
    /// reduces end-to-end voice-nav latency from ~1.0 s → ~50 ms.
    ///
    /// Falls back to the live `toggle(_:id:)` path when the cache misses
    /// and the phrase isn't in the hot set — but even that fallback
    /// persists to disk so the *next* repeat of the same phrase is instant.
    func speak(cachedPhrase text: String, id: UUID) {
        if playingId == id || loadingId == id { stop(); return }
        stop()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        loadingId = id
        lastError = nil

        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let data = try await PrerecordedAudioCache.shared.audio(for: trimmed)
                if Task.isCancelled { return }
                try self.beginPlayback(data: data, id: id)
            } catch {
                self.loadingId = nil
                self.lastError = (error as NSError).localizedDescription
            }
        }
    }

    private override init() { super.init() }

    /// Speak (or toggle off) a message. Tapping the same id while it's playing stops it.
    func toggle(_ text: String, id: UUID) {
        if playingId == id || loadingId == id {
            stop()
            return
        }
        // Switch from one message to another: cancel the current playback.
        stop()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        loadingId = id
        lastError = nil

        fetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let data: Data
                if let cached = audioCache[id] {
                    data = cached
                } else {
                    data = try await fetchAudio(for: trimmed)
                    audioCache[id] = data
                }
                if Task.isCancelled { return }
                try beginPlayback(data: data, id: id)
            } catch {
                loadingId = nil
                lastError = (error as NSError).localizedDescription
            }
        }
    }

    func stop() {
        fetchTask?.cancel()
        fetchTask = nil
        player?.stop()
        player = nil
        loadingId = nil
        playingId = nil
        stopMetering()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Internals

    private func beginPlayback(data: Data, id: UUID) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)

        let p = try AVAudioPlayer(data: data)
        p.delegate = self
        p.isMeteringEnabled = true
        p.prepareToPlay()
        guard p.play() else {
            throw NSError(domain: "ElevenLabsTTS", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Couldn't start audio playback."])
        }
        player = p
        loadingId = nil
        playingId = id
        startMetering()
    }

    private func startMetering() {
        meterTimer?.invalidate()
        // 30 Hz polling is enough for a smooth-looking mouth without
        // flooding the main thread.
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let p = self.player, p.isPlaying else { return }
                p.updateMeters()
                // averagePower returns dBFS (~-160..0). Map to 0..1 with a
                // perceptual curve so quiet speech still moves the mouth.
                let db = p.averagePower(forChannel: 0)
                let normalized = Self.normalize(db: db)
                self.playbackLevel = normalized
            }
        }
        RunLoop.main.add(t, forMode: .common)
        meterTimer = t
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
        playbackLevel = 0
    }

    private static func normalize(db: Float) -> Float {
        // -50 dB floor → 0; 0 dB → 1. Exponential curve so mid-range speech
        // sits around 0.4–0.7 and amplitude peaks push to ~0.9.
        let clamped = max(-50, min(0, db))
        let linear = (clamped + 50) / 50
        return pow(linear, 2.2)
    }

    private func fetchAudio(for text: String) async throws -> Data {
        let voice = APIKeys.elevenLabsVoiceId
        let urlString = "https://api.elevenlabs.io/v1/text-to-speech/\(voice)?output_format=mp3_44100_128"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ElevenLabsTTS", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Bad ElevenLabs URL."])
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        req.setValue(APIKeys.elevenLabs, forHTTPHeaderField: "xi-api-key")

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_turbo_v2_5",            // low-latency model
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.8,
                "style": 0.0,
                "use_speaker_boost": true
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8)?.prefix(200) ?? ""
            throw NSError(
                domain: "ElevenLabsTTS",
                code: (resp as? HTTPURLResponse)?.statusCode ?? -3,
                userInfo: [NSLocalizedDescriptionKey: "ElevenLabs error: \(snippet)"]
            )
        }
        return data
    }
}

// MARK: - AVAudioPlayerDelegate

extension ElevenLabsTTSService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in self?.stop() }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let msg = error?.localizedDescription ?? "Audio decode error"
        Task { @MainActor [weak self] in
            self?.lastError = msg
            self?.stop()
        }
    }
}
