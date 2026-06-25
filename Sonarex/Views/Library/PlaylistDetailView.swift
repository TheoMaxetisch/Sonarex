//
//  PlaylistDetailView.swift
//  Sonarex
//
//  Created by Michael Wedel on 09.06.26.
//

import SwiftUI

struct PlaylistDetailView: View {
    @Environment(PlayerController.self) private var player
    let playlist: Playlist

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(spacing: 10) {
                    ForEach(Array(playlist.tracks.enumerated()), id: \.element.id) { index, track in
                        PlaylistTrackRow(track: track, number: index + 1) {
                            player.play(track, in: playlist.tracks)
                            player.isPlayerPresented = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 28)
        }
        .background(Color("AppBackground"))
        .navigationTitle(playlist.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(playlist.artworkGradient)

                Image(systemName: playlist.artworkSymbol)
                    .font(.system(size: 76, weight: .semibold))
                    .foregroundStyle(Color("InverseText").opacity(0.92))
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 260)
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text(playlist.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color("PrimaryText"))

                Text(playlist.playlistDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)

                Label("\(playlist.trackCountText) - \(playlist.totalDurationText)", systemImage: "music.note.list")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("SecondaryText"))
            }

            Button {
                player.play(playlist.tracks)
                player.isPlayerPresented = true
            } label: {
                Label("Abspielen", systemImage: "play.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("SecondaryAccent"))
            .accessibilityLabel("\(playlist.title) abspielen")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

private struct PlaylistTrackRow: View {
    let track: Track
    let number: Int
    let playAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("SecondaryText"))
                .frame(width: 24)

            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(track.artworkGradient)

                Image(systemName: track.artworkSymbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color("InverseText"))
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))
                    .lineLimit(1)

                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .lineLimit(1)
            }

            Spacer()

            Text(track.durationText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("SecondaryText"))

            Button(action: playAction) {
                Image(systemName: "play.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("InverseText"))
                    .frame(width: 30, height: 30)
                    .background(Color("FeedBlack").opacity(0.22), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(track.title) abspielen")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
