import SwiftUI

/// `@Observable` (Macro) ersetzt das alte `ObservableObject`-Pattern.
/// Das Modell wird vom Parent (LabHomeView) erzeugt und an diese View
/// weitergereicht. Änderungen sind im Parent sofort sichtbar.
/// Die Sub-View nutzt `@Bindable`, um aus der Observable-Referenz Bindings
/// für Form-Controls (Stepper) abzuleiten.
struct ObservableLessonView: View {
    let counter: LabCounter

    var body: some View {
        VStack(spacing: 24) {
            Text("Schritte: \(counter.steps)")
                .font(.title)
                .contentTransition(.numericText())
                .animation(.snappy, value: counter.steps)

            HStack {
                Button("Schritt machen") { counter.tick() }
                    .buttonStyle(.borderedProminent)
                Button("Reset") { counter.reset() }
                    .buttonStyle(.bordered)
            }

            Divider()

            ObservableLessonStepperView(counter: counter)

            Text("Das Modell lebt in LabHomeView (`@State`). Hier wird es als Referenz benutzt; die Schrittweite wird im Sub-View per `@Bindable` an einen Stepper gebunden.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("@Observable / @Bindable")
    }
}

@Observable
final class LabCounter {
    var steps: Int = 0
    var stepSize: Int = 1

    func tick() { steps += stepSize }
    func reset() { steps = 0 }
}

/// Sub-View, die das Modell per `@Bindable` empfängt und die Schrittweite bindet.
private struct ObservableLessonStepperView: View {
    @Bindable var counter: LabCounter

    var body: some View {
        Stepper(value: $counter.stepSize, in: 1...10) {
            Text("Schrittweite: \(counter.stepSize)")
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack { ObservableLessonView(counter: LabCounter()) }
}
