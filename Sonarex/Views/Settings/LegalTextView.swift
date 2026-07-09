import SwiftUI

struct LegalTextView: View {
    let title: String
    let resource: String

    @State private var text: String = ""
    @State private var didLoadText = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 34)
        }
        .background(Color("AppBackground"))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !didLoadText else { return }
            text = loadResource(resource) ?? ""
            didLoadText = true
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            SettingsIcon(systemImage: iconName, tint: tint)
                .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SonarexTypography.screenTitle)
                    .foregroundStyle(Color("PrimaryText"))
                    .lineLimit(1)

                Text(subtitle)
                    .font(SonarexTypography.secondaryEmphasis)
                    .foregroundStyle(Color("SecondaryText"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var content: some View {
        if text.isEmpty {
            emptyState
        } else {
            legalBody
        }
    }

    private var legalBody: some View {
        Text(text)
            .font(SonarexTypography.body)
            .lineSpacing(5)
            .foregroundStyle(Color("PrimaryText"))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color("GlassDivider").opacity(0.7), lineWidth: 1)
            }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsIcon(systemImage: "exclamationmark.triangle.fill", tint: Color("FeedRose"))

            Text("Text nicht gefunden")
                .font(SonarexTypography.sectionTitle)
                .foregroundStyle(Color("PrimaryText"))

            Text("Bitte lege `Resources/\(resource).txt` im App-Bundle an.")
                .font(SonarexTypography.secondary)
                .foregroundStyle(Color("SecondaryText"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color("GlassDivider").opacity(0.7), lineWidth: 1)
        }
    }

    private var subtitle: String {
        switch resource {
        case "AGB":
            "Nutzungsbedingungen"
        case "Privacy":
            "Daten und Privatsphäre"
        default:
            "Rechtlicher Hinweis"
        }
    }

    private var iconName: String {
        switch resource {
        case "Privacy":
            "hand.raised.fill"
        default:
            "doc.text.fill"
        }
    }

    private var tint: Color {
        switch resource {
        case "Privacy":
            Color("FeedMint")
        default:
            Color("FeedGray")
        }
    }

    private func loadResource(_ name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
