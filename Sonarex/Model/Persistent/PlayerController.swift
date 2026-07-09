import AVFoundation
import Foundation
import MediaPlayer
import Observation
import UIKit

/// Wiederholungsmodus des Players; die Reihenfolge entspricht der UI-Umschaltung.
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

/// Steuert Streaming, Queue, Remote Commands und Now-Playing-Informationen.
@MainActor
@Observable
final class PlayerController {
    @ObservationIgnored private var audioPlayer: AVPlayer?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: (any NSObjectProtocol)?
    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var playerItemStatusObservation: NSKeyValueObservation?
    @ObservationIgnored private var playerStatusObservation: NSKeyValueObservation?
    @ObservationIgnored private var continuationQueue: [Track] = []

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

    init() {
        // Audio-Session und Sperrbildschirmsteuerung werden einmal zentral vorbereitet.
        configureAudioSession()
        configureRemoteCommands()
    }

    var progress: Double {
        guard let currentTrack, currentTrack.duration > 0 else { return 0 }
        return min(max(elapsedTime / Double(currentTrack.duration), 0), 1)
    }

    var continuationPreviewTracks: [Track] {
        Array(continuationQueue.prefix(4))
    }

    func play(_ track: Track, in tracks: [Track] = []) {
        // Jeder neue Start ersetzt Queue-Status, setzt Statistikdaten und startet danach den Stream.
        configureAudioSession()
        queue = tracks.isEmpty ? [track] : tracks
        currentIndex = queue.firstIndex { $0.id == track.id } ?? 0
        currentTrack = track
        elapsedTime = 0
        isPlaying = false
        playbackError = nil
        if continuationQueue.contains(where: { $0.id == track.id }) {
            continuationQueue.removeAll { $0.id == track.id }
        } else {
            continuationQueue = []
        }
        refreshContinuationQueue()
        track.lastPlayedAt = .now
        track.playCount += 1
        updateNowPlayingInfo(for: track, playbackRate: 0)
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
        updatePlaybackRate()
    }

    func seek(to progress: Double) {
        guard let currentTrack else { return }
        let seconds = Double(currentTrack.duration) * min(max(progress, 0), 1)
        elapsedTime = seconds
        audioPlayer?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        updateNowPlayingElapsedTime()
    }

    func playNext() {
        guard !queue.isEmpty, let currentIndex else { return }
        let next = currentIndex + 1
        if queue.indices.contains(next) {
            play(queue[next], in: queue)
        } else if repeatMode == .all {
            play(queue[0], in: queue)
        } else if let continuationTrack = nextContinuationTrack() {
            queue.append(continuationTrack)
            play(continuationTrack, in: queue)
        } else {
            isPlaying = false
            audioPlayer?.pause()
            updatePlaybackRate()
        }
    }

    func playPrevious() {
        guard !queue.isEmpty, let currentIndex else { return }
        if elapsedTime > 5 {
            elapsedTime = 0
            audioPlayer?.seek(to: .zero)
            updateNowPlayingElapsedTime()
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
        continuationQueue = []
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func continuationPreview(limit: Int = 4) -> [Track] {
        refreshContinuationQueue(minimumCount: limit)
        return Array(continuationQueue.prefix(limit))
    }

    func playContinuation(_ track: Track) {
        if !queue.contains(where: { $0.id == track.id }) {
            queue.append(track)
        }
        play(track, in: queue)
    }

    private func startStreaming(_ track: Track) {
        playbackTask?.cancel()
        // URL-Erstellung und AVPlayer-Setup laufen asynchron, damit die SwiftUI-Oberflaeche reaktionsfaehig bleibt.
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
                updateNowPlayingInfo(for: track, playbackRate: 0)
            } catch {
                guard !Task.isCancelled else { return }
                playbackError = error.localizedDescription
                isPlaying = false
                updatePlaybackRate()
            }
        }
    }

    private func nextContinuationTrack() -> Track? {
        refreshContinuationQueue(minimumCount: 1)
        return continuationQueue.first
    }

    private func refreshContinuationQueue(minimumCount: Int = 6) {
        guard continuationQueue.count < minimumCount else { return }
        let existingIDs = Set((queue + continuationQueue).map(\.id))
        // Erst werden passende Songs aus Playlists gesucht, danach faellt die App auf die Bibliothek zurueck.
        let playlistCandidates = randomizedPlaylistCandidates(excluding: existingIDs)

        for track in playlistCandidates where continuationQueue.count < minimumCount {
            continuationQueue.append(track)
        }

        if continuationQueue.count < minimumCount {
            let fallbackCandidates = shuffledLibraryCandidates(excluding: Set((queue + continuationQueue).map(\.id)))
            for track in fallbackCandidates where continuationQueue.count < minimumCount {
                continuationQueue.append(track)
            }
        }
    }

