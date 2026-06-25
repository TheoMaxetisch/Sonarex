import Testing
import SwiftData
import Foundation
@testable import Sonarex

// `Tag` ist sowohl in Swift Testing (für Test-Tags) als auch in unserem
// Modell definiert. Daher in dieser Datei mit dem Modulnamen qualifizieren:
// `Sonarex.Tag`. Note/Reminder sind eindeutig und brauchen keine Qualifikation.
private typealias NoteTag = Sonarex.Tag

@MainActor
struct NoteModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Note.self, NoteTag.self, Reminder.self,
            configurations: config
        )
    }

    @Test func createNote() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let note = Note(title: "Hallo", body: "Welt")
        context.insert(note)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Note>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Hallo")
        #expect(fetched.first?.body == "Welt")
    }

    @Test func tagRelationship() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let note = Note(title: "Mit Tag")
        let tag = NoteTag(name: "Wichtig")
        context.insert(note)
        context.insert(tag)
        note.tags = [tag]
        try context.save()

        #expect(note.tags?.count == 1)
        #expect(tag.notes?.contains(where: { $0.id == note.id }) == true)
    }

    @Test func reminderCascadeDelete() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let note = Note(title: "Mit Reminder")
        let reminder = Reminder(dueDate: .now)
        context.insert(note)
        context.insert(reminder)
        reminder.note = note
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Reminder>()).count == 1)

        context.delete(note)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Reminder>()).count == 0)
    }

    @Test func tagNameUniqueUpsert() throws {
        // Mit @Attribute(.unique) führt SwiftData ein Upsert durch:
        // Ein zweites Insert mit gleichem `name` aktualisiert den existierenden
        // Eintrag, statt einen neuen anzulegen. Der Count bleibt also 1.
        let container = try makeContainer()
        let context = container.mainContext

        context.insert(NoteTag(name: "Persönlich"))
        try context.save()
        context.insert(NoteTag(name: "Persönlich"))
        try context.save()

        let tags = try context.fetch(FetchDescriptor<NoteTag>())
        #expect(tags.count == 1)
    }
}
