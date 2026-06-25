import SwiftUI

/// Lädt einen Plaintext aus dem App-Bundle und stellt ihn dar.
/// `Resources/AGB.txt` und `Resources/Privacy.txt` können ersetzt werden,
/// ohne Code anzufassen.
struct LegalTextView: View {
    let title: String
    let resource: String

    @State private var text: String = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(text.isEmpty ? "(Kein Text gefunden — bitte Resources/\(resource).txt anlegen.)" : text)
                .font(.body)
                .foregroundStyle(Color("PrimaryText"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color("GlassSurface"), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(20)
        }
        .background(Color("AppBackground"))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            text = loadResource(resource) ?? ""
        }
    }

    private func loadResource(_ name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
