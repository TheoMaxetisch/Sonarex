import SwiftUI

/// Wurzel-View.
/// Drei Tabs: Notizen (Hauptfeature), Lab (Pattern-Showcase), Einstellungen (rechts).
struct RootTabView: View {
    @Environment(PlayerController.self) private var player

    var body: some View {
        TabView {
            Tab("Feed", systemImage: "music.note.list") {
                PlayerTabContent {
                    FeedHomeView()
                }
            }
            /// text.magnifyingglass
            Tab("Suche", systemImage: "sparkle.magnifyingglass") {
                PlayerTabContent {
                    SearchHomeView()
                }
            }
            Tab("Bibliothek", systemImage: "tray.full.fill") {
                PlayerTabContent {
                    LibraryHomeView()
                }
            }
            Tab("Einstellungen", systemImage: "gearshape") {
                PlayerTabContent {
                    SettingsView()
                }
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.86), value: player.currentTrack?.id)
        .sheet(
            isPresented: Binding(
                get: { player.isPlayerPresented },
                set: { player.isPlayerPresented = $0 }
            )
        ) {
            FullPlayerView()
        }
    }
}

private struct PlayerTabContent<Content: View>: View {
    @Environment(PlayerController.self) private var player
    @ViewBuilder let content: Content

    var body: some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let track = player.currentTrack, !player.isPlayerPresented {
                    MiniPlayerView(
                        track: track,
                        isPlaying: player.isPlaying,
                        progress: player.progress,
                        openFullPlayer: { player.isPlayerPresented = true },
                        togglePlayback: player.togglePlayback,
                        stopPlayback: player.stop
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self], inMemory: true)
        .environment(PlayerController())
}
