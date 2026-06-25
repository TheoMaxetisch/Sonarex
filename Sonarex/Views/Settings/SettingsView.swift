import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("prefersDarkMode") private var prefersDarkMode = false
    @Query private var serverProfiles: [ServerProfile]
    @State private var serverPassword = ""
    @State private var credentialMessage: String?
    @State private var credentialSaveSucceeded = false
    @State private var syncMessage: String?
    @State private var syncSucceeded = false
    @State private var isSyncingLibrary = false

    private let email = "support@example.com"
    private let subject = "Sonarex Feedback"

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    SettingsSection(title: "Darstellung") {
                        SettingsToggleRow(
                            title: "Dunkles Design",
                            subtitle: prefersDarkMode ? "Aktiviert" : "Deaktiviert",
                            systemImage: prefersDarkMode ? "moon.fill" : "sun.max.fill",
                            isOn: $prefersDarkMode
                        )
                    }

                    SettingsSection(title: "Server") {
                        SettingsTextFieldRow(
                            title: "Subsonic Server",
                            placeholder: "https://navidrome.wedel.dev",
                            systemImage: "server.rack",
                            text: serverURLBinding
                        )

                        SettingsDivider()

                        ServerCredentialsRow(
                            username: serverUsernameBinding,
                            password: $serverPassword,
                            message: credentialMessage,
                            saveSucceeded: credentialSaveSucceeded,
                            isEnabled: activeServer != nil,
                            saveAction: saveCredentials
                        )

                        SettingsDivider()

                        ServerSyncRow(
                            message: syncMessage,
                            syncSucceeded: syncSucceeded,
                            isSyncing: isSyncingLibrary,
                            isEnabled: activeServer != nil,
                            syncAction: syncLibrary
                        )
                    }

                    SettingsSection(title: "Rechtliches") {
                        NavigationLink {
                            LegalTextView(title: "AGB", resource: "AGB")
                        } label: {
                            SettingsNavigationRow(
                                title: "AGB",
                                subtitle: "Nutzungsbedingungen",
                                systemImage: "doc.text"
                            )
                        }
                        .buttonStyle(.plain)

                        SettingsDivider()

                        NavigationLink {
                            LegalTextView(title: "Datenschutz", resource: "Privacy")
                        } label: {
                            SettingsNavigationRow(
                                title: "Datenschutz",
                                subtitle: "Umgang mit deinen Daten",
                                systemImage: "hand.raised"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    SettingsSection(title: "Kontakt") {
                        SettingsInfoRow(
                            title: "E-Mail",
                            value: email,
                            systemImage: "envelope"
                        )

                        SettingsDivider()

                        Link(destination: mailURL) {
                            SettingsNavigationRow(
                                title: "E-Mail schreiben",
                                subtitle: "Feedback an Sonarex senden",
                                systemImage: "paperplane.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    SettingsSection(title: "Ueber") {
                        SettingsInfoRow(title: "App", value: "Sonarex", systemImage: "music.note")
                        SettingsDivider()
                        SettingsInfoRow(title: "Version", value: shortVersion, systemImage: "number")
                        SettingsDivider()
                        SettingsInfoRow(title: "Build", value: build, systemImage: "hammer")
                    }

                    footer
                }
                .padding(.bottom, 32)
            }
            .background(Color("AppBackground"))
        }
        .task(id: activeServer?.id) {
            loadPassword()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Einstellungen")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color("PrimaryText"))

            Text("App, Design und rechtliche Infos.")
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var footer: some View {
        Text("MSD-Lehr-Template fuer iOS 26 / Swift 6.3.")
            .font(.footnote)
            .foregroundStyle(Color("SecondaryText"))
            .padding(.horizontal, 20)
    }

    private var activeServer: ServerProfile? {
        serverProfiles.first(where: \.isActive) ?? serverProfiles.first
    }

    private var serverURLBinding: Binding<String> {
        Binding(
            get: { activeServer?.baseURL ?? "" },
            set: { activeServer?.baseURL = $0 }
        )
    }

    private var serverUsernameBinding: Binding<String> {
        Binding(
            get: { activeServer?.username ?? "" },
            set: { activeServer?.username = $0 }
        )
    }

    private func loadPassword() {
        credentialMessage = nil
        credentialSaveSucceeded = false
        guard let activeServer else {
            serverPassword = ""
            return
        }

        do {
            serverPassword = try KeychainCredentialStore.password(for: activeServer.id) ?? ""
        } catch {
            serverPassword = ""
            credentialMessage = error.localizedDescription
        }
    }

    private func saveCredentials() {
        guard let activeServer else { return }
        do {
            try KeychainCredentialStore.savePassword(serverPassword, for: activeServer.id)
            credentialSaveSucceeded = true
            credentialMessage = serverPassword.isEmpty
                ? "Passwort aus der Keychain entfernt."
                : "Zugangsdaten sicher gespeichert."
        } catch {
            credentialSaveSucceeded = false
            credentialMessage = error.localizedDescription
        }
    }

    private func syncLibrary() {
        guard let activeServer else { return }
        isSyncingLibrary = true
        syncMessage = "Bibliothek wird synchronisiert..."
        syncSucceeded = false

        Task {
            do {
                try KeychainCredentialStore.savePassword(serverPassword, for: activeServer.id)
                let result = try await NavidromeLibrarySyncService.sync(
                    server: activeServer,
                    password: serverPassword,
                    context: modelContext
                )
                syncSucceeded = true
                syncMessage = "\(result.albumCount) Alben und \(result.trackCount) Songs importiert."
            } catch {
                syncSucceeded = false
                syncMessage = error.localizedDescription
            }
            isSyncingLibrary = false
        }
    }

    private var mailURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [URLQueryItem(name: "subject", value: subject)]
        return components.url ?? URL(string: "mailto:\(email)")!
    }

    private var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
}

private struct ServerCredentialsRow: View {
    @Binding var username: String
    @Binding var password: String
    let message: String?
    let saveSucceeded: Bool
    let isEnabled: Bool
    let saveAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIcon(systemImage: "person.badge.key.fill")

            VStack(alignment: .leading, spacing: 10) {
                Text("Zugangsdaten")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))

                TextField("Benutzername", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .settingsInputStyle()

                Text("Das Passwort wird sicher in der iOS-Keychain gespeichert und nicht in SwiftData abgelegt.")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)

                SecureField("Passwort", text: $password)
                    .textContentType(.password)
                    .settingsInputStyle()
                    .onSubmit(saveAction)

                Button(action: saveAction) {
                    Label("Zugangsdaten speichern", systemImage: "key.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("SecondaryAccent"))
                .disabled(!isEnabled)

                if let message {
                    Label(
                        message,
                        systemImage: saveSucceeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(saveSucceeded ? Color.green : Color.red)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
    }
}

private struct ServerSyncRow: View {
    let message: String?
    let syncSucceeded: Bool
    let isSyncing: Bool
    let isEnabled: Bool
    let syncAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIcon(systemImage: "arrow.triangle.2.circlepath")

            VStack(alignment: .leading, spacing: 10) {
                Text("Navidrome-Bibliothek")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))

                Text("Alben und Songs ueber die Subsonic API abrufen.")
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: syncAction) {
                    Label(
                        isSyncing ? "Synchronisiere..." : "Bibliothek synchronisieren",
                        systemImage: isSyncing ? "hourglass" : "square.and.arrow.down"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("SecondaryAccent"))
                .disabled(!isEnabled || isSyncing)

                if let message {
                    Label(
                        message,
                        systemImage: syncSucceeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(syncSucceeded ? Color.green : Color.red)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
    }
}

private extension View {
    func settingsInputStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundStyle(Color("PrimaryText"))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Color("GlassSurfaceStrong"),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }
}

private struct SettingsTextFieldRow: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIcon(systemImage: systemImage)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))

                TextField(placeholder, text: $text)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.subheadline)
                    .foregroundStyle(Color("PrimaryText"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color("GlassSurfaceStrong"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color("SecondaryText"))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Server URL leeren")
            }
        }
        .padding(14)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("SecondaryText"))
                .textCase(.uppercase)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content
            }
            .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 20)
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemImage: systemImage)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(Color("SecondaryAccent"))
        }
        .padding(14)
    }
}

private struct SettingsNavigationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemImage: systemImage)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemImage: systemImage)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("PrimaryText"))

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
    }
}

private struct SettingsIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color("InverseText"))
            .frame(width: 36, height: 36)
            .background(Color("SecondaryAccent"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color("GlassDivider"))
            .frame(height: 1)
            .padding(.leading, 62)
    }
}

#Preview {
    SettingsView()
}
