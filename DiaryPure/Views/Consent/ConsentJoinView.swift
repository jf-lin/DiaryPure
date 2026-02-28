import Combine
import SwiftData
import SwiftUI

struct ConsentJoinView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var multipeer = MultipeerService()
    @State private var receivedPayload: AgreementTransferPayload?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var pulseScale = 1.0

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
    }

    private var waitingView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: pulseScale
                )
                .onAppear { pulseScale = 1.2 }

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
                default:
                    break
                }
            }
            .store(in: &cancellables)
        multipeer.startAdvertising()
    }
}
