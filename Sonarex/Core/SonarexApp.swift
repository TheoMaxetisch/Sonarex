import SwiftUI
import SwiftData

@main
struct SonarexApp: App {
    @AppStorage("prefersDarkMode") private var prefersDarkMode = false
    @State private var playerController = PlayerController()

    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                ServerProfile.self, Track.self, Playlist.self, PlaylistEntry.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            let container = try ModelContainer(for: schema, configurations: configuration)
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
                .environment(playerController)
        }
        .modelContainer(container)
    }
}
