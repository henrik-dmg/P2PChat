//
//  MultipeerDiscoveryService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import MultipeerConnectivity
import Observation

@Observable
public final class MultipeerDiscoveryService: MultipeerDataTransferService, PeerDiscoveryService {

    // MARK: - Properties

    public let service: ServiceIdentifier
    public private(set) var state: ServiceState = .inactive
    public private(set) var availablePeers = [ChatPeer]()

    @ObservationIgnored
    private lazy var browser = makeBrowser()

    // MARK: - Init

    public init(service: ServiceIdentifier, ownPeerID: PeerID) {
        self.service = service
        super.init(ownPeerID: ownPeerID)
    }

    // MARK: - PeerDiscoveryService

    public func startDiscoveringPeers() {
        browser.startBrowsingForPeers()
        state = .active
    }

    public func stopDiscoveringPeers() {
        browser.stopBrowsingForPeers()
        availablePeers = []
        state = .inactive
    }

    // MARK: - Overridden Methods

    public override func connect(to peer: ChatPeer) {
        browser.invitePeer(peer.identifier, to: session, withContext: nil, timeout: 10)
    }

    // MARK: - Helpers

    private func makeBrowser() -> MCNearbyServiceBrowser {
        let browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: service.rawValue)
        browser.delegate = self
        return browser
    }

}

extension MultipeerDiscoveryService: MCNearbyServiceBrowserDelegate {

    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Browser found peer: \(peerID.displayName)")
        availablePeers.append(MultipeerPeer(identifier: peerID, info: info))
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Browser lost peer: \(peerID.displayName)")
        availablePeers.removeAll { peer in
            peer.identifier == peerID
        }
    }

    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        print("Browser did not start browsing for peers: \(error)")
        state = .error(error)
    }

}
