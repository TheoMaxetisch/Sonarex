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
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(Color("InverseText").opacity(0.9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Label(track.durationText, systemImage: "play.fill")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .foregroundStyle(Color("InverseText"))
                        .background(Color("FeedBlack").opacity(0.35), in: Capsule())
                        .padding(8)
                }
                .aspectRatio(1, contentMode: .fit)

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
            }
            .frame(width: 148)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(track.title) von \(track.artist) abspielen")
    }
}
