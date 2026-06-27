import Foundation
import SwiftData
import Testing
@testable import Sonarex

@MainActor
struct MusicModelTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self,
            configurations: config
        )
    }

    @Test func serverURLValidationAcceptsHTTPAndHTTPSOnly() {
        let validServer = ServerProfile(name: "Home", baseURL: "https://music.example.test")
        let invalidServer = ServerProfile(name: "Broken", baseURL: "ftp://music.example.test")
        let incompleteServer = ServerProfile(name: "Incomplete", baseURL: "music.example.test")

        #expect(validServer.validatedBaseURL?.absoluteString == "https://music.example.test")
        #expect(invalidServer.validatedBaseURL == nil)
        #expect(incompleteServer.validatedBaseURL == nil)
    }

    @Test func trackDurationTextFormatsMinutesAndSeconds() {
        let track = Track(remoteID: "track-1", title: "Test", artist: "Artist", duration: 185)

        #expect(track.durationText == "3:05")
    }

    @Test func playlistOrdersTracksByEntryPosition() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let playlist = Playlist(remoteID: "playlist-1", title: "Ordered")
        let first = Track(remoteID: "first", title: "First", artist: "Artist", duration: 60)
        let second = Track(remoteID: "second", title: "Second", artist: "Artist", duration: 80)

        context.insert(playlist)
        context.insert(first)
        context.insert(second)
        playlist.entries = [
            PlaylistEntry(position: 2, playlist: playlist, track: second),
            PlaylistEntry(position: 1, playlist: playlist, track: first)
        ]
        try context.save()

        #expect(playlist.tracks.map(\.remoteID) == ["first", "second"])
        #expect(playlist.trackCountText == "2 Songs")
        #expect(playlist.totalDurationText == "2:20")
    }

    @Test func playlistRelationshipDeletesEntriesWhenPlaylistIsDeleted() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let playlist = Playlist(remoteID: "playlist-1", title: "Temporary")
        let track = Track(remoteID: "track-1", title: "Track", artist: "Artist", duration: 60)
        let entry = PlaylistEntry(position: 0, playlist: playlist, track: track)

        context.insert(playlist)
        context.insert(track)
        context.insert(entry)
        playlist.entries = [entry]
        try context.save()

        #expect(try context.fetch(FetchDescriptor<PlaylistEntry>()).count == 1)

        context.delete(playlist)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<PlaylistEntry>()).isEmpty)
    }
}

@MainActor
struct DemoMusicSeederTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self,
            configurations: config
        )
    }

    @Test func seedCreatesDemoLibraryOnlyWhenStoreIsEmpty() throws {
        let container = try makeContainer()
        let context = container.mainContext

        try DemoMusicSeeder.seedIfNeeded(in: context)
        try DemoMusicSeeder.seedIfNeeded(in: context)

        let servers = try context.fetch(FetchDescriptor<ServerProfile>())
        let tracks = try context.fetch(FetchDescriptor<Track>())
        let playlists = try context.fetch(FetchDescriptor<Playlist>())

        #expect(servers.count == 1)
        #expect(servers.first?.isDemo == true)
        #expect(tracks.count == 10)
        #expect(playlists.count == 3)
    }

    @Test func seedMarksExistingGoldenHourServerAsDemo() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let server = ServerProfile(name: "Old Demo", baseURL: "https://navidrome.wedel.dev", isActive: true)
        let track = Track(
            remoteID: "golden-hour-static",
            title: "Golden Hour Static",
            artist: "Mara Vale",
            duration: 231,
            server: server
        )

        context.insert(server)
        context.insert(track)
        server.tracks = [track]
        try context.save()

        try DemoMusicSeeder.seedIfNeeded(in: context)

        #expect(server.isDemo == true)
        #expect(try context.fetch(FetchDescriptor<ServerProfile>()).count == 1)
    }
}

struct SubsonicRequestBuilderTests {
    @Test func urlContainsAuthenticationAndEndpointQueryItems() throws {
        let builder = SubsonicRequestBuilder(
            baseURL: try #require(URL(string: "https://music.example.test")),
            username: "michi",
            password: "secret"
        )

        let url = try builder.url(
            for: "stream",
            queryItems: [
                URLQueryItem(name: "id", value: "song-1"),
                URLQueryItem(name: "format", value: "mp3")
            ],
            responseFormat: nil
        )
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })

        #expect(components.path == "/rest/stream.view")
        #expect(queryItems["u"] == "michi")
        #expect(queryItems["v"] == "1.16.1")
        #expect(queryItems["c"] == "Sonarex")
        #expect(queryItems["id"] == "song-1")
        #expect(queryItems["format"] == "mp3")
        #expect(queryItems["f"] == nil)
        #expect(queryItems["s"]?.isEmpty == false)
        #expect(queryItems["t"]?.count == 32)
    }

    @Test func urlAddsJSONFormatByDefault() throws {
        let builder = SubsonicRequestBuilder(
            baseURL: try #require(URL(string: "https://music.example.test")),
            username: "michi",
            password: "secret"
        )

        let url = try builder.url(for: "getGenres")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let format = components.queryItems?.first { $0.name == "f" }?.value

        #expect(format == "json")
    }
}

@MainActor
struct PlayerControllerTests {
    @Test func repeatModeCyclesThroughAllStates() {
        #expect(RepeatMode.off.next == .all)
        #expect(RepeatMode.all.next == .one)
        #expect(RepeatMode.one.next == .off)
    }

    @Test func progressIsClampedBetweenZeroAndOne() {
        let player = PlayerController()
        let track = Track(remoteID: "track-1", title: "Track", artist: "Artist", duration: 100)

        player.currentTrack = track
        player.elapsedTime = 150
        #expect(player.progress == 1)

        player.elapsedTime = -10
        #expect(player.progress == 0)
    }

    @Test func stopClearsPlaybackState() {
        let player = PlayerController()
        let track = Track(remoteID: "track-1", title: "Track", artist: "Artist", duration: 100)

        player.currentTrack = track
        player.queue = [track]
        player.currentIndex = 0
        player.elapsedTime = 42
        player.isPlaying = true
        player.isPlayerPresented = true

        player.stop()

        #expect(player.currentTrack == nil)
        #expect(player.queue.isEmpty)
        #expect(player.currentIndex == nil)
        #expect(player.elapsedTime == 0)
        #expect(player.isPlaying == false)
        #expect(player.isPlayerPresented == false)
    }
}
