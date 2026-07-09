import SwiftUI
import SwiftData

/// Bibliotheksuebersicht fuer Favoriten und gespeicherte/eigene Playlists.
struct LibraryHomeView: View {
    @Environment(PlayerController.self) private var player
    @Environment(PremiumAccessController.self) private var premium
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Playlist.title) private var playlists: [Playlist]
    @Query(sort: \Track.title) private var tracks: [Track]
    @State private var selectedPlaylist: Playlist?
    @State private var isShowingFavoriteSongs = false
    @State private var playlistPendingDeletion: Playlist?
    @State private var isConfirmingPlaylistDeletion = false
    @State private var errorMessage: String?

    private var displayTracks: [Track] {
        // Demo-Daten werden ausgeblendet, sobald echte Servertracks existieren.
        let realTracks = tracks.filter { $0.server?.isDemo != true }
        return realTracks.isEmpty ? tracks : realTracks
    }

    private var displayPlaylists: [Playlist] {
        let realPlaylists = playlists.filter { $0.server?.isDemo != true }
        return realPlaylists.isEmpty ? playlists : realPlaylists
    }

    private var savedPlaylists: [Playlist] {
        // Nur bewusst gespeicherte oder selbst erstellte Playlists erscheinen in der Bibliothek.
        displayPlaylists.filter(\.isOwnedByUser)
    }

    private var favoriteTracks: [Track] {
        displayTracks.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    header

                    AlbumRowView(
                        // Favoriten werden als virtuelle Playlist dargestellt.
                        title: "Favourite Songs",
                        subtitle: "\(favoriteTracks.count) Songs",
                        tracks: Array(favoriteTracks.prefix(4)),
                        onSelectTrack: { track in
                            player.play(track, in: favoriteTracks)
                            player.isPlayerPresented = true
                        },
                        onShowAll: {
                            isShowingFavoriteSongs = true
                        }
                    )

                    ForEach(savedPlaylists) { playlist in
                        AlbumRowView(
                            title: playlist.title,
                            subtitle: "\(playlist.subtitle) - \(playlist.trackCountText)",
                            tracks: Array(playlist.tracks.prefix(4)),
                            onSelectTrack: { track in
                                player.play(track, in: playlist.tracks)
                                player.isPlayerPresented = true
                            },
                            onShowAll: {
                                selectedPlaylist = playlist
                            },
                            onDelete: playlist.isEditableByUser ? {
                                // Nur editierbare Navidrome-Playlists erhalten ein Loeschmenue.
                                playlistPendingDeletion = playlist
                                isConfirmingPlaylistDeletion = true
                            } : nil
                        )
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color("AppBackground"))
            .navigationDestination(item: $selectedPlaylist) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .navigationDestination(isPresented: $isShowingFavoriteSongs) {
                FavoriteSongsDetailView()
            }
            // Destruktives Playlist-Loeschen wird bestaetigt und erst dann synchronisiert.
            .confirmationDialog("Playlist löschen?", isPresented: $isConfirmingPlaylistDeletion, titleVisibility: .visible) {
                Button("Playlist löschen", role: .destructive) {
                    if let playlistPendingDeletion {
                        delete(playlistPendingDeletion)
                    }
                }

                Button("Abbrechen", role: .cancel) {
                    playlistPendingDeletion = nil
                }
            } message: {
                Text("Diese Playlist wird aus Sonarex und Navidrome gelöscht.")
            }
            .alert("Playlist konnte nicht gelöscht werden", isPresented: hasErrorMessage) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private var header: some View {
        HStack(spacing: 16) {
            AppIconHeaderMark()

            Text("Bibliothek")
                .font(SonarexTypography.screenTitle)
                .foregroundStyle(Color("PrimaryText"))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 4)
    }

    private var hasErrorMessage: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func delete(_ playlist: Playlist) {
        guard premium.requirePremium(for: "Playlist löschen") else { return }

        Task {
            do {
                // Server und lokaler ModelContext werden gemeinsam aktualisiert.
                try await NavidromePlaylistSyncService.delete(playlist)
                if selectedPlaylist?.id == playlist.id {
                    selectedPlaylist = nil
                }
                if var serverPlaylists = playlist.server?.playlists {
                    serverPlaylists.removeAll { $0.id == playlist.id }
                    playlist.server?.playlists = serverPlaylists
                }
                modelContext.delete(playlist)
                try modelContext.save()
                playlistPendingDeletion = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
