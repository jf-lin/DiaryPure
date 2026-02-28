import Combine
import MultipeerConnectivity
import SwiftData
import SwiftUI

enum SigningState {
    case signing
    case searching
    case waitingForPartner
    case completed
}

struct ConsentSigningSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let agreement: ConsentAgreement
    @StateObject private var multipeer = MultipeerService()

    @State private var state: SigningState = .signing
    @State private var showingSignature = false
    @State private var discoveredPeers: [MCPeerID] = []
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .signing:
                    signingPhase
                case .searching:
                    searchingPhase
                case .waitingForPartner:
                    waitingPhase
                case .completed:
                    ConsentCompletionView {
                        multipeer.disconnect()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Signing Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if state != .completed {
                        Button("Cancel") {
                            multipeer.disconnect()
                            dismiss()
                        }
                    }
                }
            }
        }
        .onDisappear {
            multipeer.disconnect()
        }
    }

    // MARK: - Phases

    private var signingPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "signature")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Sign the agreement to begin")
                .font(.headline)
            Button("Sign Now") {
                showingSignature = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .sheet(isPresented: $showingSignature) {
            SignatureView { data in
                agreement.creatorSignature = data
                agreement.status = .pendingPartner
                startSearching()
            }
        }
    }

    private var searchingPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching for partner's device...")
                .font(.headline)
            Text("Ask your partner to open \"Join Session\" on their device")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !discoveredPeers.isEmpty {
                VStack(spacing: 12) {
                    Text("Devices Found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(discoveredPeers, id: \.displayName) { peer in
                        Button {
                            multipeer.invite(peer: peer)
                        } label: {
                            HStack {
                                Image(systemName: "iphone")
                                Text(peer.displayName)
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
    }

    private var waitingPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Waiting for partner to review and sign...")
                .font(.headline)
            if let peer = multipeer.connectedPeer {
                Text("Connected to \(peer.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Logic

    private func startSearching() {
        state = .searching
        subscribeToEvents()
        multipeer.startBrowsing()
    }

    private func subscribeToEvents() {
        multipeer.events
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch event {
                case .peerFound(let peer):
                    if !discoveredPeers.contains(where: { $0.displayName == peer.displayName }) {
                        discoveredPeers.append(peer)
                    }
                case .peerLost(let peer):
                    discoveredPeers.removeAll { $0.displayName == peer.displayName }
                case .connected:
                    state = .waitingForPartner
                    sendPayload()
                case .received(let data):
                    handlePartnerResponse(data)
                case .disconnected:
                    if state != .completed {
                        state = .searching
                        discoveredPeers = []
                    }
                case .invitationReceived:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func sendPayload() {
        let payload = AgreementTransferPayload(
            agreementID: agreement.id,
            creatorName: agreement.creatorName,
            partnerName: agreement.partnerName,
            agreementText: agreement.agreementText,
            language: agreement.language,
            creatorSignature: agreement.creatorSignature,
            partnerSignature: nil,
            status: .pendingPartner,
            createdAt: agreement.createdAt,
            signedAt: nil
        )
        multipeer.send(payload: payload)
    }

    private func handlePartnerResponse(_ data: Data) {
        guard let payload = AgreementTransferPayload.decoded(from: data) else { return }
        agreement.partnerName = payload.partnerName
        agreement.partnerSignature = payload.partnerSignature
        agreement.status = .signed
        agreement.signedAt = Date()
        state = .completed
    }
}
