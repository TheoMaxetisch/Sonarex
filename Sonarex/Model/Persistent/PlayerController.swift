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
    var currentTrack: Track?
    var queue: [Track] = []
    var currentIndex: Int?
    var isPlaying = false
    var elapsedTime: TimeInterval = 0
    var volume = 0.72
    var repeatMode: RepeatMode = .off
    var isShuffleEnabled = false
    var isPlayerPresented = false

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
        track.lastPlayedAt = .now
        track.playCount += 1
    }

    func play(_ tracks: [Track], startingAt index: Int = 0) {
        guard tracks.indices.contains(index) else { return }
        play(tracks[index], in: tracks)
    }

    func togglePlayback() {
        guard currentTrack != nil else { return }
        isPlaying.toggle()
    }

    func seek(to progress: Double) {
        guard let currentTrack else { return }
        elapsedTime = Double(currentTrack.duration) * min(max(progress, 0), 1)
    }

    func playNext() {
        guard !queue.isEmpty, let currentIndex else { return }
        let next = currentIndex + 1
        if queue.indices.contains(next) {
            play(queue[next], in: queue)
        } else if repeatMode == .all {
            play(queue[0], in: queue)
        }
    }

    func playPrevious() {
        guard !queue.isEmpty, let currentIndex else { return }
        if elapsedTime > 5 {
            elapsedTime = 0
        } else if queue.indices.contains(currentIndex - 1) {
            play(queue[currentIndex - 1], in: queue)
        }
    }

    func stop() {
        currentTrack = nil
        queue = []
        currentIndex = nil
        elapsedTime = 0
        isPlaying = false
        isPlayerPresented = false
    }
}
