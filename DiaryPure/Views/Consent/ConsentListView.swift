import SwiftData
import SwiftUI

struct ConsentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConsentAgreement.createdAt, order: .reverse) private var agreements: [ConsentAgreement]
    @State private var showingCreate = false
    @State private var showingJoin = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(agreements) { agreement in
                    NavigationLink {
                        ConsentDetailView(agreement: agreement)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(agreement.creatorName)
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(agreement.partnerName)
                            }
                            .font(.headline)
                            HStack {
                                statusBadge(for: agreement.status)
                                if agreement.role == .partner {
                                    Text("Partner")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.2))
                                        .clipShape(Capsule())
                                }
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
                        description: Text("Create a new agreement or join a signing session.")
                    )
                }
            }
            .navigationTitle("Consent")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingCreate = true
                        } label: {
                            Label("New Agreement", systemImage: "plus")
                        }
                        Button {
                            showingJoin = true
                        } label: {
                            Label("Join Session", systemImage: "antenna.radiowaves.left.and.right")
                        }
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
            .fullScreenCover(isPresented: $showingJoin) {
                ConsentJoinView()
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for status: AgreementStatus) -> some View {
        let (text, color): (String, Color) = switch status {
        case .draft: ("Draft", .orange)
        case .pendingPartner: ("Pending", .yellow)
        case .signed: ("Signed", .green)
        case .cancelled: ("Cancelled", .red)
        }
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
    }

    private func deleteAgreements(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(agreements[index])
        }
    }
}

struct ConsentDetailView: View {
    @Bindable var agreement: ConsentAgreement

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Creator")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(agreement.creatorName)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Partner")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(agreement.partnerName)
                            .font(.headline)
                    }
                }

                Divider()

                Text(agreement.agreementText)
                    .font(.body)

                Divider()

                signatureSection(
                    title: "Creator's Signature",
                    data: agreement.creatorSignature
                )

                signatureSection(
                    title: "Partner's Signature",
                    data: agreement.partnerSignature
                )

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
    }

    @ViewBuilder
    private func signatureSection(title: String, data: Data?) -> some View {
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
                Text("Not yet signed")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
