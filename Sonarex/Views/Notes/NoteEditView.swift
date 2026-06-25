import SwiftUI
import SwiftData
import PhotosUI

/// Editor für eine Notiz. Demonstriert:
/// - `@Bindable` auf SwiftData-Modell → Felder schreiben direkt in den Store
/// - `PhotosPicker` als moderner, permission-freier Bild-Input
/// - `@Attribute(.externalStorage)` ist transparent: einfach `note.image = data`
struct NoteEditView: View {
    @Bindable var note: Note
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var showTagPicker = false

    var body: some View {
        Form {
            Section("Titel & Text") {
                TextField("Titel", text: $note.title)
                TextField("Beschreibung", text: $note.body, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Bild") {
                if let data = note.image, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
                let pickerLabel = note.image == nil ? "Bild auswählen" : "Bild ersetzen"
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(pickerLabel, systemImage: "photo")
                }
                if note.image != nil {
                    Button(role: .destructive) {
                        note.image = nil
                    } label: {
                        Label("Bild entfernen", systemImage: "trash")
                    }
                }
            }

            Section("Tags") {
                if let tags = note.tags, !tags.isEmpty {
                    ForEach(tags) { tag in
                        Text(tag.name)
                    }
                }
                Button {
                    showTagPicker = true
                } label: {
                    Label("Tags verwalten", systemImage: "tag")
                }
            }

            Section("Reminder") {
                if let reminders = note.reminders {
                    ForEach(reminders.sorted(by: { $0.dueDate < $1.dueDate })) { reminder in
                        ReminderRow(reminder: reminder) {
                            context.delete(reminder)
                        }
                    }
                }
                Button {
                    let reminder = Reminder(dueDate: .now.addingTimeInterval(3600))
                    reminder.note = note
                    context.insert(reminder)
                } label: {
                    Label("Reminder hinzufügen", systemImage: "bell.badge.fill")
                }
            }
        }
        .navigationTitle("Bearbeiten")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fertig") { dismiss() }
            }
        }
        .sheet(isPresented: $showTagPicker) {
            NavigationStack {
                TagPickerView(note: note)
            }
        }
        .task(id: photoItem) {
            guard let item = photoItem else { return }
            if let data = try? await item.loadTransferable(type: Data.self) {
                note.image = data
            }
        }
    }
}

private struct ReminderRow: View {
    @Bindable var reminder: Reminder
    var onDelete: () -> Void

    var body: some View {
        HStack {
            Button {
                reminder.isCompleted.toggle()
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.borderless)

            DatePicker(
                "",
                selection: $reminder.dueDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}
