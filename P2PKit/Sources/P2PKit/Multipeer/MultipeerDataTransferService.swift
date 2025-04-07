//
//  MultipeerDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import MultipeerConnectivity
import Observation
import OSLog

@Observable
public class MultipeerDataTransferService: NSObject, PeerDataTransferService {

    // MARK: - Nested Types

    public typealias ChatPeer = MultipeerPeer
    public typealias ConnectionState = Bool

    // MARK: - Properties

    public let ownPeerID: PeerID
    public var connectedPeers: [PeerID] {
        Array(connections.keys)
    }
    public weak var delegate: PeerDataTransferServiceDelegate?

    private var connections: [PeerID: MCPeerID] = [:]
    @ObservationIgnored
    lazy var session = makeSession()
    @ObservationIgnored
    lazy var ownMCPeerID = MCPeerID(displayName: ownPeerID)

    let logger = Logger.multipeer

    // MARK: - Init

    init(ownPeerID: PeerID) {
        self.ownPeerID = ownPeerID
        super.init()
    }

    // MARK: - PeerDataTransferService

    public func connect(to peer: ChatPeer) {
        session.nearbyConnectionData(forPeer: peer.identifier) { [weak self] data, error in
            if let error {
                self?.logger.error("Error fetching nearby connection data for peer \(peer.identifier): \(error)")
                return
            }
            guard let data else {
                self?.logger.error("No error but no data either")
                return
            }
            self?.session.connectPeer(peer.identifier, withNearbyConnectionData: data)
        }
    }

    public func send(_ data: Data, to peerID: PeerID) async throws {
        guard let storedPeerID = connections[peerID] else {
            logger.warning("No stored peerID for \(peerID)")
            return
        }
        guard session.connectedPeers.contains(storedPeerID) else {
            logger.warning("Stored peer \(storedPeerID) not connected")
            return
        }
        try session.send(data, toPeers: [storedPeerID], with: .reliable)
        logger.info("Successfully sent data to peer \(peerID)")
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
        //connectedPeers = session.connectedPeers.map { $0.displayName }

        switch state {
        case .notConnected:
            connections[peerID.displayName] = nil
            delegate?.serviceDidDisconnectFromPeer(with: peerID.displayName)
            logger.info("Peer \(peerID) disconnected")
        case .connecting:
            logger.info("Peer \(peerID) connecting")
        case .connected:
            connections[peerID.displayName] = peerID
            delegate?.serviceDidConnectToPeer(with: peerID.displayName)
            logger.info("Peer \(peerID) connected")
        @unknown default:
            logger.warning("Unknown connection state: \(String(describing: state))")
        }
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        delegate?.serviceReceived(data: data, from: peerID.displayName)
        logger.info("Received data from \(peerID)")
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        logger.info("Session did receive stream")
    }

    public func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        logger.info("Session did receiving resource with name \(resourceName)")
    }

    public func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {
        logger.info("Session did finish receiving resource with name \(resourceName)")
    }

}
