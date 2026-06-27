import Foundation
import SwiftData

@MainActor
enum DemoMusicSeeder {
    static func seedIfNeeded(in context: ModelContext) throws {
        try markExistingDemoProfiles(in: context)

        var descriptor = FetchDescriptor<ServerProfile>()
        descriptor.fetchLimit = 1
        guard try context.fetch(descriptor).isEmpty else { return }

        let server = ServerProfile(
            name: "Navidrome",
            baseURL: "https://navidrome.wedel.dev",
            isActive: true,
            isDemo: true
        )

        let tracks = [
            Track(remoteID: "golden-hour-static", title: "Golden Hour Static", artist: "Mara Vale", album: "Late Signal", duration: 231, artworkStyle: 1, artworkSymbol: "waveform.path.ecg", server: server),
            Track(remoteID: "neon-harbor", title: "Neon Harbor", artist: "Toma Reed", album: "City Windows", duration: 198, artworkStyle: 0, artworkSymbol: "waveform", server: server),
            Track(remoteID: "north-line", title: "North Line", artist: "Mara Vale", album: "Late Signal", duration: 242, artworkStyle: 2, artworkSymbol: "music.note", server: server),
            Track(remoteID: "low-lights", title: "Low Lights", artist: "Akari Bloom", album: "City Windows", duration: 176, artworkStyle: 1, artworkSymbol: "sparkles", server: server),
            Track(remoteID: "signal-bloom", title: "Signal Bloom", artist: "June Field", album: "Morning Pulse", duration: 224, artworkStyle: 3, artworkSymbol: "dot.radiowaves.left.and.right", server: server),
            Track(remoteID: "soft-circuit", title: "Soft Circuit", artist: "Nio Atlas", album: "Late Night Coding", duration: 187, artworkStyle: 4, artworkSymbol: "pianokeys", server: server),
            Track(remoteID: "glass-steps", title: "Glass Steps", artist: "Mika Sol", album: "Morning Pulse", duration: 260, artworkStyle: 5, artworkSymbol: "metronome", server: server),
            Track(remoteID: "deep-room", title: "Deep Room", artist: "Elian Park", album: "Late Night Coding", duration: 312, artworkStyle: 6, artworkSymbol: "headphones", server: server),
            Track(remoteID: "quiet-map", title: "Quiet Map", artist: "Sora Lane", album: "Late Night Coding", duration: 219, artworkStyle: 7, artworkSymbol: "moon.stars.fill", server: server),
            Track(remoteID: "paper-skies", title: "Paper Skies", artist: "Noah Vale", album: "Late Night Coding", duration: 256, artworkStyle: 8, artworkSymbol: "cloud.fill", server: server)
        ]

        let playlists = [
            makePlaylist(remoteID: "late-night-coding", title: "Late Night Coding", subtitle: "Fokus, Bass und ruhige Synths", description: "Konzentrierte Tracks fuer lange Sessions, wenn alles etwas leiser und klarer werden soll.", style: 7, symbol: "keyboard", tracks: [tracks[7], tracks[8], tracks[9], tracks[5]], server: server),
            makePlaylist(remoteID: "morning-pulse", title: "Morning Pulse", subtitle: "Helle Tracks fuer den Start", description: "Ein kompakter Mix aus warmen Hooks, schnellen Drums und kleinen Energie-Schueben.", style: 4, symbol: "sun.max.fill", tracks: [tracks[0], tracks[4], tracks[2], tracks[6]], server: server),
            makePlaylist(remoteID: "city-windows", title: "City Windows", subtitle: "Elektronische Pop-Momente", description: "Songs fuer Bewegung: unterwegs, im Zug oder beim Blick aus grossen Fenstern.", style: 0, symbol: "building.2.fill", tracks: [tracks[1], tracks[3], tracks[4], tracks[5]], server: server)
        ]

        server.tracks = tracks
        server.playlists = playlists
        context.insert(server)
        try context.save()
    }

    private static func markExistingDemoProfiles(in context: ModelContext) throws {
        let servers = try context.fetch(FetchDescriptor<ServerProfile>())
        var didUpdate = false

        for server in servers where server.tracks?.contains(where: { $0.remoteID == "golden-hour-static" }) == true {
            if !server.isDemo {
                server.isDemo = true
                didUpdate = true
            }
        }

        if didUpdate {
            try context.save()
        }
    }

    private static func makePlaylist(
        remoteID: String,
        title: String,
        subtitle: String,
        description: String,
        style: Int,
        symbol: String,
        tracks: [Track],
        server: ServerProfile
    ) -> Playlist {
        let playlist = Playlist(remoteID: remoteID, title: title, subtitle: subtitle, playlistDescription: description, artworkStyle: style, artworkSymbol: symbol, server: server)
        playlist.entries = tracks.enumerated().map { index, track in
            PlaylistEntry(position: index, playlist: playlist, track: track)
        }
        return playlist
    }
}
