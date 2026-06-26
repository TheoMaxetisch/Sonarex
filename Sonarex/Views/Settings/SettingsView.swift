import SwiftUI
import SwiftData
import MessageUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("prefersDarkMode") private var prefersDarkMode = false
    @Query private var serverProfiles: [ServerProfile]

    @State private var serverPassword = ""
    @State private var credentialMessage: SettingsStatus?
    @State private var syncMessage: SettingsStatus?
    @State private var isSyncingLibrary = false
    @State private var presentedSheet: SettingsSheet?
    @State private var isMailComposerPresented = false

    private let email = "sonarex@web.de"
    private let subject = "Sonarex Feedback"

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    heroHeader
                    appearanceGroup
                    serverGroup
                    legalGroup
                    contactGroup
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
            .background(Color("AppBackground"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: activeServer?.id) {
            loadPassword()
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .server:
                serverEditor
            case .login:
                loginEditor
            }
        }
        .sheet(isPresented: $isMailComposerPresented) {
            MailComposerView(recipient: email, subject: subject)
        }
    }

    private var heroHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("SecondaryAccent"), Color("FeedMint"), Color("FeedRose")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("InverseText"))
            }
            .frame(width: 58, height: 58)

            Text("Einstellungen")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color("PrimaryText"))
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var appearanceGroup: some View {
        SettingsGroup("Darstellung") {
            SettingsRow(
                title: "Dunkles Design",
                subtitle: prefersDarkMode ? "Aktiviert" : "Deaktiviert",
                systemImage: prefersDarkMode ? "moon.fill" : "sun.max.fill",
                tint: prefersDarkMode ? Color("FeedIndigo") : Color("FeedYellow")
            ) {
                Toggle("Dunkles Design", isOn: $prefersDarkMode)
                    .labelsHidden()
                    .tint(Color("SecondaryAccent"))
            }
        }
    }

    private var serverGroup: some View {
        SettingsGroup("Navidrome") {
            Button {
                presentedSheet = .server
            } label: {
                SettingsRow(title: "Server", subtitle: serverURLSubtitle, systemImage: "server.rack", tint: Color("FeedAqua")) {
                    Chevron()
                }
            }
            .buttonStyle(.plain)

            Button {
                presentedSheet = .login
            } label: {
                SettingsRow(title: "Login", subtitle: loginSubtitle, systemImage: "person.badge.key.fill", tint: Color("FeedGreen")) {
                    Chevron()
                }
            }
            .buttonStyle(.plain)

            SettingsRow(title: "Bibliothek", subtitle: "Alben und Songs", systemImage: "arrow.triangle.2.circlepath", tint: Color("FeedPurple")) {
                HStack(spacing: 10) {
                    if let syncMessage {
                        SettingsStatusDot(status: syncMessage)
                    }

                    Button(action: syncLibrary) {
                        Image(systemName: isSyncingLibrary ? "hourglass" : "arrow.triangle.2.circlepath")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color("InverseText"))
                            .frame(width: 40, height: 40)
                            .background(Color("SecondaryAccent"), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(activeServer == nil || isSyncingLibrary)
                    .accessibilityLabel("Bibliothek synchronisieren")
                }
            }
        }
    }

    private var serverEditor: some View {
        SettingsSheetView(title: "Server bearbeiten", systemImage: "server.rack", tint: Color("FeedAqua")) {
            SettingsEditorField(title: "Servername") {
                TextField("Navidrome", text: serverNameBinding)
                    .settingsFieldStyle()
            }

            SettingsEditorField(title: "Server URL") {
                TextField("https://navidrome.example.com", text: serverURLBinding)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .settingsFieldStyle()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var loginEditor: some View {
        SettingsSheetView(title: "Login bearbeiten", systemImage: "person.badge.key.fill", tint: Color("FeedGreen")) {
            SettingsEditorField(title: "Benutzername") {
                TextField("Benutzername", text: serverUsernameBinding)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .settingsFieldStyle()
            }

            SettingsEditorField(title: "Passwort") {
                SecureField("Passwort", text: $serverPassword)
                    .textContentType(.password)
                    .settingsFieldStyle()
                    .onSubmit(saveCredentials)
            }

            SettingsActionButton(
                title: "Zugangsdaten speichern",
                systemImage: "key.fill",
                isDisabled: activeServer == nil,
                action: saveCredentials
            )

            if let credentialMessage {
                SettingsStatusLabel(status: credentialMessage)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var legalGroup: some View {
        SettingsGroup("Rechtliches") {
            NavigationLink {
                LegalTextView(title: "AGB", resource: "AGB")
            } label: {
                SettingsRow(title: "AGB", subtitle: "Nutzungsbedingungen", systemImage: "doc.text", tint: Color("FeedGray")) {
                    Chevron()
                }
            }
            .buttonStyle(.plain)

            NavigationLink {
                LegalTextView(title: "Datenschutz", resource: "Privacy")
            } label: {
                SettingsRow(title: "Datenschutz", subtitle: "Daten und Privatsphäre", systemImage: "hand.raised.fill", tint: Color("FeedMint")) {
                    Chevron()
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var contactGroup: some View {
        SettingsGroup("Kontakt") {
            SettingsRow(title: "E-Mail", subtitle: email, systemImage: "envelope.fill", tint: Color("FeedOrange")) {
                Button(action: openMailComposer) {
                    Image(systemName: "paperplane.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color("SecondaryAccent"))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("E-Mail schreiben")
            }

            SettingsRow(title: "Version", subtitle: "\(shortVersion) (\(build))", systemImage: "info.circle.fill", tint: Color("FeedBlue")) {
                EmptyView()
            }
        }
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

    private var serverNameBinding: Binding<String> {
        Binding(
            get: { activeServer?.name ?? "" },
            set: { activeServer?.name = $0 }
        )
    }

    private var serverUsernameBinding: Binding<String> {
        Binding(
            get: { activeServer?.username ?? "" },
            set: { activeServer?.username = $0 }
        )
    }

    private var serverURLSubtitle: String {
        activeServer?.baseURL.isEmpty == false ? "Verbunden ueber Subsonic API" : "Noch keine URL gesetzt"
    }

    private var loginSubtitle: String {
        activeServer?.username.isEmpty == false ? "Zugangsdaten gespeichert" : "Noch nicht eingerichtet"
    }

    private func loadPassword() {
        credentialMessage = nil
        guard let activeServer else {
            serverPassword = ""
            return
        }

        do {
            serverPassword = try KeychainCredentialStore.password(for: activeServer.id) ?? ""
        } catch {
            serverPassword = ""
            credentialMessage = .error(error.localizedDescription)
        }
    }

    private func saveCredentials() {
        guard let activeServer else { return }
        do {
            try KeychainCredentialStore.savePassword(serverPassword, for: activeServer.id)
            credentialMessage = .success(serverPassword.isEmpty ? "Passwort entfernt." : "Zugangsdaten gespeichert.")
        } catch {
            credentialMessage = .error(error.localizedDescription)
        }
    }

    private func syncLibrary() {
        guard let activeServer else { return }
        isSyncingLibrary = true
        syncMessage = .working("Bibliothek wird synchronisiert...")

        Task {
            do {
                try KeychainCredentialStore.savePassword(serverPassword, for: activeServer.id)
                let result = try await NavidromeLibrarySyncService.sync(
                    server: activeServer,
                    password: serverPassword,
                    context: modelContext
                )
                syncMessage = .success("\(result.albumCount) Alben und \(result.trackCount) Songs importiert.")
            } catch {
                syncMessage = .error(error.localizedDescription)
            }
            isSyncingLibrary = false
        }
    }

    private func openMailComposer() {
        if MFMailComposeViewController.canSendMail() {
            isMailComposerPresented = true
        } else {
            UIApplication.shared.open(mailURL)
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

#Preview {
    SettingsView()
}
