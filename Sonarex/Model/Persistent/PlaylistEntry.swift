import Foundation
import SwiftData

/// Verbindungstabelle zwischen Playlist und Track mit stabiler Reihenfolge.
@Model
final class PlaylistEntry {
    var id: UUID = UUID()
    var position: Int = 0
    var addedAt: Date = Date()
    var playlist: Playlist?
    var track: Track?

    init(
        id: UUID = UUID(),
        position: Int,
        addedAt: Date = .now,
        playlist: Playlist? = nil,
        track: Track? = nil
    ) {
        self.id = id
        self.position = position
        self.addedAt = addedAt
        self.playlist = playlist
        self.track = track
    }
}
