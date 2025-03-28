//
//  MultipeerDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Observation
import MultipeerConnectivity

@Observable
public class MultipeerDataTransferService: NSObject, PeerDataTransferService {

    // MARK: - Nested Types

    public typealias ChatPeer = MultipeerPeer
    public typealias ConnectionState = Bool

    // MARK: - Properties

    public let ownPeerID: PeerID
    public private(set) var connectedPeers: [PeerID] = []
    public weak var delegate: PeerDataTransferServiceDelegate?

    @ObservationIgnored
    public private(set) var connections: [PeerID: MCPeerID] = [:]
    @ObservationIgnored
    lazy var session = makeSession()
    @ObservationIgnored
    lazy var ownMCPeerID = MCPeerID(displayName: ownPeerID)

    // MARK: - Init

    init(ownPeerID: PeerID) {
        self.ownPeerID = ownPeerID
        super.init()
    }

    // MARK: - PeerDataTransferService

    public func configure() async throws {}

    public func connect(to peer: ChatPeer) {
        session.connectPeer(peer.identifier, withNearbyConnectionData: Data())
    }

    public func send(_ data: Data, to peerID: PeerID) async throws {
        guard let storedPeerID = connections[peerID] else {
            print("No stored peerID for \(peerID)")
            return
        }
        guard session.connectedPeers.contains(storedPeerID) else {
            print("Stored peer \(storedPeerID) not connected")
            return
        }
        try session.send(data, toPeers: [storedPeerID], with: .reliable)
        print("Successfully sent data to peer \(peerID)")
    }

    public func disconnect(from peerID: PeerID) {
        session.disconnect()  // Apparently not possible to disconnect from single peer
    }

    public func disconnectAll() {
        session.disconnect()
    }

    // MARK: - Helpers

    private func makeSession() -> MCSession {
        let session = MCSession(peer: ownMCPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }

}

extension MultipeerDataTransferService: MCSessionDelegate {

    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        connectedPeers = session.connectedPeers.map { $0.displayName }

        switch state {
        case .notConnected:
            connections[peerID.displayName] = nil
            delegate?.serviceDidDisconnectFromPeer(with: peerID.displayName)
            print("Peer \(peerID) disconnected")
        case .connecting:
            print("Peer \(peerID) connecting")
        case .connected:
            connections[peerID.displayName] = peerID
            delegate?.serviceDidConnectToPeer(with: peerID.displayName)
            print("Peer \(peerID) connected")
        @unknown default:
            print(state)
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        delegate?.serviceReceived(data: data, from: peerID.displayName)
        print("Received data from \(peerID)")
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Session did receive stream")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Session did receiving resource with name \(resourceName)")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        print("Session did finish receiving resource with name \(resourceName)")
    }

}
