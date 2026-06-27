import SwiftUI

struct FullPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PlayerController.self) private var player

    var body: some View {
        Group {
            if let track = player.currentTrack {
                playerContent(track)
            } else {
                ContentUnavailableView("Nichts wird abgespielt", systemImage: "music.note")
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
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Player schließen")

            Spacer()

            VStack(spacing: 2) {
                Text("Jetzt läuft")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                Text(track.album.isEmpty ? "Sonarex" : track.album)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.title3.weight(.semibold))
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
                    .font(.system(size: 78, weight: .medium))
                    .accessibilityHidden(true)
                VStack(spacing: 6) {
                    Text("SONAREX").font(.headline.weight(.bold))
                    Text(track.album.isEmpty ? track.title : track.album)
                        .font(.subheadline)
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
                Text(track.title).font(.title2.weight(.bold)).lineLimit(2)
                Text(track.artist).foregroundStyle(Color("SecondaryText"))
            }
            Spacer(minLength: 12)
            Button {
                toggleFavorite(track)
            } label: {
                Image(systemName: track.isFavorite ? "heart.fill" : "heart")
                    .font(.title2.weight(.semibold))
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
            .font(.caption.monospacedDigit())
            .foregroundStyle(Color("SecondaryText"))
        }
    }

    @ViewBuilder
    private var playbackError: some View {
        if let message = player.playbackError {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
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
                    .font(.system(size: 28, weight: .bold))
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
        .font(.title2.weight(.semibold))
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
        .font(.footnote)
        .foregroundStyle(Color("SecondaryText"))
    }

    private var upcomingQueue: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Als Nächstes").font(.headline)
            VStack(spacing: 0) {
                if upcomingTracks.isEmpty {
                    Label("Danach startet der Mix", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
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
                    Text("Weiter im Mix").font(.headline)
                    Spacer()
                    Image(systemName: "shuffle")
                        .font(.subheadline.weight(.semibold))
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
                Image(systemName: symbol).font(.headline)
                Text(title).font(.caption.weight(.semibold))
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
                    Text(track.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(track.artist).font(.caption).foregroundStyle(Color("SecondaryText")).lineLimit(1)
                }
                Spacer()
                Text(track.durationText).font(.caption.monospacedDigit()).foregroundStyle(Color("SecondaryText"))
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
