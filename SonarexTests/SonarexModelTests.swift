import Foundation
import SwiftData
import Testing
@testable import Sonarex

// Die Model-Tests pruefen Kernlogik ohne UI: Persistenz, Formatierung, Auth-URLs und Player-Zustand.
@MainActor
struct MusicModelTests {
    private func makeContainer() throws -> ModelContainer {
        // In-Memory-Container haelt Tests schnell und verhindert Schreibzugriffe auf echte App-Daten.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self,
            configurations: config
        )
    }

    @Test func serverURLValidationAcceptsHTTPAndHTTPSOnly() {
        // Validierung verhindert, dass unbrauchbare URLs in Netzwerkrequests gelangen.
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
        // Reihenfolge ist fachlich wichtig, weil Navidrome beim Entfernen mit Playlist-Indizes arbeitet.
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
        // Prueft die SwiftData-Cascade-Regel fuer PlaylistEntry.
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
        // Demo-Seeding wird isoliert getestet, damit der echte Simulatorzustand keine Rolle spielt.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self,
            configurations: config
        )
    }

    @Test func seedCreatesDemoLibraryOnlyWhenStoreIsEmpty() throws {
        // Mehrfacher Start der App darf keine doppelten Demo-Daten erzeugen.
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
        // Migration fuer aeltere Installationen mit bereits vorhandenen Demo-Daten.
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

@MainActor
struct PremiumAccessControllerTests {
    @Test func trialStartsOnFirstLaunchAndGrantsAccess() {
        // UserDefaults-Suite wird isoliert, damit der Test reproduzierbar bleibt.
        let defaults = isolatedDefaults()
        let premium = PremiumAccessController(defaults: defaults)

        #expect(premium.isTrialActive)
        #expect(premium.hasPremiumAccess)
        #expect(premium.remainingTrialDays <= PremiumAccessController.trialDurationDays)
        #expect(defaults.object(forKey: "premiumTrialStartedAt") as? Date != nil)
    }

    @Test func expiredTrialRequiresPurchase() {
        // Abgelaufene Testphase muss Premium-Aktionen blockieren und die Paywall oeffnen.
        let defaults = isolatedDefaults()
        let expiredStart = Calendar.current.date(byAdding: .day, value: -15, to: .now)!
        defaults.set(expiredStart, forKey: "premiumTrialStartedAt")

        let premium = PremiumAccessController(defaults: defaults)

        #expect(!premium.isTrialActive)
        #expect(!premium.hasPremiumAccess)
        #expect(premium.requirePremium(for: "Songs liken") == false)
        #expect(premium.isPaywallPresented)
    }

    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "SonarexPremiumTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

struct SubsonicRequestBuilderTests {
    @Test func urlContainsAuthenticationAndEndpointQueryItems() throws {
        // Der RequestBuilder kombiniert Authentifizierung und fachliche Query-Parameter.
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
        // JSON ist das Standardformat fuer alle normalen API-Antworten.
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

struct SecurityTests {
    @Test func serverURLValidationRejectsUnsafeOrIncompleteURLs() {
        // Sicherheitsnaher Test fuer erlaubte URL-Schemata und vollstaendige Hosts.
        let validHTTPS = ServerProfile(name: "HTTPS", baseURL: "https://music.example.test")
        let validHTTP = ServerProfile(name: "HTTP", baseURL: "http://localhost:4533")
        let ftpServer = ServerProfile(name: "FTP", baseURL: "ftp://music.example.test")
        let missingScheme = ServerProfile(name: "Missing Scheme", baseURL: "music.example.test")
        let missingHost = ServerProfile(name: "Missing Host", baseURL: "https://")

        #expect(validHTTPS.validatedBaseURL?.scheme == "https")
        #expect(validHTTP.validatedBaseURL?.scheme == "http")
        #expect(ftpServer.validatedBaseURL == nil)
        #expect(missingScheme.validatedBaseURL == nil)
        #expect(missingHost.validatedBaseURL == nil)
    }

    @Test func subsonicAuthenticationURLDoesNotExposePassword() throws {
        // Das Klartextpasswort darf weder als `p`-Parameter noch im String der URL auftauchen.
        let builder = SubsonicRequestBuilder(
            baseURL: try #require(URL(string: "https://music.example.test")),
            username: "michi",
            password: "secret-password"
        )

        let url = try builder.url(for: "ping")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })

        #expect(!url.absoluteString.contains("secret-password"))
        #expect(queryItems["p"] == nil)
        #expect(queryItems["t"]?.isEmpty == false)
        #expect(queryItems["s"]?.isEmpty == false)
        #expect(queryItems["t"]?.count == 32)
    }
}

@MainActor
struct PlayerControllerTests {
    @Test func repeatModeCyclesThroughAllStates() {
        // Die UI schaltet Repeat ueber diese Reihenfolge weiter.
        #expect(RepeatMode.off.next == .all)
        #expect(RepeatMode.all.next == .one)
        #expect(RepeatMode.one.next == .off)
    }

    @Test func progressIsClampedBetweenZeroAndOne() {
        // Progress muss fuer Slider und Mini-Player immer im Bereich 0...1 bleiben.
        let player = PlayerController()
        let track = Track(remoteID: "track-1", title: "Track", artist: "Artist", duration: 100)

        player.currentTrack = track
        player.elapsedTime = 150
        #expect(player.progress == 1)

        player.elapsedTime = -10
        #expect(player.progress == 0)
    }

    @Test func stopClearsPlaybackState() {
        // Stop muss sichtbaren UI-Zustand, Queue und Now-Playing-Status zuruecksetzen.
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
