import SwiftUI

struct AppIconHeaderMark: View {
    var body: some View {
        Image("AppIconHeader")
            .resizable()
            .scaledToFill()
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color("GlassDivider").opacity(0.55), lineWidth: 1)
            }
            .shadow(color: Color("FeedBlack").opacity(0.16), radius: 14, y: 7)
            .accessibilityHidden(true)
    }
}
