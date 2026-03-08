import AuthenticationServices
import LocalAuthentication
import SwiftUI

final class AuthService: ObservableObject {
    @Published var isSignedIn = false
    @Published var userID: String?
    @Published var userName: String?
    @Published var isLocked = false

    private let userIDKey = "appleUserID"

    init() {
        if let savedID = UserDefaults.standard.string(forKey: userIDKey) {
            self.userID = savedID
            self.isSignedIn = true
        }
        if let savedName = UserDefaults.standard.string(forKey: "appleUserName") {
            self.userName = savedName
        }
    }

    func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let id = credential.user
            userID = id
            isSignedIn = true
            UserDefaults.standard.set(id, forKey: userIDKey)

            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    userName = name
                    UserDefaults.standard.set(name, forKey: "appleUserName")
                }
            }

        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }

    #if DEBUG
    func skipSignIn() {
        userID = "local"
        userName = "Test User"
        isSignedIn = true
        UserDefaults.standard.set("local", forKey: userIDKey)
        UserDefaults.standard.set("Test User", forKey: "appleUserName")
    }
    #endif

    func lockApp() {
        guard isSignedIn else { return }
        isLocked = true
    }

    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        context.evaluatePolicy(policy, localizedReason: "Unlock DiaryPure") { success, _ in
            DispatchQueue.main.async {
                if success { self.isLocked = false }
            }
        }
    }

    func signOut() {
        isSignedIn = false
        isLocked = false
        userID = nil
        userName = nil
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: "appleUserName")
    }
}
