import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        Group {
            if authService.isSignedIn {
                TabView {
                    DiaryListView()
                        .tabItem {
                            Label("Diary", systemImage: "book")
                        }
                    ConsentListView()
                        .tabItem {
                            Label("Consent", systemImage: "signature")
                        }
                }
            } else {
                AuthView()
            }
        }
    }
}
