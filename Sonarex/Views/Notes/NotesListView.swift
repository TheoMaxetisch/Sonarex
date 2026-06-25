import SwiftUI
import SwiftData

/// Hauptliste aller Notizen. Demonstriert:
/// - `@Query` für SwiftData
/// - `NavigationStack` + `.navigationDestination(for:)`
/// - Floating-Button mit Liquid-Glass (`.glassEffect`)
struct NotesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]

    @State private var editingNote: Note?

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Notizen",
                        systemImage: "note.text",
                        description: Text("Tippe rechts unten auf das Plus, um deine erste Notiz anzulegen.")
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            NavigationLink(value: note) {
                                NoteRowView(note: note)
                            }
                        }
                        .onDelete(perform: deleteNotes)
                    }
                }
            }
            .navigationTitle("Notizen")
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note)
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    let note = Note(title: "Neue Notiz")
                    context.insert(note)
                    editingNote = note
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .padding()
            }
            .sheet(item: $editingNote) { note in
                NavigationStack {
                    NoteEditView(note: note)
                }
            }
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            context.delete(notes[index])
        }
    }
}

private struct NoteRowView: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            if let data = note.image, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.tertiary)
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "note.text").foregroundStyle(Color("SecondaryText")))
            }
            VStack(alignment: .leading) {
                Text(note.title.isEmpty ? "(ohne Titel)" : note.title)
                    .font(.headline)
                Text(note.createdAt, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotesListView()
        .modelContainer(for: [Note.self, Tag.self, Reminder.self], inMemory: true)
}