    private func randomizedPlaylistCandidates(excluding existingIDs: Set<UUID>) -> [Track] {
        guard let playlists = currentTrack?.server?.playlists else { return [] }

        return playlists
            .shuffled()
            .compactMap { playlist in
                playlist.tracks
                    .filter { !existingIDs.contains($0.id) }
                    .randomElement()
            }
    }

    private func shuffledLibraryCandidates(excluding existingIDs: Set<UUID>) -> [Track] {
        guard let tracks = currentTrack?.server?.tracks else { return [] }
        return tracks
            .filter { !existingIDs.contains($0.id) }
            .shuffled()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Playback erlaubt Musik auch bei gesperrtem Bildschirm und ueber System-Remote-Controls.
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            playbackError = error.localizedDescription
        }
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Alte Targets werden entfernt, damit bei mehrfacher Initialisierung keine Befehle doppelt feuern.
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
        commandCenter.stopCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.seekForwardCommand.removeTarget(nil)
        commandCenter.seekBackwardCommand.removeTarget(nil)

        commandCenter.stopCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self, self.currentTrack != nil else { return }
                self.isPlaying = true
                self.audioPlayer?.play()
                self.updatePlaybackRate()
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isPlaying = false
                self.audioPlayer?.pause()
                self.updatePlaybackRate()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.togglePlayback()
            }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.playNext()
            }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.playPrevious()
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = false
    }

    private func updateNowPlayingInfo(for track: Track, playbackRate: Double) {
        // Diese Metadaten versorgen Sperrbildschirm, Kontrollzentrum und CarPlay-kompatible Anzeigen.
        let info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: track.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
            MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
            MPNowPlayingInfoPropertyIsLiveStream: false,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = playbackRate > 0 ? .playing : .paused
    }

    private func updatePlaybackRate() {
        guard currentTrack != nil else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1 : 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    private func updateNowPlayingElapsedTime() {
        guard currentTrack != nil else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
    }

    private func streamURL(for track: Track) throws -> URL {
        // Streaming nutzt die gespeicherten Keychain-Zugangsdaten des zugeordneten Servers.
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
                URLQueryItem(name: "id", value: track.remoteID),
                URLQueryItem(name: "format", value: "mp3"),
                URLQueryItem(name: "maxBitRate", value: "320")
            ],
            responseFormat: nil
        )
    }

    private func addPlaybackObservers(for player: AVPlayer, item: AVPlayerItem) {
        // Beobachter synchronisieren AVPlayer-Zustand mit SwiftUI und Now-Playing-Status.
        playerItemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self, weak item] observedItem, _ in
            Task { @MainActor in
                guard let self, let item, self.audioPlayer?.currentItem === item else { return }

                switch observedItem.status {
                case .readyToPlay:
                    self.playbackError = nil
                    self.isPlaying = true
                    if let currentTrack = self.currentTrack {
                        self.updateNowPlayingInfo(for: currentTrack, playbackRate: 1)
                    }
                case .failed:
                    self.playbackError = self.playbackFailureMessage(from: observedItem)
                    self.isPlaying = false
                    self.updatePlaybackRate()
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        playerStatusObservation = player.observe(\.status, options: [.new]) { [weak self, weak player] observedPlayer, _ in
            Task { @MainActor in
                guard let self, let player, self.audioPlayer === player else { return }

                if observedPlayer.status == .failed {
                    self.playbackError = observedPlayer.error?.localizedDescription
                        ?? "Der Stream konnte nicht abgespielt werden."
                    self.isPlaying = false
                    self.updatePlaybackRate()
                }
            }
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.elapsedTime = max(time.seconds, 0)
                self?.updateNowPlayingElapsedTime()
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
        // Observer muessen vor Trackwechseln geloest werden, sonst entstehen doppelte Updates.
        if let timeObserver, let audioPlayer {
            audioPlayer.removeTimeObserver(timeObserver)
        }
        timeObserver = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil

        playerItemStatusObservation?.invalidate()
        playerItemStatusObservation = nil

        playerStatusObservation?.invalidate()
        playerStatusObservation = nil
    }

    private func playbackFailureMessage(from item: AVPlayerItem) -> String {
        if let error = item.error {
            return error.localizedDescription
        }

        if let event = item.errorLog()?.events.last {
            if let comment = event.errorComment, !comment.isEmpty {
                return comment
            }

            if event.errorStatusCode != 0 {
                return "Der Stream konnte nicht abgespielt werden. Navidrome meldet Status \(event.errorStatusCode)."
            }
        }

        return "Der Stream konnte nicht abgespielt werden. Bitte Server, Passwort und Dateiformat pruefen."
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
