import SwiftUI

struct AlbumRowView: View {
    let title: String
    let subtitle: String
    let tracks: [Track]
    let onSelectTrack: (Track) -> Void
    let onShowAll: (() -> Void)?
    let onDelete: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        tracks: [Track],
        onSelectTrack: @escaping (Track) -> Void,
        onShowAll: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.tracks = tracks
        self.onSelectTrack = onSelectTrack
        self.onShowAll = onShowAll
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline) {
                Button {
                    onShowAll?()
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(SonarexTypography.sectionTitle)
                            .foregroundStyle(Color("PrimaryText"))
                            .lineLimit(1)

                        Text(subtitle)
                            .font(SonarexTypography.secondary)
                            .foregroundStyle(Color("SecondaryText"))
                            .lineLimit(1)
                    }
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(onShowAll == nil)
                .accessibilityAddTraits(onShowAll == nil ? [] : .isButton)
                .accessibilityHint(onShowAll == nil ? "" : "Öffnet die vollständige Liste.")

                Spacer()

                if let onDelete {
                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label("Löschen", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(SonarexTypography.action)
                            .foregroundStyle(Color("SecondaryText"))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) Optionen")
                    .accessibilityHint("Öffnet Optionen für diese Playlist.")
                }

                Button {
                    onShowAll?()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(SonarexTypography.action)
                        .foregroundStyle(Color("SecondaryText"))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title) anzeigen")
                .accessibilityHint("Öffnet die vollständige Liste.")
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
