import Foundation
import SwiftData

@MainActor
enum NavidromeLibrarySyncService {
    struct Result {
        let albumCount: Int
        let trackCount: Int
    }

    static func sync(server: ServerProfile, password: String, context: ModelContext) async throws -> Result {
        guard let baseURL = server.validatedBaseURL else {
            throw SyncError.invalidServerURL
        }
        guard !server.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SyncError.missingUsername
        }
        guard !password.isEmpty else {
            throw SyncError.missingPassword
        }

        let client = SubsonicClient(baseURL: baseURL, username: server.username, password: password)
        let albumSummaries = try await client.albumList()
        let starredSongIDs = try await client.starredSongIDs()
        let existingPlaylists = server.playlists ?? []
        let existingTracks = server.tracks ?? []
        let savedPlaylistIDs = Set(existingPlaylists.filter(\.isOwnedByUser).map(\.remoteID))

        var importedPlaylists: [Playlist] = []
        var importedTracks: [Track] = []

        for (albumIndex, albumSummary) in albumSummaries.enumerated() {
            let album = try await client.album(id: albumSummary.id)
            let tracks = album.songs.enumerated().map { trackIndex, song in
                Track(
                    remoteID: song.id,
                    title: song.title,
                    artist: song.artist ?? album.artist ?? "Unbekannter Artist",
                    album: song.album ?? album.name,
                    duration: song.duration ?? 0,
                    artworkStyle: (albumIndex + trackIndex) % TrackArtwork.palettes.count,
                    artworkSymbol: "music.note"
                ).configured(from: song)
                .favorited(starredSongIDs.contains(song.id))
            }

            let playlist = Playlist(
                remoteID: album.id,
                title: album.name,
                subtitle: album.artist ?? "\(tracks.count) Songs",
                playlistDescription: album.year.map { "\($0)" } ?? "",
                artworkStyle: albumIndex % TrackArtwork.palettes.count,
                artworkSymbol: "rectangle.stack.fill",
                isOwnedByUser: savedPlaylistIDs.contains(album.id)
            )
            playlist.coverArtID = album.coverArt
            playlist.entries = tracks.enumerated().map { index, track in
                PlaylistEntry(position: index, playlist: playlist, track: track)
            }

            importedTracks.append(contentsOf: tracks)
            importedPlaylists.append(playlist)
        }

        for playlist in existingPlaylists {
            context.delete(playlist)
        }
        for track in existingTracks {
            context.delete(track)
        }

        for track in importedTracks {
            context.insert(track)
            track.server = server
        }
        for playlist in importedPlaylists {
            context.insert(playlist)
            playlist.server = server
            for entry in playlist.entries ?? [] {
                context.insert(entry)
            }
        }

        server.playlists = importedPlaylists
        server.tracks = importedTracks
        try context.save()

        return Result(albumCount: importedPlaylists.count, trackCount: importedTracks.count)
    }
}

private extension Track {
    func configured(from song: SubsonicSong) -> Track {
        trackNumber = song.track
        discNumber = song.discNumber
        year = song.year
        genre = song.genre
        contentType = song.contentType
        bitRate = song.bitRate
        coverArtID = song.coverArt
        return self
    }

    func favorited(_ isFavorite: Bool) -> Track {
        self.isFavorite = isFavorite
        return self
    }
}

private struct SubsonicClient {
    let baseURL: URL
    let username: String
    let password: String

    private var requestBuilder: SubsonicRequestBuilder {
        SubsonicRequestBuilder(baseURL: baseURL, username: username, password: password)
    }

    func albumList() async throws -> [SubsonicAlbumSummary] {
        let response: AlbumListResponse = try await get(
            "getAlbumList2",
            queryItems: [
                URLQueryItem(name: "type", value: "alphabeticalByName"),
                URLQueryItem(name: "size", value: "500")
            ]
        )
        return response.subsonicResponse.albumList2.album
    }

