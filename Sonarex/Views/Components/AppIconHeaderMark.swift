import SwiftUI

/// Wiederverwendbares App-Icon-Element fuer Header von Feed, Suche, Bibliothek und Settings.
struct AppIconHeaderMark: View {
    var body: some View {
        // Das Icon ist rein dekorativ; Screenreader bekommen die eigentliche Seitueberschrift.
        Image("AppIconHeader")
            .resizable()
            .scaledToFill()
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: Color("FeedBlack").opacity(0.16), radius: 14, y: 7)
            .accessibilityHidden(true)
    }
}
