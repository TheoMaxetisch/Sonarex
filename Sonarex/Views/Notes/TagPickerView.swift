import SwiftUI
import SwiftData

/// Wählt Tags zu einer Notiz aus oder legt neue an.
/// Demonstriert `@Query` ein zweites Mal (für Tags) und zeigt,
/// wie der `@Attribute(.unique)`-Constraint App-seitig vorab geprüft wird.
struct TagPickerView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var newTagName = ""

    var body: some View {
        Form {
            Section("Neuer Tag") {
                HStack {
                    TextField("Name", text: $newTagName)
                    Button("Hinzufügen") { addTag() }
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Verfügbar") {
                if allTags.isEmpty {
                    Text("Noch keine Tags angelegt.")
                        .foregroundStyle(Color("SecondaryText"))
                } else {
                    ForEach(allTags) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if isAttached(tag) {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { toggle(tag) }
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fertig") { dismiss() }
            }
        }
    }

    private func isAttached(_ tag: Tag) -> Bool {
        note.tags?.contains { $0.id == tag.id } ?? false
    }

    private func toggle(_ tag: Tag) {
        if isAttached(tag) {
            note.tags?.removeAll { $0.id == tag.id }
        } else {
            if note.tags == nil { note.tags = [] }
            note.tags?.append(tag)
        }
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Wegen @Attribute(.unique) auf Tag.name würde ein Duplikat-Insert
        // einen Upsert auslösen. Wir prüfen vorher, um Verwirrung zu vermeiden.
        if !allTags.contains(where: { $0.name == trimmed }) {
            let tag = Tag(name: trimmed)
            context.insert(tag)
            if note.tags == nil { note.tags = [] }
            note.tags?.append(tag)
        }
        newTagName = ""
    }
}
