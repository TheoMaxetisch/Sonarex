import SwiftUI

/// Showcase für den Liquid-Glass-Modifier `.glassEffect()` aus iOS 26.
struct GlassEffectLessonView: View {
    var body: some View {
        ZStack {
            
            // Farbiger Hintergrund, damit der Glas-Effekt sichtbar wird.
            LinearGradient(
                colors: [.purple, .blue, .teal, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(title: ".glassEffect()") {
                        Text("Standard")
                            .padding()
                            .glassEffect()
                    }
                    GlassCard(title: ".glassEffect(.regular, in: .capsule)") {
                        Text("Capsule-Form")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .glassEffect(.regular, in: .capsule)
                    }
                    GlassCard(title: ".glassEffect(.regular.tint(.orange))") {
                        Text("Getönt")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .glassEffect(.regular.tint(.orange), in: .capsule)
                    }
                    GlassCard(title: ".glassEffect(.regular.interactive())") {
                        Button("Tippen") { }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Liquid Glass")
    }
}

private struct GlassCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.monospaced())
                .foregroundStyle(.white.opacity(0.85))
            content()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.15), in: .rect(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack { GlassEffectLessonView() }
}
