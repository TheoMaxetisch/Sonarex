import CryptoKit
import Foundation

struct SubsonicRequestBuilder {
    let baseURL: URL
    let username: String
    let password: String

    func url(
        for endpoint: String,
        queryItems endpointQueryItems: [URLQueryItem] = [],
        responseFormat: String? = "json"
    ) throws -> URL {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("rest").appendingPathComponent("\(endpoint).view"),
            resolvingAgainstBaseURL: false
        ) else {
            throw SubsonicRequestError.invalidServerURL
        }

        components.queryItems = authenticationQueryItems(responseFormat: responseFormat) + endpointQueryItems
        guard let url = components.url else {
            throw SubsonicRequestError.invalidServerURL
        }
        return url
    }

    private func authenticationQueryItems(responseFormat: String?) -> [URLQueryItem] {
        let salt = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let token = Insecure.MD5.hash(data: Data((password + salt).utf8))
            .map { String(format: "%02hhx", $0) }
            .joined()

        var queryItems = [
            URLQueryItem(name: "u", value: username),
            URLQueryItem(name: "t", value: token),
            URLQueryItem(name: "s", value: salt),
            URLQueryItem(name: "v", value: "1.16.1"),
            URLQueryItem(name: "c", value: "Sonarex")
        ]

        if let responseFormat {
            queryItems.append(URLQueryItem(name: "f", value: responseFormat))
        }

        return queryItems
    }
}

enum SubsonicRequestError: LocalizedError {
    case invalidServerURL

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            "Die Server-URL ist ungueltig. Bitte mit http:// oder https:// eintragen."
        }
    }
}
