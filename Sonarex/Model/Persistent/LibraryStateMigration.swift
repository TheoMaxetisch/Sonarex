import Foundation
import SwiftData

/// Einmalige Migration fuer geaenderte Bibliothekslogik nach frueheren App-Staenden.
@MainActor
enum LibraryStateMigration {
    private static let didResetAutoSavedPlaylistsKey = "didResetAutoSavedPlaylistsForLibraryLikes"

    static func resetAutoSavedPlaylistsIfNeeded(in context: ModelContext) throws {
        // UserDefaults verhindert, dass die Migration bei jedem Start erneut laeuft.
        guard !UserDefaults.standard.bool(forKey: didResetAutoSavedPlaylistsKey) else { return }

        let playlists = try context.fetch(FetchDescriptor<Playlist>())
        // Frueher automatisch gespeicherte Playlists werden zurueckgesetzt; echte eigene bleiben kuenftig markiert.
        for playlist in playlists where playlist.isOwnedByUser {
            playlist.isOwnedByUser = false
        }

        try context.save()
        UserDefaults.standard.set(true, forKey: didResetAutoSavedPlaylistsKey)
    }
}
