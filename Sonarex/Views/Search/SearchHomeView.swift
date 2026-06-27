//
//  SearchHomeView.swift
//  Sonarex
//
//  Created by Michael Wedel on 11.05.26.
//

import SwiftUI
import SwiftData

struct SearchHomeView: View {
    @Environment(PlayerController.self) private var player
    @Query(sort: \Track.title) private var tracks: [Track]
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private let categories = SearchCategory.categories

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    searchField

                    if searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Kategorien")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color("PrimaryText"))

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(categories) { category in
                                    SearchCategoryCardView(category: category)
                                }
                            }
                        }
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
        }
    }

    private var filteredTracks: [Track] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return tracks.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.artist.localizedCaseInsensitiveContains(query)
                || $0.album.localizedCaseInsensitiveContains(query)
                || ($0.genre?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            AppIconHeaderMark()

            Text("Suche")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color("PrimaryText"))
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.headline.weight(.semibold))
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
                        .font(.headline)
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
}

struct SearchCategory: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let colors: [Color]

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let preview = SearchCategory(
        title: "Pop",
        subtitle: "Charts und Hooks",
        systemImage: "sparkles",
        colors: TrackArtwork.palettes[1]
    )

    static let categories = [
        SearchCategory(title: "Klassik", subtitle: "Piano, Streicher, Orchester", systemImage: "pianokeys", colors: TrackArtwork.palettes[6]),
        SearchCategory(title: "Pop", subtitle: "Charts, Hooks und neue Stimmen", systemImage: "sparkles", colors: TrackArtwork.palettes[1]),
        SearchCategory(title: "Gesang", subtitle: "Vocals, Chöre und Akustik", systemImage: "mic.fill", colors: TrackArtwork.palettes[4]),
        SearchCategory(title: "Fokus", subtitle: "Ruhig, klar und konzentriert", systemImage: "headphones", colors: TrackArtwork.palettes[7]),
        SearchCategory(title: "Electronic", subtitle: "Synths, Beats und Pulse", systemImage: "waveform", colors: TrackArtwork.palettes[0]),
        SearchCategory(title: "Jazz", subtitle: "Grooves, Bass und Brass", systemImage: "music.note", colors: TrackArtwork.palettes[2]),
        SearchCategory(title: "Indie", subtitle: "Gitarren und weiche Kanten", systemImage: "guitars", colors: TrackArtwork.palettes[3]),
        SearchCategory(title: "Ambient", subtitle: "Flächen, Raum und Ruhe", systemImage: "cloud.fill", colors: TrackArtwork.palettes[8])
    ]
}

#Preview {
    SearchHomeView()
}
