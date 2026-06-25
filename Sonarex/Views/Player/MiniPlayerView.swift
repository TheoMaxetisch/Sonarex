//
//  MiniPlayerView.swift
//  Sonarex
//
//  Created by Michael Wedel on 08.06.26.
//

import SwiftUI

struct MiniPlayerView: View {
    let track: Track
    let isPlaying: Bool
    let openFullPlayer: () -> Void
    let togglePlayback: () -> Void
    let stopPlayback: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: openFullPlayer) {
                HStack(spacing: 12) {
                    artwork

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

                    Spacer(minLength: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Full Player öffnen")

            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("PrimaryText"))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pause" : "Abspielen")

            Button(action: stopPlayback) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("SecondaryText"))
                    .frame(width: 34, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mini Player schließen")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color("AccentColor").opacity(0.22), lineWidth: 1)
        }
        .shadow(color: Color("FeedBlack").opacity(0.16), radius: 18, y: 8)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(track.artworkGradient)
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: track.artworkSymbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color("InverseText").opacity(0.9))
            }
    }
}
