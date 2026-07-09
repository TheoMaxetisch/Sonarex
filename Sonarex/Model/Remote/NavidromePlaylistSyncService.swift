import Foundation

/// Synchronisiert erstellte Playlists und Aenderungen direkt mit Navidrome.
@MainActor
enum NavidromePlaylistSyncService {
    struct RemotePlaylist {
        let id: String
        let name: String
    }

    static func createPlaylist(named name: String, containing track: Track) async throws -> RemotePlaylist {
        // Navidrome erstellt die Playlist serverseitig und liefert die Remote-ID zurueck.
        guard let server = track.server else {
            throw PlaylistSyncError.missingServer
        }
        let decoded: PlaylistSyncResponse = try await request(
            endpoint: "createPlaylist",
            server: server,
            queryItems: [
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "songId", value: track.remoteID)
            ]
        )

        if let playlist = decoded.subsonicResponse.playlist {
            return RemotePlaylist(id: playlist.id, name: playlist.name ?? name)
        }

        throw PlaylistSyncError.api("Navidrome hat keine Playlist-ID zurueckgegeben.")
    }

    static func add(_ track: Track, to playlist: Playlist) async throws {
        guard let server = track.server ?? playlist.server else {
            throw PlaylistSyncError.missingServer
        }
        guard playlist.isEditableByUser else {
            throw PlaylistSyncError.notEditable
        }

        let decoded: PlaylistSyncResponse = try await request(
            endpoint: "updatePlaylist",
            server: server,
            queryItems: [
                URLQueryItem(name: "playlistId", value: playlist.remoteID),
                URLQueryItem(name: "songIdToAdd", value: track.remoteID)
            ]
        )

        guard decoded.subsonicResponse.status != "failed" else {
            throw PlaylistSyncError.api(
                decoded.subsonicResponse.error?.message
                    ?? "Navidrome hat die Playlist-Aenderung abgelehnt."
            )
        }
    }

    static func remove(_ entry: PlaylistEntry, from playlist: Playlist) async throws {
        guard let server = playlist.server ?? entry.track?.server else {
            throw PlaylistSyncError.missingServer
        }
        guard playlist.isEditableByUser else {
            throw PlaylistSyncError.notEditable
        }
        guard let index = playlist.orderedEntries.firstIndex(where: { $0.id == entry.id }) else {
            throw PlaylistSyncError.missingEntry
        }

        // Subsonic entfernt Songs ueber den Index innerhalb der Playlist, nicht ueber die Song-ID.
        let decoded: PlaylistSyncResponse = try await request(
            endpoint: "updatePlaylist",
            server: server,
            queryItems: [
                URLQueryItem(name: "playlistId", value: playlist.remoteID),
                URLQueryItem(name: "songIndexToRemove", value: "\(index)")
            ]
        )

        guard decoded.subsonicResponse.status != "failed" else {
            throw PlaylistSyncError.api(
                decoded.subsonicResponse.error?.message
                    ?? "Navidrome hat die Playlist-Aenderung abgelehnt."
            )
        }
    }

    static func delete(_ playlist: Playlist) async throws {
        guard let server = playlist.server else {
            throw PlaylistSyncError.missingServer
        }
        guard playlist.isEditableByUser else {
            throw PlaylistSyncError.notEditable
        }

        let _: PlaylistSyncResponse = try await request(
            endpoint: "deletePlaylist",
            server: server,
            queryItems: [
                URLQueryItem(name: "id", value: playlist.remoteID)
            ]
        )
    }

    private static func request<Response: Decodable>(
        endpoint: String,
        server: ServerProfile,
        queryItems: [URLQueryItem]
    ) async throws -> Response {
        // Alle Playlist-Requests nutzen dieselbe Keychain-basierte Serverauthentifizierung.
        guard let baseURL = server.validatedBaseURL else {
            throw PlaylistSyncError.invalidServerURL
        }
        guard let password = try KeychainCredentialStore.password(for: server.id), !password.isEmpty else {
            throw PlaylistSyncError.missingPassword
        }

        let requestBuilder = SubsonicRequestBuilder(
            baseURL: baseURL,
            username: server.username,
            password: password
        )
        let url = try requestBuilder.url(for: endpoint, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw PlaylistSyncError.serverUnavailable
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        if let responseEnvelope = decoded as? any PlaylistSyncEnvelopeProviding,
           responseEnvelope.status == "failed" {
            throw PlaylistSyncError.api(responseEnvelope.errorMessage ?? "Navidrome hat die Anfrage abgelehnt.")
        }
        return decoded
    }
}

private protocol PlaylistSyncEnvelopeProviding {
    var status: String { get }
    var errorMessage: String? { get }
}

private struct PlaylistSyncResponse: Decodable, PlaylistSyncEnvelopeProviding {
    let subsonicResponse: PlaylistSyncEnvelope

    var status: String { subsonicResponse.status }
    var errorMessage: String? { subsonicResponse.error?.message }

    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

private struct PlaylistSyncEnvelope: Decodable {
    let status: String
    let playlist: PlaylistSyncRemotePlaylist?
    let error: PlaylistSyncAPIError?
}

private struct PlaylistSyncRemotePlaylist: Decodable {
    let id: String
    let name: String?
}

private struct PlaylistSyncAPIError: Decodable {
    let message: String
}

private enum PlaylistSyncError: LocalizedError {
    case missingServer
    case invalidServerURL
    case missingPassword
    case serverUnavailable
    case notEditable
    case missingEntry
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingServer:
            "Dieser Song ist keinem Navidrome-Server zugeordnet."
        case .invalidServerURL:
            "Die Server-URL ist ungueltig. Bitte mit http:// oder https:// eintragen."
        case .missingPassword:
            "Bitte zuerst das Navidrome-Passwort in den Server-Einstellungen speichern."
        case .serverUnavailable:
            "Navidrome konnte nicht erreicht werden."
        case .notEditable:
            "Diese Playlist kann nicht bearbeitet werden."
        case .missingEntry:
            "Dieser Song wurde in der Playlist nicht gefunden."
        case .api(let message):
            message
        }
    }
}
