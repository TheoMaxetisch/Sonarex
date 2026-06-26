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

            VStack(alignment: .leading, spacing: 4) {
                Text("Einstellungen")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color("PrimaryText"))
                    .lineLimit(1)

                Text("App, Design und Verbindung")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("SecondaryText"))
                    .lineLimit(1)
            }

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

private enum SettingsStatus {
    case working(String)
    case success(String)
    case error(String)

    var message: String {
        switch self {
        case .working(let message), .success(let message), .error(let message):
            message
        }
    }

    var symbol: String {
        switch self {
        case .working:
            "hourglass"
        case .success:
            "checkmark.circle.fill"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .working:
            Color("SecondaryText")
        case .success:
            Color.green
        case .error:
            Color.red
        }
    }
}

private enum SettingsSheet: String, Identifiable {
    case server
    case login

    var id: String { rawValue }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("SecondaryText"))
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content
            }
            .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color("GlassDivider").opacity(0.7), lineWidth: 1)
            }
        }
    }
}

private struct SettingsSheetView<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    SettingsIcon(systemImage: systemImage, tint: tint)

                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("PrimaryText"))

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 14) {
                    content
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color("AppBackground"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
    }
}

private struct SettingsEditorField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("SecondaryText"))
                .textCase(.uppercase)

            content
        }
    }
}

private struct SettingsRow<Accessory: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SettingsIcon(systemImage: systemImage, tint: tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            accessory
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}

private struct SettingsStatusDot: View {
    let status: SettingsStatus

    var body: some View {
        Image(systemName: status.symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(status.color)
            .frame(width: 22, height: 22)
            .accessibilityLabel(status.message)
    }
}

private struct MailComposerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let recipient: String
    let subject: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismissAction: @MainActor @Sendable () -> Void

        init(dismiss: DismissAction) {
            self.dismissAction = { dismiss() }
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: (any Error)?
        ) {
            let dismissAction = dismissAction
            Task { @MainActor in
                dismissAction()
            }
        }
    }
}

private struct SettingsIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color("InverseText"))
            .frame(width: 38, height: 38)
            .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SettingsActionButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("SecondaryAccent"))
        .disabled(isDisabled)
    }
}

private struct SettingsStatusLabel: View {
    let status: SettingsStatus

    var body: some View {
        Label(status.message, systemImage: status.symbol)
            .font(.caption)
            .foregroundStyle(status.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color("SecondaryText"))
    }
}

private extension View {
    func settingsFieldStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundStyle(Color("PrimaryText"))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Color("GlassSurfaceStrong"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    SettingsView()
}
