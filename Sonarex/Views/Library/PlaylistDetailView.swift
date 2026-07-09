import SwiftUI
import SwiftData

struct PlaylistDetailView: View {
    @Environment(PlayerController.self) private var player
    @Environment(PremiumAccessController.self) private var premium
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var isConfirmingPlaylistDeletion = false
    @State private var isEditingPlaylist = false
    let playlist: Playlist

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(spacing: 10) {
                    ForEach(Array(playlist.orderedEntries.enumerated()), id: \.element.id) { index, entry in
                        if let track = entry.track {
                            PlaylistTrackRow(
                                track: track,
                                number: index + 1,
                                isEditing: isEditingPlaylist,
                                removeAction: playlist.isEditableByUser && isEditingPlaylist ? { remove(entry) } : nil
                            ) {
                                player.play(track, in: playlist.tracks)
                                player.isPlayerPresented = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 28)
        }
        .background(Color("AppBackground"))
        .navigationTitle(playlist.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Playlist löschen?", isPresented: $isConfirmingPlaylistDeletion, titleVisibility: .visible) {
            Button("Playlist löschen", role: .destructive) {
                deletePlaylist()
            }

            Button("Abbrechen", role: .cancel) {
            }
        } message: {
            Text("Diese Playlist wird aus Sonarex und Navidrome gelöscht.")
        }
        .alert("Playlist konnte nicht geändert werden", isPresented: hasErrorMessage) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(playlist.artworkGradient)

                Image(systemName: playlist.artworkSymbol)
                    .font(SonarexTypography.largeArtworkSymbol)
                    .foregroundStyle(Color("InverseText").opacity(0.92))
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 260)
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text(playlist.title)
                    .font(SonarexTypography.screenTitle)
                    .foregroundStyle(Color("PrimaryText"))

                Text(playlist.playlistDescription)
                    .font(SonarexTypography.body)
                    .foregroundStyle(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)

                Label("\(playlist.trackCountText) - \(playlist.totalDurationText)", systemImage: "music.note.list")
                    .font(SonarexTypography.metadata)
                    .foregroundStyle(Color("SecondaryText"))
            }

            if isEditingPlaylist {
                Label("Bearbeiten aktiv", systemImage: "pencil")
                    .font(SonarexTypography.metadata)
                    .foregroundStyle(Color("SecondaryAccent"))
            }

