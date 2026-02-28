import SwiftData
import SwiftUI

struct ConsentCreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService

    @State private var creatorName = ""
    @State private var language: AgreementLanguage = ConsentTemplateService.deviceLanguage()
    @State private var showingReview = false
    @State private var showingSigningSession = false
    @State private var createdAgreement: ConsentAgreement?

    var body: some View {
        Form {
            Section("Your Name") {
                TextField("Your name", text: $creatorName)
            }
            Section("Language") {
                Picker("Agreement Language", selection: $language) {
                    ForEach(AgreementLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .onAppear {
            if creatorName.isEmpty {
                creatorName = authService.userName ?? ""
            }
        }
        .navigationTitle("New Agreement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Preview") {
                    showingReview = true
                }
                .disabled(creatorName.isEmpty)
            }
        }
        .navigationDestination(isPresented: $showingReview) {
            ConsentReviewView(
                agreementText: renderedText,
                onSign: {
                    let agreement = ConsentAgreement(
                        creatorName: creatorName,
                        partnerName: "",
                        agreementText: renderedText,
                        language: language,
                        role: .creator
                    )
                    modelContext.insert(agreement)
                    createdAgreement = agreement
                    showingReview = false
                    showingSigningSession = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingSigningSession) {
            if let agreement = createdAgreement {
                ConsentSigningSessionView(agreement: agreement)
                    .onDisappear { dismiss() }
            }
        }
    }

    private var renderedText: String {
        ConsentTemplateService.render(
            creatorName: creatorName,
            partnerName: "",
            date: Date(),
            language: language
        )
    }
}
