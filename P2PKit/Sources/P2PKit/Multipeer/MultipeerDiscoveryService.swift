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

    public init(service: ServiceIdentifier) {
        self.service = service
        super.init()
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

    // MARK: - Helpers

    private func makeBrowser() -> MCNearbyServiceBrowser {
        let browser = MCNearbyServiceBrowser(peer: MCPeerID(displayName: UIDevice.current.name), serviceType: service.rawValue)
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

}
