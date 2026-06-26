//
//  LibraryHomeView.swift
//  Sonarex
//
//  Created by Michael Wedel on 11.05.26.
//

import SwiftUI
import SwiftData

struct LibraryHomeView: View {
    @Environment(PlayerController.self) private var player
    @Query(sort: \Playlist.title) private var playlists: [Playlist]
    @Query(sort: \Track.title) private var tracks: [Track]
    @State private var selectedPlaylist: Playlist?
    @State private var isShowingFavoriteSongs = false

    private var savedPlaylists: [Playlist] {
        playlists.filter(\.isOwnedByUser)
    }

    private var favoriteTracks: [Track] {
        tracks.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    header

                    AlbumRowView(
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
            .navigationDestination(isPresented: $isShowingFavoriteSongs) {
                FavoriteSongsDetailView()
            }
        }
    }

    private var header: some View {
        Text("Bibliothek")
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(Color("PrimaryText"))
        
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}
