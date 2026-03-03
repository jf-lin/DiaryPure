import AuthenticationServices
import SwiftUI

struct SignoutView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        VStack(spacing: 32) {
            Button(role: .destructive) {
                authService.signOut()
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Spacer().frame(height: 60)
        }
        .padding()
    }
}
