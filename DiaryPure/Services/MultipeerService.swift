import Combine
import Foundation
import MultipeerConnectivity

enum MultipeerEvent {
    case peerFound(MCPeerID)
    case peerLost(MCPeerID)
    case connected(MCPeerID)
    case disconnected(MCPeerID)
    case received(Data)
    case invitationReceived(MCPeerID, (Bool, MCSession?) -> Void)
}

final class MultipeerService: NSObject, ObservableObject {
    private let serviceType = "diarypure-sign"
    private let myPeerID: MCPeerID

    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?

    let events = PassthroughSubject<MultipeerEvent, Never>()

    @Published var connectedPeer: MCPeerID?
    @Published var isConnected = false

    override init() {
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    private func makeSession() -> MCSession {
        let s = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        return s
    }

    // MARK: - Creator (Browser)

    func startBrowsing() {
        session = makeSession()
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func invite(peer: MCPeerID) {
        guard let session else { return }
        browser?.invitePeer(peer, to: session, withContext: nil, timeout: 30)
    }

    // MARK: - Partner (Advertiser)

    func startAdvertising() {
        session = makeSession()
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    // MARK: - Shared

    func send(payload: AgreementTransferPayload) {
        guard let session, let data = payload.encoded(),
              let peer = session.connectedPeers.first else { return }
        try? session.send(data, toPeers: [peer], with: .reliable)
    }

    func acceptInvitation(_ handler: @escaping (Bool, MCSession?) -> Void) {
        handler(true, session)
    }

    func disconnect() {
        browser?.stopBrowsingForPeers()
        advertiser?.stopAdvertisingPeer()
        session?.disconnect()
        browser = nil
        advertiser = nil
        session = nil
        connectedPeer = nil
        isConnected = false
    }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeer = peerID
                self.isConnected = true
                self.events.send(.connected(peerID))
            case .notConnected:
                self.connectedPeer = nil
                self.isConnected = false
                self.events.send(.disconnected(peerID))
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.events.send(.received(data))
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            self.events.send(.peerFound(peerID))
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.events.send(.peerLost(peerID))
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.events.send(.invitationReceived(peerID, invitationHandler))
        }
    }
}
