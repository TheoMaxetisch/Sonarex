import AVFoundation
import Foundation
import Observation

enum RepeatMode: String, CaseIterable {
    case off
    case all
    case one

    var symbol: String {
        self == .one ? "repeat.1" : "repeat"
    }

    var next: RepeatMode {
        switch self {
        case .off: .all
        case .all: .one
        case .one: .off
        }
    }
}

@MainActor
@Observable
final class PlayerController {
    @ObservationIgnored private var audioPlayer: AVPlayer?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: (any NSObjectProtocol)?
    @ObservationIgnored private var playbackTask: Task<Void, Never>?

    var currentTrack: Track?
    var queue: [Track] = []
    var currentIndex: Int?
    var isPlaying = false
    var elapsedTime: TimeInterval = 0
    var volume = 0.72 {
        didSet {
            audioPlayer?.volume = Float(volume)
        }
    }
    var repeatMode: RepeatMode = .off
    var isShuffleEnabled = false
    var isPlayerPresented = false
    var playbackError: String?

    var progress: Double {
        guard let currentTrack, currentTrack.duration > 0 else { return 0 }
        return min(max(elapsedTime / Double(currentTrack.duration), 0), 1)
    }

    func play(_ track: Track, in tracks: [Track] = []) {
        queue = tracks.isEmpty ? [track] : tracks
        currentIndex = queue.firstIndex { $0.id == track.id } ?? 0
        currentTrack = track
        elapsedTime = 0
        isPlaying = true
        playbackError = nil
        track.lastPlayedAt = .now
        track.playCount += 1
        startStreaming(track)
    }

    func play(_ tracks: [Track], startingAt index: Int = 0) {
        guard tracks.indices.contains(index) else { return }
        play(tracks[index], in: tracks)
    }

    func togglePlayback() {
        guard currentTrack != nil else { return }
        isPlaying.toggle()
        if isPlaying {
            audioPlayer?.play()
        } else {
            audioPlayer?.pause()
        }
    }

    func seek(to progress: Double) {
        guard let currentTrack else { return }
        let seconds = Double(currentTrack.duration) * min(max(progress, 0), 1)
        elapsedTime = seconds
        audioPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func playNext() {
        guard !queue.isEmpty, let currentIndex else { return }
        let next = currentIndex + 1
        if queue.indices.contains(next) {
            play(queue[next], in: queue)
        } else if repeatMode == .all {
            play(queue[0], in: queue)
        } else {
            isPlaying = false
            audioPlayer?.pause()
        }
    }

    func playPrevious() {
        guard !queue.isEmpty, let currentIndex else { return }
        if elapsedTime > 5 {
            elapsedTime = 0
        } else if queue.indices.contains(currentIndex - 1) {
            play(queue[currentIndex - 1], in: queue)
        } else {
            audioPlayer?.seek(to: .zero)
        }
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        audioPlayer?.pause()
        audioPlayer = nil
        removePlaybackObservers()
        currentTrack = nil
        queue = []
        currentIndex = nil
        elapsedTime = 0
        isPlaying = false
        isPlayerPresented = false
        playbackError = nil
    }

    private func startStreaming(_ track: Track) {
        playbackTask?.cancel()
        playbackTask = Task { [weak self, track] in
            guard let self else { return }
            do {
                let url = try streamURL(for: track)
                guard !Task.isCancelled else { return }

                removePlaybackObservers()
                let playerItem = AVPlayerItem(url: url)
                let player = AVPlayer(playerItem: playerItem)
                player.volume = Float(volume)
                audioPlayer = player
                addPlaybackObservers(for: player, item: playerItem)
                player.play()
                isPlaying = true
            } catch {
                guard !Task.isCancelled else { return }
                playbackError = error.localizedDescription
                isPlaying = false
            }
        }
    }

    private func streamURL(for track: Track) throws -> URL {
        guard let server = track.server,
              let baseURL = server.validatedBaseURL else {
            throw PlaybackError.missingServer
        }
        guard !server.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PlaybackError.missingUsername
        }
        guard let password = try KeychainCredentialStore.password(for: server.id),
              !password.isEmpty else {
            throw PlaybackError.missingPassword
        }

        return try SubsonicRequestBuilder(
            baseURL: baseURL,
            username: server.username,
            password: password
        ).url(
            for: "stream",
            queryItems: [
                URLQueryItem(name: "id", value: track.remoteID)
            ]
        )
    }

    private func addPlaybackObservers(for player: AVPlayer, item: AVPlayerItem) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.elapsedTime = max(time.seconds, 0)
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.repeatMode == .one {
                    self.audioPlayer?.seek(to: .zero)
                    self.audioPlayer?.play()
                    self.elapsedTime = 0
                } else {
                    self.playNext()
                }
            }
        }
    }

    private func removePlaybackObservers() {
        if let timeObserver, let audioPlayer {
            audioPlayer.removeTimeObserver(timeObserver)
        }
        timeObserver = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }
}

private enum PlaybackError: LocalizedError {
    case missingServer
    case missingUsername
    case missingPassword

    var errorDescription: String? {
        switch self {
        case .missingServer:
            "Dieser Song ist keinem Navidrome-Server zugeordnet."
        case .missingUsername:
            "Bitte zuerst einen Benutzernamen in den Server-Einstellungen eintragen."
        case .missingPassword:
            "Bitte zuerst das Navidrome-Passwort in den Server-Einstellungen speichern."
        }
    }
}
