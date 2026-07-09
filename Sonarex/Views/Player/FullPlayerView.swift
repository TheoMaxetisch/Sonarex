import SwiftUI
import SwiftData

struct FullPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PlayerController.self) private var player
    @Environment(PremiumAccessController.self) private var premium
    @Query(sort: \Playlist.title) private var playlists: [Playlist]
    @State private var isShowingPlaylistPicker = false

    var body: some View {
        Group {
            if let track = player.currentTrack {
                playerContent(track)
            } else {
                ContentUnavailableView("Nichts wird abgespielt", systemImage: "music.note")
            }
        }
        .sheet(isPresented: $isShowingPlaylistPicker) {
            if let track = player.currentTrack {
                AddToPlaylistSheet(
                    track: track,
                    playlists: editablePlaylists(for: track),
                    onCreate: createPlaylist,
                    onAdd: addTrack
                )
            }
        }
    }

    private func playerContent(_ track: Track) -> some View {
        ZStack {
            PlayerBackground(accent: track.artworkColors.first ?? Color("SecondaryAccent"))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    header(track)
                    artwork(track)
                    trackInfo(track)
                    playbackError
                    progress(track)
                    transportControls
                    volumeControl
                    upcomingQueue
                    continuationPreview
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
    }

    private func header(_ track: Track) -> some View {
        HStack {
            Button {
                player.isPlayerPresented = false
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(SonarexTypography.action)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Player schließen")

            Spacer()

            VStack(spacing: 2) {
                Text("Jetzt läuft")
                    .font(SonarexTypography.secondary)
                    .foregroundStyle(Color("SecondaryText"))
                Text(track.album.isEmpty ? "Sonarex" : track.album)
                    .font(SonarexTypography.secondaryEmphasis)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(SonarexTypography.action)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
    }

    private func artwork(_ track: Track) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(track.artworkGradient)

            VStack(spacing: 18) {
                Image(systemName: track.artworkSymbol)
                    .font(.system(size: 58, weight: .medium))
                    .accessibilityHidden(true)
                VStack(spacing: 6) {
                    Text("SONAREX").font(SonarexTypography.action)
                    Text(track.album.isEmpty ? track.title : track.album)
                        .font(SonarexTypography.secondary)
                        .foregroundStyle(Color("InverseText").opacity(0.78))
                }
            }
            .foregroundStyle(Color("InverseText"))
        }
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: (track.artworkColors.first ?? .clear).opacity(0.36), radius: 34, y: 18)
        .padding(.top, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Artwork für \(track.album.isEmpty ? track.title : track.album)")
    }

    private func trackInfo(_ track: Track) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(track.title).font(SonarexTypography.sheetTitle).lineLimit(2)
                Text(track.artist).font(SonarexTypography.secondary).foregroundStyle(Color("SecondaryText"))
            }
            Spacer(minLength: 12)
            Button {
                if premium.requirePremium(for: "Songs zu Playlists hinzufügen") {
                    isShowingPlaylistPicker = true
                }
            } label: {
                Image(systemName: "text.badge.plus")
                    .font(SonarexTypography.action)
                    .foregroundStyle(Color("InverseText"))
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Zu Playlist hinzufügen")

            Button {
                if premium.requirePremium(for: "Songs liken") {
                    toggleFavorite(track)
                }
            } label: {
                Image(systemName: track.isFavorite ? "heart.fill" : "heart")
                    .font(SonarexTypography.action)
                    .foregroundStyle(track.isFavorite ? Color("FavoriteColor") : Color("InverseText"))
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(track.isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
            .accessibilityValue(track.isFavorite ? "Ist Favorit" : "Kein Favorit")
        }
    }

    private func progress(_ track: Track) -> some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { player.progress },
                    set: { value in player.seek(to: value) }
                ),
                in: 0...1
            )
                .tint(Color("InverseText"))
                .accessibilityLabel("Wiedergabeposition")
                .accessibilityValue("\(formattedTime(player.elapsedTime)) von \(track.durationText)")
            HStack {
                Text(formattedTime(player.elapsedTime))
                Spacer()
                Text(track.durationText)
            }
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundStyle(Color("SecondaryText"))
        }
    }

    @ViewBuilder
    private var playbackError: some View {
        if let message = player.playbackError {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(SonarexTypography.metadata)
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var transportControls: some View {
        HStack(spacing: 30) {
            Button { player.isShuffleEnabled.toggle() } label: {
                Image(systemName: "shuffle")
                    .foregroundStyle(player.isShuffleEnabled ? Color("SecondaryAccent") : Color("InverseText").opacity(0.72))
            }
            .accessibilityLabel("Zufällige Wiedergabe")
            .accessibilityValue(player.isShuffleEnabled ? "Ein" : "Aus")

            Button(action: player.playPrevious) { Image(systemName: "backward.fill") }
                .accessibilityLabel("Vorheriger Song")

            Button(action: player.togglePlayback) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color("FeedBlack"))
                    .frame(width: 74, height: 74)
                    .background(Color("InverseText"), in: Circle())
            }
            .accessibilityLabel(player.isPlaying ? "Pause" : "Abspielen")
            .accessibilityValue(player.isPlaying ? "Wiedergabe läuft" : "Pausiert")

            Button(action: player.playNext) { Image(systemName: "forward.fill") }
                .accessibilityLabel("Nächster Song")

            Button { player.repeatMode = player.repeatMode.next } label: {
                Image(systemName: player.repeatMode.symbol)
                    .foregroundStyle(player.repeatMode == .off ? Color("InverseText").opacity(0.72) : Color("SecondaryAccent"))
            }
            .accessibilityLabel("Wiederholen")
            .accessibilityValue(repeatModeAccessibilityValue)
        }
        .font(SonarexTypography.action)
        .buttonStyle(.plain)
    }

    private var volumeControl: some View {
        HStack(spacing: 14) {
            Image(systemName: "speaker.fill")
                .accessibilityHidden(true)
            Slider(
                value: Binding(
                    get: { player.volume },
                    set: { value in player.volume = value }
                ),
                in: 0...1
            )
                .tint(Color("InverseText"))
                .accessibilityLabel("Lautstärke")
                .accessibilityValue("\(Int(player.volume * 100)) Prozent")
            Image(systemName: "speaker.wave.3.fill")
                .accessibilityHidden(true)
        }
        .font(SonarexTypography.secondary)
        .foregroundStyle(Color("SecondaryText"))
    }

    private var upcomingQueue: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Als Nächstes").font(SonarexTypography.sectionTitle)
            VStack(spacing: 0) {
                if upcomingTracks.isEmpty {
                    Label("Danach startet der Mix", systemImage: "sparkles")
                        .font(SonarexTypography.action)
                        .foregroundStyle(Color("SecondaryText"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 58)
                } else {
                    ForEach(upcomingTracks) { track in
                        QueueRow(track: track) { player.play(track, in: player.queue) }
                        if track.id != upcomingTracks.last?.id {
                            Divider().overlay(Color("GlassDivider")).padding(.leading, 56)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color("GlassSurface").opacity(0.8), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    @ViewBuilder
    private var continuationPreview: some View {
        let tracks = player.continuationPreviewTracks
        if !tracks.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Weiter im Mix").font(SonarexTypography.sectionTitle)
                    Spacer()
                    Image(systemName: "shuffle")
                        .font(SonarexTypography.action)
                        .foregroundStyle(Color("SecondaryAccent"))
                        .accessibilityHidden(true)
                }

                VStack(spacing: 0) {
                    ForEach(tracks) { track in
                        QueueRow(track: track) {
                            player.playContinuation(track)
                        }
                        if track.id != tracks.last?.id {
                            Divider().overlay(Color("GlassDivider")).padding(.leading, 56)
                        }
                    }
                }
                .padding(12)
                .background(Color("GlassSurface").opacity(0.56), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color("SecondaryAccent").opacity(0.24), lineWidth: 1)
                }
            }
        }
    }

    private var upcomingTracks: [Track] {
        guard let index = player.currentIndex else { return [] }
        return Array(player.queue.dropFirst(index + 1))
    }

    private var repeatModeAccessibilityValue: String {
        switch player.repeatMode {
        case .off:
            "Aus"
        case .all:
            "Alle Songs"
        case .one:
            "Aktueller Song"
        }
    }

    private func formattedTime(_ seconds: Double) -> String {
        let value = Int(seconds.rounded())
        return "\(value / 60):\(String(format: "%02d", value % 60))"
    }

    private func editablePlaylists(for track: Track) -> [Playlist] {
        guard let serverID = track.server?.id else { return [] }
        return playlists.filter { playlist in
            playlist.isEditableByUser && playlist.server?.id == serverID
        }
    }

    private func createPlaylist(named name: String, with track: Track) async throws {
        let remotePlaylist = try await NavidromePlaylistSyncService.createPlaylist(named: name, containing: track)
        let playlist = Playlist(
            remoteID: remotePlaylist.id,
            title: remotePlaylist.name,
            subtitle: "Eigene Playlist",
            playlistDescription: "",
            artworkStyle: track.artworkStyle,
            artworkSymbol: "music.note.list",
            isOwnedByUser: true,
            isEditableByUser: true,
            server: track.server
        )
        let entry = PlaylistEntry(position: 0, playlist: playlist, track: track)
        playlist.entries = [entry]

        modelContext.insert(playlist)
        modelContext.insert(entry)
        if let server = track.server {
            var serverPlaylists = server.playlists ?? []
            serverPlaylists.append(playlist)
            server.playlists = serverPlaylists
        }
        try modelContext.save()
    }

    private func addTrack(_ track: Track, to playlist: Playlist) async throws {
        guard !playlist.tracks.contains(where: { $0.remoteID == track.remoteID }) else { return }
        try await NavidromePlaylistSyncService.add(track, to: playlist)

        let nextPosition = (playlist.entries ?? []).map(\.position).max().map { $0 + 1 } ?? 0
        let entry = PlaylistEntry(position: nextPosition, playlist: playlist, track: track)
        var entries = playlist.entries ?? []
        entries.append(entry)
        playlist.entries = entries
        playlist.changedAt = .now
        modelContext.insert(entry)
        try modelContext.save()
    }

    private func toggleFavorite(_ track: Track) {
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

private struct AddToPlaylistSheet: View {
    @Environment(\.dismiss) private var dismiss
    let track: Track
    let playlists: [Playlist]
    let onCreate: @MainActor (String, Track) async throws -> Void
    let onAdd: @MainActor (Track, Playlist) async throws -> Void

    @State private var newPlaylistName = ""
    @State private var statusMessage: String?
    @State private var isWorking = false

    private var trimmedName: String {
        newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Neue Playlist") {
                    TextField("Name", text: $newPlaylistName)
                        .textInputAutocapitalization(.words)

                    Button {
                        Task { await createPlaylist() }
                    } label: {
                        Label("Erstellen und hinzufügen", systemImage: "plus")
                    }
                    .disabled(trimmedName.isEmpty || isWorking)
                }

                Section("Playlists") {
                    if playlists.isEmpty {
                        ContentUnavailableView("Noch keine eigenen Playlists", systemImage: "music.note.list")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(playlists) { playlist in
                            Button {
                                Task { await add(to: playlist) }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: playlist.tracks.contains(where: { $0.remoteID == track.remoteID }) ? "checkmark.circle.fill" : "text.badge.plus")
                                        .foregroundStyle(Color("SecondaryAccent"))
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(playlist.title)
                                            .font(SonarexTypography.bodyEmphasis)
                                            .foregroundStyle(Color("PrimaryText"))
                                        Text(playlist.trackCountText)
                                            .font(SonarexTypography.secondary)
                                            .foregroundStyle(Color("SecondaryText"))
                                    }
                                }
                            }
                            .disabled(isWorking || playlist.tracks.contains(where: { $0.remoteID == track.remoteID }))
                        }
                    }
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(SonarexTypography.secondary)
                            .foregroundStyle(Color.red)
                    }
                }
            }
            .navigationTitle("Zu Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
            .disabled(isWorking)
        }
    }

    private func createPlaylist() async {
        await perform {
            try await onCreate(trimmedName, track)
        }
    }

    private func add(to playlist: Playlist) async {
        await perform {
            try await onAdd(track, playlist)
        }
    }

    private func perform(_ operation: () async throws -> Void) async {
        statusMessage = nil
        isWorking = true
        do {
            try await operation()
            dismiss()
        } catch {
            statusMessage = error.localizedDescription
            isWorking = false
        }
    }
}

