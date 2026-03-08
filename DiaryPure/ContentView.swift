import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if authService.isSignedIn {
                if authService.isLocked {
                    lockScreen
                } else {
                    TabView {
                        DiaryCalendarView()
                            .tabItem {
                                Label("Diary", systemImage: "calendar")
                            }
                        ConsentListView()
                            .tabItem {
                                Label("Consent", systemImage: "signature")
                            }
                        ProfileView()
                            .tabItem {
                                Label("Profile", systemImage: "person.crop.circle")
                            }
                    }
                }
            } else {
                AuthView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                authService.lockApp()
            } else if newPhase == .active && authService.isLocked {
                authService.authenticateWithBiometrics()
            }
        }
    }

    private var lockScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("DiaryPure is locked")
                .font(.title2.weight(.semibold))
            Button("Unlock") {
                authService.authenticateWithBiometrics()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}