    func album(id: String) async throws -> SubsonicAlbum {
        let response: AlbumResponse = try await get(
            "getAlbum",
            queryItems: [URLQueryItem(name: "id", value: id)]
        )
        return response.subsonicResponse.album
    }

    func starredSongIDs() async throws -> Set<String> {
        let response: StarredResponse = try await get("getStarred2", queryItems: [])
        return Set(response.subsonicResponse.starred2.song.map(\.id))
    }

    private func get<Response: Decodable>(
        _ endpoint: String,
        queryItems endpointQueryItems: [URLQueryItem]
    ) async throws -> Response {
        let url = try requestBuilder.url(for: endpoint, queryItems: endpointQueryItems)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw SyncError.serverUnavailable
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        if let responseEnvelope = decoded as? any SubsonicEnvelopeProviding,
           responseEnvelope.status == "failed" {
            throw SyncError.api(responseEnvelope.errorMessage ?? "Navidrome hat die Anfrage abgelehnt.")
        }
        return decoded
    }
}

private protocol SubsonicEnvelopeProviding {
    var status: String { get }
    var errorMessage: String? { get }
}

private struct AlbumListResponse: Decodable, SubsonicEnvelopeProviding {
    let subsonicResponse: SubsonicAlbumListEnvelope

    var status: String { subsonicResponse.status }
    var errorMessage: String? { subsonicResponse.error?.message }

    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

private struct AlbumResponse: Decodable, SubsonicEnvelopeProviding {
    let subsonicResponse: SubsonicAlbumEnvelope

    var status: String { subsonicResponse.status }
    var errorMessage: String? { subsonicResponse.error?.message }

    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

private struct StarredResponse: Decodable, SubsonicEnvelopeProviding {
    let subsonicResponse: SubsonicStarredEnvelope

    var status: String { subsonicResponse.status }
    var errorMessage: String? { subsonicResponse.error?.message }

    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

private struct SubsonicAlbumListEnvelope: Decodable {
    let status: String
    let albumList2: SubsonicAlbumList
    let error: SubsonicError?
}

private struct SubsonicAlbumEnvelope: Decodable {
    let status: String
    let album: SubsonicAlbum
    let error: SubsonicError?
}

private struct SubsonicStarredEnvelope: Decodable {
    let status: String
    let starred2: SubsonicStarred
    let error: SubsonicError?
}

private struct SubsonicStarred: Decodable {
    let song: [SubsonicStarredSong]

    enum CodingKeys: String, CodingKey {
        case song
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        song = try container.decodeIfPresent([SubsonicStarredSong].self, forKey: .song) ?? []
    }
}

private struct SubsonicStarredSong: Decodable {
    let id: String
}

private struct SubsonicAlbumList: Decodable {
    let album: [SubsonicAlbumSummary]
}

private struct SubsonicAlbumSummary: Decodable {
    let id: String
}

private struct SubsonicAlbum: Decodable {
    let id: String
    let name: String
    let artist: String?
    let year: Int?
    let coverArt: String?
    let songs: [SubsonicSong]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case artist
        case year
        case coverArt
        case songs = "song"
    }
}

private struct SubsonicSong: Decodable {
    let id: String
    let title: String
    let artist: String?
    let album: String?
    let duration: Int?
    let track: Int?
    let discNumber: Int?
    let year: Int?
    let genre: String?
    let contentType: String?
    let bitRate: Int?
    let coverArt: String?
}

private struct SubsonicError: Decodable {
    let message: String
}

private enum SyncError: LocalizedError {
    case invalidServerURL
    case missingUsername
    case missingPassword
    case serverUnavailable
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            "Die Server-URL ist ungueltig. Bitte mit http:// oder https:// eintragen."
        case .missingUsername:
            "Bitte zuerst einen Benutzernamen eintragen."
        case .missingPassword:
            "Bitte zuerst ein Passwort speichern."
        case .serverUnavailable:
            "Navidrome konnte nicht erreicht werden."
        case .api(let message):
            message
        }
    }
}
