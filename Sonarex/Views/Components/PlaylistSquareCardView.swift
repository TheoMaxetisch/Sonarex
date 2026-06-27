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
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(Color("InverseText").opacity(0.9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Label(playlist.trackCountText, systemImage: "music.note.list")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .foregroundStyle(Color("InverseText"))
                        .background(Color("FeedBlack").opacity(0.35), in: Capsule())
                        .padding(8)
                }
                .aspectRatio(1, contentMode: .fit)

                VStack(alignment: .leading, spacing: 3) {
                    Text(playlist.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("PrimaryText"))
                        .lineLimit(1)

                    Text(playlist.subtitle.isEmpty ? "Playlist" : playlist.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                        .lineLimit(1)
                }
            }
            .frame(width: 148)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Playlist \(playlist.title) anzeigen")
    }
}
