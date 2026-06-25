import SwiftUI

/// `@State` ist lokal zur View. Die Parent-View (LabHomeView) sieht diesen
/// Wert nicht — beim Zurückblättern bleibt er privat hier. Vergleiche mit der
/// `@Binding`-Lesson, wo der Wert geteilt wird.
struct StateLessonView: View {
    @State private var count: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("\(count)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: count)

            HStack {
                Button("−") { count -= 1 }
                Button("Reset") { count = 0 }
                Button("+") { count += 1 }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Dieser Counter lebt nur in dieser View. Geh zurück zur Lab-Liste — die Lab-View kennt den Wert nicht.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("@State")
    }
}

#Preview {
    NavigationStack { StateLessonView() }
}
