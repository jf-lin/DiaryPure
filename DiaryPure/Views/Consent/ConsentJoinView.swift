import Combine
import MultipeerConnectivity
import SwiftData
import SwiftUI

struct ConsentJoinView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var multipeer = MultipeerService()
    @State private var receivedPayload: AgreementTransferPayload?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var ripple = false
    @State private var pendingInvitation: (peer: MCPeerID, handler: (Bool, MCSession?) -> Void)?
    @State private var showingInvitationAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if let payload = receivedPayload {
                    ConsentPartnerReviewView(
                        payload: payload,
                        multipeer: multipeer,
                        onComplete: {
                            dismiss()
                        }
                    )
                } else {
                    waitingView
                }
            }
            .navigationTitle("Join Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if receivedPayload == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            pendingInvitation?.handler(false, nil)
                            multipeer.disconnect()
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            startAdvertising()
        }
        .onDisappear {
            multipeer.disconnect()
        }
        .alert("Invitation Received", isPresented: $showingInvitationAlert) {
            Button("Accept") {
                if let invitation = pendingInvitation {
                    multipeer.acceptInvitation(invitation.handler)
                }
                pendingInvitation = nil
            }
            Button("Decline", role: .destructive) {
                pendingInvitation?.handler(false, nil)
                pendingInvitation = nil
            }
        } message: {
            if let peer = pendingInvitation?.peer {
                Text("\"\(peer.displayName)\" wants to share a consent agreement with you.")
            }
        }
    }

    private var waitingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.accentColor.opacity(ripple ? 0 : 0.4), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(ripple ? 2.5 : 1)
                        .animation(
                            .easeOut(duration: 2.4)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.8),
                            value: ripple
                        )
                }
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
            }
            .onAppear { ripple = true }

            Text("Waiting for invitation...")
                .font(.headline)
            Text("The creator will find your device and send the agreement")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if multipeer.isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Connected — receiving agreement...")
                }
                .font(.subheadline)
            }
            Spacer()
        }
    }

    private func startAdvertising() {
        multipeer.events
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch event {
                case .received(let data):
                    if let payload = AgreementTransferPayload.decoded(from: data) {
                        receivedPayload = payload
                    }
                case .invitationReceived(let peer, let handler):
                    pendingInvitation = (peer, handler)
                    showingInvitationAlert = true
                default:
                    break
                }
            }
            .store(in: &cancellables)
        multipeer.startAdvertising()
    }
}
