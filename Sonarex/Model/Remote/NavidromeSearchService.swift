import Foundation

@MainActor
enum NavidromeSearchService {
    static func genres(server: ServerProfile, password: String) async throws -> [NavidromeGenre] {
        guard let baseURL = server.validatedBaseURL else {
            throw SearchError.invalidServerURL
        }
        guard !server.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SearchError.missingUsername
        }
        guard !password.isEmpty else {
            throw SearchError.missingPassword
        }

        let requestBuilder = SubsonicRequestBuilder(baseURL: baseURL, username: server.username, password: password)
        let url = try requestBuilder.url(for: "getGenres")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw SearchError.serverUnavailable
        }

        let decoded = try JSONDecoder().decode(GenresResponse.self, from: data)
        if decoded.subsonicResponse.status == "failed" {
            throw SearchError.api(decoded.subsonicResponse.error?.message ?? "Navidrome hat die Genres-Anfrage abgelehnt.")
        }

        return decoded.subsonicResponse.genres.genre
            .filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

struct NavidromeGenre: Decodable, Identifiable {
    let songCount: Int
    let albumCount: Int
    let value: String

    var id: String { value }

    enum CodingKeys: String, CodingKey {
        case songCount
        case albumCount
        case value
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        songCount = try container.decodeIfPresent(Int.self, forKey: .songCount) ?? 0
        albumCount = try container.decodeIfPresent(Int.self, forKey: .albumCount) ?? 0
        value = try container.decode(String.self, forKey: .value)
    }
}

private struct GenresResponse: Decodable {
    let subsonicResponse: GenresEnvelope

    enum CodingKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }
}

private struct GenresEnvelope: Decodable {
    let status: String
    let genres: GenresContainer
    let error: SubsonicSearchError?

    enum CodingKeys: String, CodingKey {
        case status
        case genres
        case error
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        genres = try container.decodeIfPresent(GenresContainer.self, forKey: .genres) ?? GenresContainer(genre: [])
        error = try container.decodeIfPresent(SubsonicSearchError.self, forKey: .error)
    }
}

private struct GenresContainer: Decodable {
    let genre: [NavidromeGenre]
}

private struct SubsonicSearchError: Decodable {
    let message: String
}

private enum SearchError: LocalizedError {
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
