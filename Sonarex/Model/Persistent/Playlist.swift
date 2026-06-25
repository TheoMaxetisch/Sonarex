import Foundation
import SwiftData

@Model
final class Playlist {
    var id: UUID = UUID()
    var remoteID: String = ""
    var title: String = ""
    var subtitle: String = ""
    var playlistDescription: String = ""
    var coverArtID: String?
    var artworkStyle: Int = 0
    var artworkSymbol: String = "music.note.list"
    var createdAt: Date = Date()
    var changedAt: Date = Date()
    var isOwnedByUser: Bool = true
    var server: ServerProfile?

    @Relationship(deleteRule: .cascade, inverse: \PlaylistEntry.playlist)
    var entries: [PlaylistEntry]? = []

    init(
        id: UUID = UUID(),
        remoteID: String,
        title: String,
        subtitle: String = "",
        playlistDescription: String = "",
        artworkStyle: Int = 0,
        artworkSymbol: String = "music.note.list",
        server: ServerProfile? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.title = title
        self.subtitle = subtitle
        self.playlistDescription = playlistDescription
        self.artworkStyle = artworkStyle
        self.artworkSymbol = artworkSymbol
        self.server = server
    }

    var orderedEntries: [PlaylistEntry] {
        (entries ?? []).sorted { $0.position < $1.position }
    }

    var tracks: [Track] {
        orderedEntries.compactMap(\.track)
    }

    var trackCountText: String {
        "\(tracks.count) Songs"
    }

    var totalDurationText: String {
        let seconds = tracks.reduce(0) { $0 + $1.duration }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
