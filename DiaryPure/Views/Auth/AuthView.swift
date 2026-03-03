import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                Text("DiaryPure")
                    .font(.largeTitle.bold())
                Text("Your private diary & consent journal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                authService.handleSignIn(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)

            #if DEBUG
            Button("Continue without signing in") {
                authService.skipSignIn()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            #endif

            Spacer()
                .frame(height: 60)
        }
    }
}