            HStack(spacing: 12) {
                Button {
                    player.play(playlist.tracks)
                    player.isPlayerPresented = true
                } label: {
                    Label("Abspielen", systemImage: "play.fill")
                        .font(SonarexTypography.action)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("SecondaryAccent"))
                .accessibilityLabel("\(playlist.title) abspielen")

                Button {
                    if premium.requirePremium(for: "Playlist-Likes") {
                        playlist.isOwnedByUser.toggle()
                    }
                } label: {
                    Image(systemName: playlist.isOwnedByUser ? "heart.fill" : "heart")
                        .font(SonarexTypography.action)
                        .foregroundStyle(playlist.isOwnedByUser ? Color("FavoriteColor") : Color("PrimaryText"))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .tint(Color("SecondaryAccent"))
                .accessibilityLabel(playlist.isOwnedByUser ? "Playlist aus Bibliothek entfernen" : "Playlist in Bibliothek speichern")

                if playlist.isEditableByUser {
                    Menu {
                        Button {
                            isEditingPlaylist.toggle()
                        } label: {
                            Label(isEditingPlaylist ? "Fertig" : "Bearbeiten", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            isConfirmingPlaylistDeletion = true
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(SonarexTypography.action)
                            .foregroundStyle(Color("PrimaryText"))
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color("SecondaryAccent"))
                    .accessibilityLabel("Weitere Optionen")
                    .accessibilityHint("Öffnet Optionen für diese Playlist.")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var hasErrorMessage: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func remove(_ entry: PlaylistEntry) {
        guard premium.requirePremium(for: "Playlist bearbeiten") else { return }

        Task {
            do {
                try await NavidromePlaylistSyncService.remove(entry, from: playlist)
                var entries = playlist.entries ?? []
                entries.removeAll { $0.id == entry.id }
                playlist.entries = entries
                for (position, remainingEntry) in playlist.orderedEntries.enumerated() {
                    remainingEntry.position = position
                }
                playlist.changedAt = .now
                modelContext.delete(entry)
                try modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deletePlaylist() {
        guard premium.requirePremium(for: "Playlist löschen") else { return }

        Task {
            do {
                try await NavidromePlaylistSyncService.delete(playlist)
                if var serverPlaylists = playlist.server?.playlists {
                    serverPlaylists.removeAll { $0.id == playlist.id }
                    playlist.server?.playlists = serverPlaylists
                }
                modelContext.delete(playlist)
                try modelContext.save()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct FavoriteSongsDetailView: View {
    @Environment(PlayerController.self) private var player
    @Query(sort: \Track.title) private var tracks: [Track]

    private var displayTracks: [Track] {
        let realTracks = tracks.filter { $0.server?.isDemo != true }
        return realTracks.isEmpty ? tracks : realTracks
    }

    private var favoriteTracks: [Track] {
        displayTracks.filter(\.isFavorite)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(spacing: 10) {
                    ForEach(Array(favoriteTracks.enumerated()), id: \.element.id) { index, track in
                        PlaylistTrackRow(track: track, number: index + 1) {
                            player.play(track, in: favoriteTracks)
                            player.isPlayerPresented = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 28)
        }
        .background(Color("AppBackground"))
        .navigationTitle("Favourite Songs")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: TrackArtwork.palettes[1], startPoint: .topLeading, endPoint: .bottomTrailing))

                Image(systemName: "heart.fill")
                    .font(SonarexTypography.largeArtworkSymbol)
                    .foregroundStyle(Color("InverseText").opacity(0.92))
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 260)
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text("Favourite Songs")
                    .font(SonarexTypography.screenTitle)
                    .foregroundStyle(Color("PrimaryText"))

                Label("\(favoriteTracks.count) Songs", systemImage: "heart.fill")
                    .font(SonarexTypography.metadata)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Button {
                player.play(favoriteTracks)
                player.isPlayerPresented = true
            } label: {
                Label("Abspielen", systemImage: "play.fill")
                    .font(SonarexTypography.action)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("SecondaryAccent"))
            .disabled(favoriteTracks.isEmpty)
            .accessibilityLabel("Favourite Songs abspielen")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

struct TrackCollectionDetailView: View {
    @Environment(PlayerController.self) private var player
    let title: String
    let subtitle: String
    let tracks: [Track]
    let artworkColors: [Color]
    let artworkSymbol: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(spacing: 10) {
                    ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                        PlaylistTrackRow(track: track, number: index + 1) {
                            player.play(track, in: tracks)
                            player.isPlayerPresented = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 28)
        }
        .background(Color("AppBackground"))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: artworkColors, startPoint: .topLeading, endPoint: .bottomTrailing))

                Image(systemName: artworkSymbol)
                    .font(SonarexTypography.largeArtworkSymbol)
                    .foregroundStyle(Color("InverseText").opacity(0.92))
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 260)
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(SonarexTypography.screenTitle)
                    .foregroundStyle(Color("PrimaryText"))

                Text(subtitle)
                    .font(SonarexTypography.body)
                    .foregroundStyle(Color("SecondaryText"))

                Label("\(tracks.count) Songs", systemImage: "music.note.list")
                    .font(SonarexTypography.metadata)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Button {
                player.play(tracks)
                player.isPlayerPresented = true
            } label: {
                Label("Abspielen", systemImage: "play.fill")
                    .font(SonarexTypography.action)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("SecondaryAccent"))
            .disabled(tracks.isEmpty)
            .accessibilityLabel("\(title) abspielen")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

private struct PlaylistTrackRow: View {
    @Environment(PremiumAccessController.self) private var premium
    let track: Track
    let number: Int
    let isEditing: Bool
    let removeAction: (() -> Void)?
    let playAction: () -> Void

    init(
        track: Track,
        number: Int,
        isEditing: Bool = false,
        removeAction: (() -> Void)? = nil,
        playAction: @escaping () -> Void
    ) {
        self.track = track
        self.number = number
        self.isEditing = isEditing
        self.removeAction = removeAction
        self.playAction = playAction
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(SonarexTypography.metadata)
                .foregroundStyle(Color("SecondaryText"))
                .frame(width: 24)
                .accessibilityLabel("Position \(number)")

            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(track.artworkGradient)

                Image(systemName: track.artworkSymbol)
                    .font(SonarexTypography.action)
                    .foregroundStyle(Color("InverseText"))
                    .accessibilityHidden(true)
            }
            .frame(width: 48, height: 48)
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

            Spacer()

            Button {
                if premium.requirePremium(for: "Songs liken") {
                    toggleFavorite()
                }
            } label: {
                Image(systemName: track.isFavorite ? "heart.fill" : "heart")
                    .font(SonarexTypography.action)
                    .foregroundStyle(track.isFavorite ? Color("FavoriteColor") : Color("SecondaryText"))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(track.isFavorite ? "Aus Favourite Songs entfernen" : "Zu Favourite Songs hinzufügen")
            .accessibilityValue(track.isFavorite ? "Ist Favorit" : "Kein Favorit")
            .accessibilityHint("Ändert den Favoritenstatus dieses Songs.")

            Text(track.durationText)
                .font(SonarexTypography.metadata)
                .foregroundStyle(Color("SecondaryText"))
                .accessibilityLabel("Dauer \(track.durationText)")

            Button(action: playAction) {
                Image(systemName: "play.fill")
                    .font(SonarexTypography.metadata)
                    .foregroundStyle(Color("InverseText"))
                    .frame(width: 30, height: 30)
                    .background(Color("FeedBlack").opacity(0.22), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(track.title) abspielen")
            .accessibilityValue("\(track.artist), \(track.durationText)")

            if isEditing, let removeAction {
                Button(role: .destructive, action: removeAction) {
                    Image(systemName: "trash")
                        .font(SonarexTypography.metadata)
                        .foregroundStyle(Color("InverseText"))
                        .frame(width: 30, height: 30)
                        .background(Color.red.opacity(0.9), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(track.title) aus Playlist entfernen")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let removeAction {
                Button(role: .destructive, action: removeAction) {
                    Label("Entfernen", systemImage: "trash")
                }
                .accessibilityLabel("\(track.title) aus Playlist entfernen")
            }
        }
    }

    private func toggleFavorite() {
        let nextValue = !track.isFavorite
        track.isFavorite = nextValue

        Task {
            do {
                try await NavidromeFavoriteSyncService.setFavorite(nextValue, for: track)
            } catch {
                await MainActor.run {
                    track.isFavorite.toggle()
                }
            }
        }
    }
}
