import SwiftData
import SwiftUI

struct ConsentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConsentAgreement.createdAt, order: .reverse) private var agreements: [ConsentAgreement]
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(agreements) { agreement in
                    NavigationLink {
                        ConsentDetailView(agreement: agreement)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(agreement.partnerName)
                                .font(.headline)
                            HStack {
                                Text(agreement.status == .signed ? "Signed" : "Draft")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(agreement.status == .signed ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                    .clipShape(Capsule())
                                Spacer()
                                Text(agreement.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteAgreements)
            }
            .overlay {
                if agreements.isEmpty {
                    ContentUnavailableView(
                        "No Agreements",
                        systemImage: "signature",
                        description: Text("Tap + to create a consent agreement.")
                    )
                }
            }
            .navigationTitle("Consent")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                NavigationStack {
                    ConsentCreateView()
                }
            }
        }
    }

    private func deleteAgreements(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(agreements[index])
        }
    }
}

struct ConsentDetailView: View {
    @Bindable var agreement: ConsentAgreement
    @State private var showingSignature = false
    @State private var signingAsPartner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(agreement.partnerName)
                    .font(.title2.bold())

                Text(agreement.agreementText)
                    .font(.body)

                Divider()

                signatureSection(
                    title: "Your Signature",
                    data: agreement.creatorSignature
                ) {
                    signingAsPartner = false
                    showingSignature = true
                }

                signatureSection(
                    title: "Partner Signature",
                    data: agreement.partnerSignature
                ) {
                    signingAsPartner = true
                    showingSignature = true
                }

                if agreement.status == .signed, let signedAt = agreement.signedAt {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Signed on \(signedAt.formatted(date: .long, time: .shortened))")
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Agreement")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSignature) {
            SignatureView { imageData in
                if signingAsPartner {
                    agreement.partnerSignature = imageData
                } else {
                    agreement.creatorSignature = imageData
                }
                if agreement.creatorSignature != nil && agreement.partnerSignature != nil {
                    agreement.status = .signed
                    agreement.signedAt = Date()
                }
            }
        }
    }

    @ViewBuilder
    private func signatureSection(title: String, data: Data?, onSign: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .border(Color.secondary.opacity(0.3))
            } else {
                Button("Tap to Sign", action: onSign)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
