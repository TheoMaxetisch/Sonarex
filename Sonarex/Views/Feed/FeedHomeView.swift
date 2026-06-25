//
//  HomeHomeView.swift
//  Sonarex
//
//  Created by Michael Wedel on 11.05.26.
//

import SwiftUI
import SwiftData

struct FeedHomeView: View {
    @Environment(PlayerController.self) private var player
    @Query(sort: \Track.title) private var tracks: [Track]
    @Query(sort: \Playlist.title) private var playlists: [Playlist]
    @State private var selectedPlaylist: Playlist?

    private var featuredTrack: Track? {
        tracks.first { $0.remoteID == "golden-hour-static" } ?? tracks.first
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    if let featuredTrack {
                        HeroHeaderView(featuredTrack: featuredTrack) {
                            player.play(featuredTrack, in: tracks)
                            player.isPlayerPresented = true
                        }
                    }

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
}
