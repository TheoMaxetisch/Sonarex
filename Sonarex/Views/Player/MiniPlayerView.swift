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
    let progress: Double
    let openFullPlayer: () -> Void
    let togglePlayback: () -> Void
    let stopPlayback: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Button(action: openFullPlayer) {
                    HStack(spacing: 13) {
                        artwork

                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color("PrimaryText"))
                                .lineLimit(1)

                            Text(track.artist)
                                .font(.caption.weight(.medium))
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
                        .foregroundStyle(Color("FeedBlack"))
                        .frame(width: 44, height: 44)
                        .background(Color("InverseText"), in: Circle())
                        .shadow(color: accentColor.opacity(0.28), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? "Pause" : "Abspielen")

                Button(action: stopPlayback) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("SecondaryText"))
                        .frame(width: 34, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mini Player schließen")
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)

            progressBar
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(containerTint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accentColor.opacity(0.34), lineWidth: 1)
        }
        .shadow(color: accentColor.opacity(0.18), radius: 28, y: 14)
        .shadow(color: Color("FeedBlack").opacity(0.22), radius: 18, y: 9)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private var artwork: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(track.artworkGradient)
            .frame(width: 54, height: 54)
            .overlay {
                Image(systemName: track.artworkSymbol)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color("InverseText").opacity(0.9))
            }
            .shadow(color: accentColor.opacity(0.24), radius: 12, y: 6)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color("GlassDivider").opacity(0.8))

                Rectangle()
                    .fill(accentColor)
                    .frame(width: max(0, min(progress, 1)) * proxy.size.width)
            }
        }
        .frame(height: 3)
        .clipShape(.rect(bottomLeadingRadius: 20, bottomTrailingRadius: 20))
    }

    private var accentColor: Color {
        track.artworkColors.first ?? Color("SecondaryAccent")
    }

    private var containerTint: LinearGradient {
        LinearGradient(
            colors: [
                accentColor.opacity(0.16),
                Color("ElevatedBackground").opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
