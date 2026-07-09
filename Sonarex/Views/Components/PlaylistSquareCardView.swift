import SwiftUI

struct PlaylistSquareCardView: View {
    let playlist: Playlist
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(playlist.artworkGradient)

                    Image(systemName: playlist.artworkSymbol)
                        .font(SonarexTypography.artworkSymbol)
                        .foregroundStyle(Color("InverseText").opacity(0.9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityHidden(true)

                    Label(playlist.trackCountText, systemImage: "music.note.list")
                        .font(SonarexTypography.metadata)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .foregroundStyle(Color("InverseText"))
                        .background(Color("FeedBlack").opacity(0.35), in: Capsule())
                        .padding(8)
                        .accessibilityHidden(true)
                }
                .aspectRatio(1, contentMode: .fit)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(playlist.title)
                        .font(SonarexTypography.trackTitle)
                        .foregroundStyle(Color("PrimaryText"))
                        .lineLimit(1)

                    Text(playlist.subtitle.isEmpty ? "Playlist" : playlist.subtitle)
                        .font(SonarexTypography.trackArtist)
                        .foregroundStyle(Color("SecondaryText"))
                        .lineLimit(1)
                }
            }
            .frame(width: 148, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playlist \(playlist.title) anzeigen")
        .accessibilityValue("\(playlist.trackCountText), \(playlist.subtitle.isEmpty ? "ohne Beschreibung" : playlist.subtitle)")
        .accessibilityHint("Öffnet die Detailansicht dieser Playlist.")
    }
}
