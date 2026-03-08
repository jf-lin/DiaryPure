import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService

    @State private var editingName = false
    @State private var nameDraft = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            if editingName {
                                TextField("Your name", text: $nameDraft)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit { saveName() }
                            } else {
                                Text(authService.userName ?? "No name set")
                                    .font(.headline)
                            }
                            if let id = authService.userID, id != "local" {
                                Text("Apple ID")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            if editingName {
                                saveName()
                            } else {
                                nameDraft = authService.userName ?? ""
                                editingName = true
                            }
                        } label: {
                            Text(editingName ? "Save" : "Edit")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Signature") {
                    if SignatureStore.load() != nil {
                        HStack {
                            Text("Saved signature")
                            Spacer()
                            Button("Delete", role: .destructive) {
                                SignatureStore.delete()
                            }
                            .font(.subheadline)
                        }
                    } else {
                        Text("No saved signature")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authService.signOut()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func saveName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            authService.userName = trimmed
            UserDefaults.standard.set(trimmed, forKey: "appleUserName")
        }
        editingName = false
    }
}
