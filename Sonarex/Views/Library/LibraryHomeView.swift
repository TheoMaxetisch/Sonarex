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
    @State private var selectedPlaylist: Playlist?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    header

                    ForEach(playlists) { playlist in
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
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bibliothek")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color("PrimaryText"))

            Text("Deine Playlists als schnelle Vorschau.")
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}
