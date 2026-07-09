import SwiftUI

/// Grosser Einstieg im Feed mit taeglichem Featured Track und direkter Play-Aktion.
struct HeroHeaderView: View {
    let featuredTrack: Track
    let playAction: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Das Hero-Artwork ist eine generierte Flaeche aus Track-Farben, nicht von Netzwerkbildern abhaengig.
            RoundedRectangle(cornerRadius: 45)
                .fill(featuredTrack.heroGradient)
                .overlay {
                    // Dunkler Verlauf erhoeht den Textkontrast im unteren Bereich.
                    LinearGradient(
                        colors: [
                            Color("FeedBlack").opacity(0.38),
                            Color("FeedBlack").opacity(0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 45, style: .continuous))
                }

            VStack(alignment: .leading, spacing: 18) {
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Featured Track", systemImage: "sparkles")
                        .font(SonarexTypography.metadata)
                        .textCase(.uppercase)
                        .foregroundStyle(Color("InverseText").opacity(0.78))
                        .accessibilityHidden(true)

                    Text(featuredTrack.title)
                        .font(SonarexTypography.heroTitle)
                        .lineLimit(2)

                    Text(featuredTrack.artist)
                        .font(SonarexTypography.heroSubtitle)
                        .foregroundStyle(Color("InverseText").opacity(0.82))
                }

                ViewThatFits(in: .horizontal) {
                    // Auf schmalen Breiten stapeln sich die Aktionen automatisch.
                    HStack(spacing: 12) {
                        heroPlayButton
                        heroAddButton
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        heroPlayButton
                        heroAddButton
                    }
                }
            }
            .foregroundStyle(Color("InverseText"))
            .padding(24)
        }
        .frame(height: 360)
        .overlay(alignment: .topTrailing) {
            // Das grosse Symbol ist rein dekorativ und deshalb fuer Accessibility ausgeblendet.
            Image(systemName: featuredTrack.artworkSymbol)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color("InverseText").opacity(0.22))
                .padding(.top, 74)
                .padding(.trailing, 24)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .contain)
    }

    private var heroPlayButton: some View {
        // Primaere Aktion startet den Track sofort und oeffnet danach den Player.
        Button(action: playAction) {
            Label("Abspielen", systemImage: "play.fill")
                .font(SonarexTypography.action)
                .foregroundStyle(Color("FeedBlack"))
                .frame(height: 46)
                .padding(.horizontal, 18)
                .background(Color("InverseText"), in: Capsule())
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(featuredTrack.title) von \(featuredTrack.artist) abspielen")
        .accessibilityHint("Startet den Featured Track.")
    }

    private var heroAddButton: some View {
        // Platzhalter fuer spaetere Bibliotheksaktion; aktuell bewusst nicht funktional.
        Button {
        } label: {
            Image(systemName: "plus")
                .font(SonarexTypography.action)
                .foregroundStyle(Color("InverseText"))
                .frame(width: 46, height: 46)
                .background(Color("FeedBlack"), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Zur Bibliothek hinzufügen")
        .accessibilityHint("Diese Aktion ist noch nicht verfügbar.")
    }
}
