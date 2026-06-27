import SwiftUI

struct AlbumRowView: View {
    let title: String
    let subtitle: String
    let tracks: [Track]
    let onSelectTrack: (Track) -> Void
    let onShowAll: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        tracks: [Track],
        onSelectTrack: @escaping (Track) -> Void,
        onShowAll: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.tracks = tracks
        self.onSelectTrack = onSelectTrack
        self.onShowAll = onShowAll
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                Button {
                    onShowAll?()
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color("PrimaryText"))

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color("SecondaryText"))
                    }
                }
                .buttonStyle(.plain)
                .disabled(onShowAll == nil)

                Spacer()

                Button {
                    onShowAll?()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color("SecondaryText"))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title) anzeigen")
                .disabled(onShowAll == nil)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(tracks) { track in
                        CardView(track: track) {
                            onSelectTrack(track)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollClipDisabled()
        }
    }
}
