import Foundation
import SwiftData

@MainActor
enum LibraryStateMigration {
    private static let didResetAutoSavedPlaylistsKey = "didResetAutoSavedPlaylistsForLibraryLikes"

    static func resetAutoSavedPlaylistsIfNeeded(in context: ModelContext) throws {
        guard !UserDefaults.standard.bool(forKey: didResetAutoSavedPlaylistsKey) else { return }

        let playlists = try context.fetch(FetchDescriptor<Playlist>())
        for playlist in playlists where playlist.isOwnedByUser {
            playlist.isOwnedByUser = false
        }

        try context.save()
        UserDefaults.standard.set(true, forKey: didResetAutoSavedPlaylistsKey)
    }
}
