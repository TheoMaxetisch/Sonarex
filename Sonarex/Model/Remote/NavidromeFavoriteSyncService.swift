import Foundation

@MainActor
enum NavidromeFavoriteSyncService {
    static func setFavorite(_ isFavorite: Bool, for track: Track) async throws {
        guard let server = track.server else {
            throw FavoriteSyncError.missingServer
        }
        guard let baseURL = server.validatedBaseURL else {
            throw FavoriteSyncError.invalidServerURL
        }
        guard let password = try KeychainCredentialStore.password(for: server.id), !password.isEmpty else {
            throw FavoriteSyncError.missingPassword
        }

        let endpoint = isFavorite ? "star" : "unstar"
        let requestBuilder = SubsonicRequestBuilder(
            baseURL: baseURL,
            username: server.username,
            password: password
        )
        let url = try requestBuilder.url(
            for: endpoint,
            queryItems: [URLQueryItem(name: "id", value: track.remoteID)]
        )

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw FavoriteSyncError.serverUnavailable
        }

        let decoded = try JSONDecoder().decode(FavoriteSyncResponse.self, from: data)
        guard decoded.subsonicResponse.status != "failed" else {
            throw FavoriteSyncError.api(
                decoded.subsonicResponse.error?.message
                    ?? "Navidrome hat die Favoriten-Aenderung abgelehnt."
            )
        }
    }
}

private struct FavoriteSyncResponse: Decodable {
    let subsonicResponse: FavoriteSyncEnvelope

    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

private struct FavoriteSyncEnvelope: Decodable {
    let status: String
    let error: FavoriteSyncAPIError?
}

private struct FavoriteSyncAPIError: Decodable {
    let message: String
}

private enum FavoriteSyncError: LocalizedError {
    case missingServer
    case invalidServerURL
    case missingPassword
    case serverUnavailable
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
        case .api(let message):
            message
        }
    }
}
