import SwiftUI

/// Gemeinsame Farbpaletten fuer generierte Artwork-Flaechen in Feed, Player und Listen.
enum TrackArtwork {
    static let palettes: [[Color]] = [
        [Color("FeedAqua"), Color("FeedBlue"), Color("FeedIndigo")],
        [Color("FeedOrange"), Color("FeedRose"), Color("FeedPurple")],
        [Color("FeedMint"), Color("FeedAqua"), Color("FeedBlue")],
        [Color("FeedGreen"), Color("FeedMint"), Color("FeedAqua")],
        [Color("FeedRose"), Color("FeedOrange"), Color("FeedYellow")],
        [Color("FeedIndigo"), Color("FeedBlue"), Color("FeedAqua")],
        [Color("FeedGray"), Color("FeedBlue"), Color("FeedIndigo")],
        [Color("FeedPurple"), Color("FeedIndigo"), Color("FeedBlack")],
        [Color("FeedAqua"), Color("FeedMint"), Color("FeedGray")]
    ]

    static func colors(for style: Int) -> [Color] {
        // Modulo verhindert Out-of-Bounds, wenn persistierte Styles aus alten Daten stammen.
        palettes[abs(style) % palettes.count]
    }
}

extension Track {
    var artworkColors: [Color] {
        TrackArtwork.colors(for: artworkStyle)
    }

    var artworkGradient: LinearGradient {
        LinearGradient(colors: artworkColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var heroGradient: LinearGradient {
        LinearGradient(colors: artworkColors + [Color("FeedBlack")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Playlist {
    var artworkGradient: LinearGradient {
        LinearGradient(colors: TrackArtwork.colors(for: artworkStyle), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
