import Foundation
import SwiftData

@Model
final class ServerProfile {
    var id: UUID = UUID()
    var name: String = ""
    var baseURL: String = ""
    var username: String = ""
    var isActive: Bool = false
    var isDemo: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Track.server)
    var tracks: [Track]? = []

    @Relationship(deleteRule: .cascade, inverse: \Playlist.server)
    var playlists: [Playlist]? = []

    init(
        id: UUID = UUID(),
        name: String,
        baseURL: String,
        username: String = "",
        isActive: Bool = false,
        isDemo: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.baseURL = baseURL
        self.username = username
        self.isActive = isActive
        self.isDemo = isDemo
        self.createdAt = createdAt
    }

    var validatedBaseURL: URL? {
        guard let url = URL(string: baseURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }
}
