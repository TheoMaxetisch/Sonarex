import SwiftUI

struct RootTabView: View {
    @Environment(PlayerController.self) private var player
    @Environment(PremiumAccessController.self) private var premium

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
        .sheet(
            isPresented: Binding(
                get: { premium.isPaywallPresented },
                set: { premium.isPaywallPresented = $0 }
            )
        ) {
            PremiumPaywallView()
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

private struct PremiumPaywallView: View {
    @Environment(PremiumAccessController.self) private var premium
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                header
                featureList
                Spacer(minLength: 18)
                actions
            }
            .padding(24)
            .background(Color("AppBackground"))
            .navigationTitle("Sonarex Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
            .task {
                await premium.refresh()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color("SecondaryAccent"))

            Text(premium.requestedFeature)
                .font(.title.weight(.bold))
                .foregroundStyle(Color("PrimaryText"))

            Text("Nach der 14-taegigen Testphase brauchst du Premium fuer Likes, eigene Playlists und Playlist-Likes. Musik abspielen bleibt weiterhin moeglich.")
                .font(.body)
                .foregroundStyle(Color("SecondaryText"))
                .fixedSize(horizontal: false, vertical: true)

            Text(premium.premiumStatusText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("SecondaryAccent"))
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            PremiumFeatureRow(symbol: "heart.fill", title: "Songs liken")
            PremiumFeatureRow(symbol: "music.note.list", title: "Eigene Playlists erstellen")
            PremiumFeatureRow(symbol: "text.badge.plus", title: "Songs zu Playlists hinzufügen")
            PremiumFeatureRow(symbol: "checkmark.seal.fill", title: "Kauf über Apple wiederherstellen")
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                Task { await premium.purchasePremium() }
            } label: {
                Label(purchaseButtonTitle, systemImage: "cart.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("SecondaryAccent"))
            .disabled(premium.isLoading)

            Button {
                Task { await premium.restorePurchases() }
            } label: {
                Label("Käufe wiederherstellen", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .disabled(premium.isLoading)

            if premium.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            if let errorMessage = premium.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var purchaseButtonTitle: String {
        if let product = premium.premiumProduct {
            return "Premium kaufen \(product.displayPrice)"
        }
        return "Premium kaufen"
    }
}

private struct PremiumFeatureRow: View {
    let symbol: String
    let title: String

    var body: some View {
        Label {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("PrimaryText"))
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(Color("SecondaryAccent"))
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self], inMemory: true)
        .environment(PlayerController())
        .environment(PremiumAccessController())
}
