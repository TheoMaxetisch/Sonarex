import SwiftUI

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
            Tab("Setup", systemImage: "gearshape") {
                PlayerTabContent {
                    SettingsView()
                }
            }
        }
        .toolbarBackground(Color("AppBackground"), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .overlay(alignment: .top) {
            StatusBarScrim()
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
            .overlay(alignment: .bottom) {
                BottomContentFade()
            }
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

private struct StatusBarScrim: View {
    var body: some View {
        GeometryReader { proxy in
            Color("AppBackground")
                .frame(height: proxy.safeAreaInsets.top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(.container, edges: .top)
        }
        .allowsHitTesting(false)
    }
}

private struct BottomContentFade: View {
    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0),
                    Color("AppBackground").opacity(0.82),
                    Color("AppBackground")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: proxy.safeAreaInsets.bottom + 72)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self], inMemory: true)
        .environment(PlayerController())
}
