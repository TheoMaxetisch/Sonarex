import SwiftUI
import SwiftData

/// Suchseite mit lokaler Track-Suche, Genre-Kategorien und zufaelligen Vorschlaegen.
struct SearchHomeView: View {
    @Environment(PlayerController.self) private var player
    @Query(sort: \Track.title) private var tracks: [Track]
    @Query(sort: \Playlist.createdAt, order: .reverse) private var playlists: [Playlist]
    @Query(sort: \ServerProfile.createdAt) private var servers: [ServerProfile]
    @State private var searchText = ""
    @State private var categories: [SearchCategory] = []
    @State private var suggestedTrackIDs: [UUID] = []
    @State private var suggestedPlaylistIDs: [UUID] = []
    @State private var selectedPlaylist: Playlist?
    @State private var isShowingSuggestedSongs = false

    private let columns = [
        // Zwei flexible Spalten halten die Kategorie-Karten auf iPhone und iPad skalierbar.
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    searchField

                    if searchText.isEmpty {
                        // Ohne Suchtext zeigt die View Browse-Inhalte statt leerer Ergebnisse.
                        startContent
                    } else if filteredTracks.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 30)
                    } else {
                        AlbumRowView(
                            title: "Suchergebnisse",
                            subtitle: "\(filteredTracks.count) Treffer",
                            tracks: filteredTracks,
                            onSelectTrack: { track in
                                player.play(track, in: filteredTracks)
                                player.isPlayerPresented = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
            .background(Color("AppBackground"))
            .navigationDestination(item: $selectedPlaylist) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .navigationDestination(isPresented: $isShowingSuggestedSongs) {
                TrackCollectionDetailView(
                    title: "Song-Vorschläge",
                    subtitle: "Zufällig aus deiner Bibliothek",
                    tracks: suggestedTracks,
                    artworkColors: TrackArtwork.palettes[0],
                    artworkSymbol: "shuffle"
                )
            }
            .task(id: activeServer?.id) {
                await loadGenres()
                refreshSuggestions(force: true)
            }
            .onAppear {
                refreshSuggestions(force: true)
            }
            .onChange(of: trackIDs) {
                refreshSuggestions(force: true)
            }
            .onChange(of: playlistIDs) {
                refreshSuggestions(force: true)
            }
        }
    }

    private var activeServer: ServerProfile? {
        // Kategorien werden nur fuer echte Server geladen; Demo-Server hat keine echte Genre-API.
        servers.first { $0.isActive && !$0.isDemo } ?? servers.first { !$0.isDemo }
    }

    private var displayTracks: [Track] {
        // Echte Daten ersetzen Demo-Daten automatisch, sobald ein Sync erfolgreich war.
        let realTracks = tracks.filter { $0.server?.isDemo != true }
        return realTracks.isEmpty ? tracks : realTracks
    }

    private var displayPlaylists: [Playlist] {
        let realPlaylists = playlists.filter { $0.server?.isDemo != true }
        return realPlaylists.isEmpty ? playlists : realPlaylists
    }

    private var filteredTracks: [Track] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        // Die lokale Suche durchsucht bewusst mehrere Felder fuer tolerantere Ergebnisse.
        return displayTracks.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.artist.localizedCaseInsensitiveContains(query)
                || $0.album.localizedCaseInsensitiveContains(query)
                || ($0.genre?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var suggestedTracks: [Track] {
        items(from: displayTracks, orderedBy: suggestedTrackIDs)
    }

    private var suggestedPlaylists: [Playlist] {
        items(from: displayPlaylists, orderedBy: suggestedPlaylistIDs)
    }

    private var trackIDs: [UUID] {
        displayTracks.map(\.id)
    }

    private var playlistIDs: [UUID] {
        displayPlaylists.map(\.id)
    }

    private var startContent: some View {
        VStack(alignment: .leading, spacing: 26) {
            if !categories.isEmpty {
                categoriesSection
            }

            if !suggestedTracks.isEmpty {
                AlbumRowView(
                    title: "Song-Vorschläge",
                    subtitle: "Zufällig aus deiner Bibliothek",
                    tracks: suggestedTracks,
                    onSelectTrack: { track in
                        player.play(track, in: suggestedTracks)
                        player.isPlayerPresented = true
                    },
                    onShowAll: {
                        isShowingSuggestedSongs = true
                    }
                )
                .padding(.horizontal, -20)
            }

            if !suggestedPlaylists.isEmpty {
                playlistsSection
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kategorien")
                .font(SonarexTypography.sectionTitle)
                .foregroundStyle(Color("PrimaryText"))

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(categories) { category in
                    SearchCategoryCardView(category: category) {
                        searchText = category.title
                    }
                }
            }
        }
    }

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Playlist-Vorschläge")
                    .font(SonarexTypography.sectionTitle)
                    .foregroundStyle(Color("PrimaryText"))

                Text(playlistSuggestionSubtitle)
                    .font(SonarexTypography.secondary)
                    .foregroundStyle(Color("SecondaryText"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(suggestedPlaylists) { playlist in
                        PlaylistSquareCardView(playlist: playlist) {
                            selectedPlaylist = playlist
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollClipDisabled()
            .padding(.horizontal, -20)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            AppIconHeaderMark()

            Text("Suche")
                .font(SonarexTypography.screenTitle)
                .foregroundStyle(Color("PrimaryText"))
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(SonarexTypography.action)
                .foregroundStyle(Color("SecondaryText"))

            TextField("Songs, Artists oder Kategorien", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Color("PrimaryText"))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(SonarexTypography.action)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Suche leeren")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func loadGenres() async {
        guard let activeServer else {
            categories = []
            return
        }

        do {
            // Das Passwort bleibt im Keychain und wird nur fuer den Request gelesen.
            let password = try KeychainCredentialStore.password(for: activeServer.id) ?? ""
            let genres = try await NavidromeSearchService.genres(server: activeServer, password: password)
            categories = genres.enumerated().map { index, genre in
                SearchCategory(genre: genre, index: index)
            }
        } catch {
            categories = []
        }
    }

    private func refreshSuggestions(force: Bool = false) {
        // IDs werden gespeichert, damit Vorschlaege stabil bleiben, bis sich die Datenbasis aendert.
        if force || suggestedTrackIDs.isEmpty {
            suggestedTrackIDs = Array(displayTracks.shuffled().prefix(8)).map(\.id)
        }

        if force || suggestedPlaylistIDs.isEmpty {
            suggestedPlaylistIDs = playlistSuggestions().map(\.id)
        }
    }

    private func playlistSuggestions() -> [Playlist] {
        // Wenn Importdaten echte Zeitpunkte haben, sind aktuelle Playlists relevanter als Zufall.
        let candidates = hasUsefulPlaylistCreationDates
            ? displayPlaylists.sorted { $0.createdAt > $1.createdAt }
            : displayPlaylists.shuffled()

        return Array(candidates.prefix(8))
    }

    private var playlistSuggestionSubtitle: String {
        hasUsefulPlaylistCreationDates ? "Zuletzt hinzugefügt" : "Zufällig aus deiner Bibliothek"
    }

    private var hasUsefulPlaylistCreationDates: Bool {
        Set(displayPlaylists.map { $0.createdAt.timeIntervalSinceReferenceDate }).count > 1
    }

    private func items<Item: Identifiable>(from source: [Item], orderedBy ids: [Item.ID]) -> [Item] where Item.ID == UUID {
        ids.compactMap { id in
            source.first { $0.id == id }
        }
    }
}

struct SearchCategory: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let colors: [Color]

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    init(id: String, title: String, subtitle: String, systemImage: String, colors: [Color]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.colors = colors
    }

    init(genre: NavidromeGenre, index: Int) {
        // API-Genres werden in visuelle Kacheln mit wiederverwendeten Paletten umgewandelt.
        id = genre.value
        title = genre.value
        subtitle = "\(genre.songCount) Songs"
        systemImage = SearchCategory.symbols[index % SearchCategory.symbols.count]
        colors = TrackArtwork.palettes[index % TrackArtwork.palettes.count]
    }

    static let preview = SearchCategory(
        id: "Pop",
        title: "Pop",
        subtitle: "Charts und Hooks",
        systemImage: "sparkles",
        colors: TrackArtwork.palettes[1]
    )

    private static let symbols = [
        "music.note",
        "waveform",
        "headphones",
        "sparkles",
        "guitars",
        "pianokeys",
        "mic.fill",
        "cloud.fill"
    ]
}

#Preview {
    SearchHomeView()
}
