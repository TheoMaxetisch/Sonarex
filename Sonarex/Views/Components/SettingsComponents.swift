import SwiftUI

/// Einheitlicher Status fuer Speichern, Sync und Fehlermeldungen in den Einstellungen.
enum SettingsStatus {
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
        // Jedes Ergebnis bekommt ein vertrautes SF Symbol fuer schnelles visuelles Feedback.
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
        // Farben sind bewusst semantisch: neutral, Erfolg, Fehler.
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

enum SettingsSheet: String, Identifiable {
    // Identifiable ermoeglicht `.sheet(item:)` fuer Server- und Login-Editor.
    case server
    case login

    var id: String { rawValue }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Gruppenueberschriften strukturieren die Settings ohne eigene Navigationsebene.
            Text(title)
                .font(SonarexSettingsTypography.groupTitle)
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

struct SettingsRow<Accessory: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Links steht immer ein farbiges Icon, rechts ein frei waehlbares Accessory.
            SettingsIcon(systemImage: systemImage, tint: tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(SonarexSettingsTypography.rowTitle)
                    .foregroundStyle(Color("PrimaryText"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(SonarexSettingsTypography.rowSubtitle)
                    .foregroundStyle(Color("SecondaryText"))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .layoutPriority(1)

            Spacer(minLength: 12)

            accessory
                // Accessory-Controls wie Toggle oder Buttons sollen nicht zusammengedrueckt werden.
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}

struct SettingsSheetView<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            // Einheitlicher Sheet-Rahmen fuer Server- und Loginbearbeitung.
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    SettingsIcon(systemImage: systemImage, tint: tint)

                    Text(title)
                        .font(SonarexSettingsTypography.sheetTitle)
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
                    .font(SonarexSettingsTypography.button)
                }
            }
        }
    }
}

struct SettingsEditorField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Editorfelder erhalten eigene Labels, damit Placeholder nicht die einzige Beschreibung sind.
            Text(title)
                .font(SonarexSettingsTypography.groupTitle)
                .foregroundStyle(Color("SecondaryText"))
                .textCase(.uppercase)

            content
        }
    }
}

struct SettingsIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        // Dekoratives Symbol; die eigentliche Accessibility kommt vom umgebenden Row-Text.
        Image(systemName: systemImage)
            .font(SonarexSettingsTypography.icon)
            .foregroundStyle(Color("InverseText"))
            .frame(width: 38, height: 38)
            .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct SettingsActionButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        // Kapselt primaere Sheet-Aktionen mit einheitlicher Groesse und Farbe.
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(SonarexSettingsTypography.button)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("SecondaryAccent"))
        .disabled(isDisabled)
    }
}

struct SettingsStatusDot: View {
    let status: SettingsStatus

    var body: some View {
        // Kompakte Statusanzeige fuer Reihen, in denen kein langer Text Platz hat.
        Image(systemName: status.symbol)
            .font(SonarexSettingsTypography.small)
            .foregroundStyle(status.color)
            .frame(width: 22, height: 22)
            .accessibilityLabel(status.message)
    }
}

struct SettingsStatusLabel: View {
    let status: SettingsStatus

    var body: some View {
        // Ausfuehrlicher Status fuer Editor-Sheets und Fehlermeldungen.
        Label(status.message, systemImage: status.symbol)
            .font(SonarexSettingsTypography.rowSubtitle)
            .foregroundStyle(status.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(SonarexSettingsTypography.small)
            .foregroundStyle(Color("SecondaryText"))
            .accessibilityHidden(true)
    }
}

extension View {
    func settingsFieldStyle() -> some View {
        self
            .font(SonarexSettingsTypography.body)
            .foregroundStyle(Color("PrimaryText"))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Color("GlassSurfaceStrong"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
