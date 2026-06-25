import SwiftUI
import SwiftData

/// Read-only Detail-Ansicht. Editieren erfolgt im Sheet via `NoteEditView`.
struct NoteDetailView: View {
    let note: Note
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let data = note.image, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(note.body.isEmpty ? "Keine Beschreibung." : note.body)
                    .font(.body)

                if let tags = note.tags, !tags.isEmpty {
                    SectionHeader("Tags")
                    HStack {
                        ForEach(tags) { tag in
                            Text(tag.name)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .glassEffect(.regular.tint(Color("AccentColor")), in: .capsule)
                        }
                    }
                }

                if let reminders = note.reminders, !reminders.isEmpty {
                    SectionHeader("Reminder")
                    ForEach(reminders.sorted(by: { $0.dueDate < $1.dueDate })) { reminder in
                        HStack {
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(reminder.dueDate, format: .dateTime.day().month().hour().minute())
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(note.title.isEmpty ? "(ohne Titel)" : note.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bearbeiten") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                NoteEditView(note: note)
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("SecondaryText"))
            .padding(.top, 8)
    }
}
