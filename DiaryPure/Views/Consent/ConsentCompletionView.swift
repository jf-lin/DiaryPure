import SwiftUI

struct ConsentCompletionView: View {
    let onDismiss: () -> Void

    @State private var checkmarkScale = 0.5
    @State private var checkmarkOpacity = 0.0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkOpacity)

            Text("Agreement Signed")
                .font(.title2.bold())

            Text("Both parties have signed. A copy has been saved to your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onDismiss()
            }
        }
    }
}
