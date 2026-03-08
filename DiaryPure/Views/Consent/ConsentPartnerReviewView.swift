import Combine
import SwiftData
import SwiftUI

struct ConsentPartnerReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authService: AuthService

    let payload: AgreementTransferPayload
    let multipeer: MultipeerService
    let onComplete: () -> Void

    @State private var partnerName = ""
    @State private var showingSignature = false
    @State private var completed = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        if completed {
            ConsentCompletionView(onDismiss: onComplete)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Section {
                        TextField("Your name", text: $partnerName)
                            .textFieldStyle(.roundedBorder)
                    } header: {
                        Text("Your Name")
                            .font(.headline)
                    }

                    Divider()

                    Text(finalAgreementText)
                        .font(.body)

                    Divider()

                    Text("Creator's Signature")
                        .font(.headline)
                    if let sigData = payload.creatorSignature,
                       let img = UIImage(data: sigData) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .border(Color.secondary.opacity(0.3))
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showingSignature = true
                } label: {
                    Text("I Agree — Sign")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(partnerName.isEmpty ? Color.gray : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(partnerName.isEmpty)
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Review & Sign")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if partnerName.isEmpty {
                    partnerName = authService.userName ?? ""
                }
            }
            .sheet(isPresented: $showingSignature) {
                SignatureView { signatureData in
                    sendSignatureBack(signatureData)
                }
            }
        }
    }

    private var finalAgreementText: String {
        ConsentTemplateService.render(
            creatorName: payload.creatorName,
            partnerName: partnerName,
            date: payload.createdAt,
            language: payload.language
        )
    }

    private func sendSignatureBack(_ signatureData: Data) {
        let agreementText = finalAgreementText

        // Send payload back with partner signature, name, and updated text
        var response = payload
        response.partnerName = partnerName
        response.agreementText = agreementText
        response.partnerSignature = signatureData
        response.status = .signed
        response.signedAt = Date()
        multipeer.send(payload: response)

        // Save local copy as partner role
        let local = ConsentAgreement(
            creatorName: payload.creatorName,
            partnerName: partnerName,
            agreementText: agreementText,
            language: payload.language,
            role: .partner
        )
        local.id = payload.agreementID
        local.creatorSignature = payload.creatorSignature
        local.partnerSignature = signatureData
        local.status = .signed
        local.signedAt = Date()
        local.createdAt = payload.createdAt
        modelContext.insert(local)

        completed = true
    }
}