private struct PlayerBackground: View {
    let accent: Color
    var body: some View {
        LinearGradient(colors: [accent.opacity(0.72), Color("PlayerBackgroundMiddle"), Color("PlayerBackgroundBottom")], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .overlay { Color("FeedBlack").opacity(0.18).ignoresSafeArea() }
    }
}

private struct PlayerActionButton: View {
    let title: String
    let symbol: String
    var body: some View {
        Button {} label: {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(SonarexTypography.action)
                Text(title).font(SonarexTypography.metadata)
            }
            .foregroundStyle(Color("InverseText"))
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct QueueRow: View {
    let track: Track
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(track.artworkGradient)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: track.artworkSymbol)
                            .foregroundStyle(Color("InverseText"))
                            .accessibilityHidden(true)
                    }
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title).font(SonarexTypography.trackTitle).lineLimit(1)
                    Text(track.artist).font(SonarexTypography.trackArtist).foregroundStyle(Color("SecondaryText")).lineLimit(1)
                }
                Spacer()
                Text(track.durationText).font(.system(size: 11, weight: .regular, design: .monospaced)).foregroundStyle(Color("SecondaryText"))
            }
            .frame(height: 58)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title) von \(track.artist)")
        .accessibilityValue("Dauer \(track.durationText)")
        .accessibilityHint("Spielt diesen Song ab.")
    }
}
