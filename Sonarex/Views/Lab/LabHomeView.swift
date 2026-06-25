import SwiftUI

/// Übersicht der State-Management-Demos.
///
/// Die Parent-View hält selbst State und gibt ihn an die Child-Lessons weiter. Die Zeilen zeigen die aktuellen Werte live —
/// so wird sichtbar, welche Pattern den State zwischen Parent und Child teilen
/// (`@Binding`, `@Observable`+`@Bindable`) und welche nicht (`@State`).
struct LabHomeView: View {

    // Diese States werden an Child-Lessons durchgereicht — Änderungen
    // im Child sind hier in der Liste sofort sichtbar.
    @State private var sharedTemperature: Double = 20.0
    @State private var sharedCounter = LabCounter()

    var body: some View {
        NavigationStack {
            List {
                Section("State Management") {
                    NavigationLink {
                        StateLessonView()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("@State – lokal in der Lesson")
                            Text("Wert ist privat zur Lesson, hier nicht sichtbar")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    NavigationLink {
                        BindingLessonView(temperature: $sharedTemperature)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("@Binding – Parent ↔ Child")
                                Text("Wert lebt im Parent")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text("\(sharedTemperature, format: .number.precision(.fractionLength(1))) °C")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        ObservableLessonView(counter: sharedCounter)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("@Observable + @Bindable")
                                Text("Modell lebt im Parent")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text("\(sharedCounter.steps) Schritte")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("UI") {
                    NavigationLink("Liquid Glass Showcase") {
                        GlassEffectLessonView()
                    }
                }

                Section {
                    Text("Tipp: Öffne eine Lesson, ändere den Wert, gehe zurück. Bei @Binding und @Observable siehst du die Änderung in dieser Liste — bei @State nicht, weil der Wert privat zur Lesson bleibt.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Lab")
        }
    }
}

#Preview {
    LabHomeView()
}
