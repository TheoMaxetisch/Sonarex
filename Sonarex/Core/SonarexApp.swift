import SwiftUI
import SwiftData

@main
struct SonarexApp: App {
    @AppStorage("prefersDarkMode") private var prefersDarkMode = false
    @State private var playerController = PlayerController()
    @State private var premiumAccess = PremiumAccessController()

    let container: ModelContainer

    init() {
        do {
            // Zentrale SwiftData-Konfiguration fuer alle dauerhaft gespeicherten App-Modelle.
            let schema = Schema([
                ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            let container = try ModelContainer(for: schema, configurations: configuration)
            // Demo-Daten und Migrationen laufen beim Start, damit die App sofort vorfuehrbar bleibt.
            try DemoMusicSeeder.seedIfNeeded(in: container.mainContext)
            try LibraryStateMigration.resetAutoSavedPlaylistsIfNeeded(in: container.mainContext)
            self.container = container
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Color("AccentColor"))
                .preferredColorScheme(prefersDarkMode ? .dark : nil)
                // Player und Premium-Status werden als Environment-Objekte appweit geteilt.
                .environment(playerController)
                .environment(premiumAccess)
                .task {
                    await premiumAccess.refresh()
                }
        }
        .modelContainer(container)
    }
}
