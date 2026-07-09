import Foundation
import SwiftData

/// Lokal gespeicherter Song mit Navidrome-ID, Metadaten und UI-/Playback-Zustand.
@Model
final class Track {
    var id: UUID = UUID()
    var remoteID: String = ""
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var duration: Int = 0
    var trackNumber: Int?
    var discNumber: Int?
    var year: Int?
    var genre: String?
    var contentType: String?
    var bitRate: Int?
    var coverArtID: String?
    var isFavorite: Bool = false
    var lastPlayedAt: Date?
    var playCount: Int = 0
    var artworkStyle: Int = 0
    var artworkSymbol: String = "music.note"
    var server: ServerProfile?

    // Playlist-Mitgliedschaften werden ueber PlaylistEntry modelliert, damit Reihenfolgen erhalten bleiben.
    @Relationship(deleteRule: .nullify, inverse: \PlaylistEntry.track)
    var playlistEntries: [PlaylistEntry]? = []

    init(
        id: UUID = UUID(),
        remoteID: String,
        title: String,
        artist: String,
        album: String = "",
        duration: Int,
        artworkStyle: Int = 0,
        artworkSymbol: String = "music.note",
        server: ServerProfile? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkStyle = artworkStyle
        self.artworkSymbol = artworkSymbol
        self.server = server
    }

    var durationText: String {
        // Anzeigeformat fuer kompakte UI-Stellen wie Karten, Player und Listen.
        "\(duration / 60):\(String(format: "%02d", duration % 60))"
    }
}
