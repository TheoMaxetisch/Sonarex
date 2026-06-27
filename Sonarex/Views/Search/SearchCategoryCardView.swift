//
//  SearchCategoryCardView.swift
//  Sonarex
//
//  Created by Michael Wedel on 11.05.26.
//

import SwiftUI

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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(category.gradient)

                Image(systemName: category.systemImage)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Color("InverseText").opacity(0.22))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(14)

                VStack(alignment: .leading, spacing: 6) {
                    Text(category.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("InverseText"))
                        .lineLimit(1)

                    Text(category.subtitle)
                        .font(.caption.weight(.semibold))
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
    }
}

#Preview {
    SearchCategoryCardView(category: SearchCategory.preview)
        .padding()
}
