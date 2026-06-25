//
//  HeroHeaderView.swift
//  Sonarex
//
//  Created by Michael Wedel on 11.05.26.
//

import SwiftUI

struct HeroHeaderView: View {
    let featuredTrack: Track
    let playAction: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 32)
                .fill(featuredTrack.heroGradient)

            VStack(alignment: .leading, spacing: 18) {
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Featured Track", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color("InverseText").opacity(0.78))

                    Text(featuredTrack.title)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text(featuredTrack.artist)
                        .font(.headline)
                        .foregroundStyle(Color("InverseText").opacity(0.82))
                }

                HStack(spacing: 12) {
                    Button(action: playAction) {
                        Label("Abspielen", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(Color("FeedBlack"))
                            .frame(height: 46)
                            .padding(.horizontal, 18)
                            .background(Color("InverseText"), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color("InverseText"))
                            .frame(width: 46, height: 46)
                            .background(Color("GlassSurfaceStrong"), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Zur Bibliothek hinzufügen")
                }
            }
            .foregroundStyle(Color("InverseText"))
            .padding(24)
        }
        .frame(height: 360)
        .overlay(alignment: .topTrailing) {
            Image(systemName: featuredTrack.artworkSymbol)
                .font(.system(size: 86, weight: .bold))
                .foregroundStyle(Color("InverseText").opacity(0.22))
                .padding(.top, 74)
                .padding(.trailing, 24)
        }
        .accessibilityElement(children: .combine)
    }
}
