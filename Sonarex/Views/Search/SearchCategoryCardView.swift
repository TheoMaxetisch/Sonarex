import SwiftUI

/// Visuelle Genre-Kachel; ein Tap uebernimmt den Kategorienamen in die Suche.
struct SearchCategoryCardView: View {
    let category: SearchCategory
    let action: () -> Void

    init(category: SearchCategory, action: @escaping () -> Void = {}) {
        self.category = category
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Der Gradient macht Kategorien unterscheidbar, ohne externe Bildassets zu benoetigen.
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(category.gradient)

                Image(systemName: category.systemImage)
                    // Grosses, blasses Symbol dient nur als Orientierung und wird von VoiceOver ignoriert.
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color("InverseText").opacity(0.22))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(14)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    // Titel und Songanzahl bleiben unten, damit sie auf allen Karten gleich scanbar sind.
                    Text(category.title)
                        .font(SonarexTypography.sectionTitle)
                        .foregroundStyle(Color("InverseText"))
                        .lineLimit(1)

                    Text(category.subtitle)
                        .font(SonarexTypography.metadata)
                        .foregroundStyle(Color("InverseText").opacity(0.78))
                        .lineLimit(2)
                }
                .padding(14)
            }
            .aspectRatio(1.2, contentMode: .fit)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Kategorie \(category.title)")
        .accessibilityValue(category.subtitle)
        .accessibilityHint("Filtert die Suche nach dieser Kategorie.")
    }
}

#Preview {
    SearchCategoryCardView(category: SearchCategory.preview)
        .padding()
}
