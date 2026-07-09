import SwiftUI

struct CardView: View {
    let track: Track
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(track.artworkGradient)

                    Image(systemName: track.artworkSymbol)
                        .font(SonarexTypography.artworkSymbol)
                        .foregroundStyle(Color("InverseText").opacity(0.9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityHidden(true)

                    Label(track.durationText, systemImage: "play.fill")
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
                    Text(track.title)
                        .font(SonarexTypography.trackTitle)
                        .foregroundStyle(Color("PrimaryText"))
                        .lineLimit(1)

                    Text(track.artist)
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
        .accessibilityLabel("\(track.title) von \(track.artist) abspielen")
        .accessibilityValue("\(track.album.isEmpty ? "Unbekanntes Album" : track.album), Dauer \(track.durationText)")
        .accessibilityHint("Öffnet den Player und startet diesen Song.")
    }
}
