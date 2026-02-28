import SwiftUI
import SwiftData

@main
struct DiaryPureApp: App {
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .modelContainer(for: [DiaryEntry.self, ConsentAgreement.self])
        }
    }
}
