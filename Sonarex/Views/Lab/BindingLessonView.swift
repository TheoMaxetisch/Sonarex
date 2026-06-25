import SwiftUI

/// `@Binding`: Der Wert wohnt im Parent (LabHomeView), diese View und ihr
/// Child arbeiten mit derselben Quelle. Änderungen propagieren bidirektional.
struct BindingLessonView: View {
    @Binding var temperature: Double

    var body: some View {
        VStack(spacing: 32) {
            VStack {
                Text("Dieser Wert lebt in LabHomeView")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(temperature, format: .number.precision(.fractionLength(1))) °C")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            BindingChildSliderView(value: $temperature)

            Text("Slider und Anzeige im Child binden auf denselben State im Parent. Beim Zurück-Wischen siehst du den geänderten Wert in der Lab-Liste.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("@Binding")
    }
}

/// Grandchild-View. Bekommt den Wert per `@Binding` weitergereicht.
private struct BindingChildSliderView: View {
    @Binding var value: Double

    var body: some View {
        VStack {
            Text("Child (Slider)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Slider(value: $value, in: -10...40, step: 0.5)
        }
        .padding()
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var t: Double = 20
    NavigationStack { BindingLessonView(temperature: $t) }
}
