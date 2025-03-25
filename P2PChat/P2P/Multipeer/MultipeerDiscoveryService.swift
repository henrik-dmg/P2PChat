//
//  MultipeerDiscoveryService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import MultipeerConnectivity
import Observation

@Observable
final class MultipeerDiscoveryService: MultipeerDataTransferService, PeerDiscoveryService {

    // MARK: - Nested Types

    typealias ChatPeer = MultipeerPeer

    // MARK: - Properties

    let service: ServiceIdentifier
    private(set) var discoveryState: ServiceState = .inactive
    private(set) var availablePeers = [ChatPeer]()

    @ObservationIgnored
    private lazy var browser = makeBrowser()

    // MARK: - Init

    init(service: ServiceIdentifier) {
        self.service = service
        super.init()
    }

    // MARK: - PeerDiscoveryService

    func startDiscoveringPeers() {
        browser.startBrowsingForPeers()
        discoveryState = .active
    }

    func stopDiscoveringPeers() {
        browser.stopBrowsingForPeers()
        availablePeers = []
        discoveryState = .inactive
    }

    // MARK: - Helpers

    private func makeBrowser() -> MCNearbyServiceBrowser {
        let browser = MCNearbyServiceBrowser(peer: MCPeerID(displayName: UIDevice.current.name), serviceType: service.rawValue)
        browser.delegate = self
        return browser
    }

}

extension MultipeerDiscoveryService: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Browser found peer: \(peerID.displayName)")
        availablePeers.append(MultipeerPeer(identifier: peerID, info: info))
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Browser lost peer: \(peerID.displayName)")
        availablePeers.removeAll { peer in
            peer.identifier == peerID
        }
    }

}
