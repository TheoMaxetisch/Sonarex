import SwiftUI
import SwiftData

/// Startseite mit taeglichem Featured Track und Playlist-Reihen.
struct FeedHomeView: View {
    @Environment(PlayerController.self) private var player
    @Query(sort: \Track.title) private var tracks: [Track]
    @Query(sort: \Playlist.title) private var playlists: [Playlist]
    @AppStorage("featuredTrackID") private var featuredTrackID = ""
    @AppStorage("featuredTrackDate") private var featuredTrackDate = ""
    @State private var selectedPlaylist: Playlist?

    private var displayTracks: [Track] {
        preferredItems(from: tracks)
    }

    private var displayPlaylists: [Playlist] {
        preferredItems(from: playlists)
    }

    private var featuredTrack: Track? {
        // Wenn der gespeicherte Featured Track nicht mehr existiert, wird der erste verfuegbare Track genutzt.
        displayTracks.first { $0.remoteID == featuredTrackID } ?? displayTracks.first
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    if let featuredTrack {
                        HeroHeaderView(featuredTrack: featuredTrack) {
                            player.play(featuredTrack, in: displayTracks)
                            player.isPlayerPresented = true
                        }
                    }

                    ForEach(displayPlaylists) { playlist in
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
                            }
                        )
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color("AppBackground"))
            .navigationDestination(item: $selectedPlaylist) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .onAppear {
                refreshFeaturedTrackIfNeeded()
            }
            .onChange(of: displayTrackIDs) {
                refreshFeaturedTrackIfNeeded(force: true)
            }
        }
    }

    private var displayTrackIDs: [UUID] {
        displayTracks.map(\.id)
    }

    private var todayKey: String {
        Date.now.formatted(.iso8601.year().month().day())
    }

    private func refreshFeaturedTrackIfNeeded(force: Bool = false) {
        // Der Featured Track wird pro Tag stabil gehalten und nur bei Datenwechsel erneuert.
        guard !displayTracks.isEmpty else {
            featuredTrackID = ""
            featuredTrackDate = ""
            return
        }

        let storedTrackExists = displayTracks.contains { $0.remoteID == featuredTrackID }
        guard force || featuredTrackDate != todayKey || !storedTrackExists else { return }

        if let randomTrack = displayTracks.randomElement() {
            featuredTrackID = randomTrack.remoteID
            featuredTrackDate = todayKey
        }
    }

    private func preferredItems<Item>(from items: [Item]) -> [Item] where Item: AnyObject {
        // Echte Serverdaten haben Vorrang; Demo-Daten dienen nur als Fallback fuer leere Installationen.
        let realItems = items.filter { item in
            if let track = item as? Track {
                return track.server?.isDemo != true
            }
            if let playlist = item as? Playlist {
                return playlist.server?.isDemo != true
            }
            return true
        }

        return realItems.isEmpty ? items : realItems
    }
}
