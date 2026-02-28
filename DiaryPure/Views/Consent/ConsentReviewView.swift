import SwiftUI

struct ConsentReviewView: View {
    let agreementText: String
    let onSign: () -> Void

    var body: some View {
        ScrollView {
            Text(agreementText)
                .font(.body)
                .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onSign) {
                Text("Sign & Start Session")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Review Agreement")
        .navigationBarTitleDisplayMode(.inline)
    }
}
