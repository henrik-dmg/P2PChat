//
//  MultipeerAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import MultipeerConnectivity
import Observation

@Observable
public final class MultipeerAdvertisingService: MultipeerDataTransferService, PeerAdvertisingService {

    // MARK: - Properties

    public private(set) var state: ServiceState = .inactive

    @ObservationIgnored
    private lazy var advertiser = makeAdvertiser()

    // MARK: - PeerDiscoveryService

    public func startAdvertisingService() {
        advertiser.startAdvertisingPeer()
        state = .active
    }

    public func stopAdvertisingService() {
        advertiser.stopAdvertisingPeer()
        state = .inactive
    }

    // MARK: - Helpers

    func makeAdvertiser() -> MCNearbyServiceAdvertiser {
        let advertiser = MCNearbyServiceAdvertiser(peer: ownMCPeerID, discoveryInfo: nil, serviceType: service.type)
        advertiser.delegate = self
        return advertiser
    }

}

extension MultipeerAdvertisingService: MCNearbyServiceAdvertiserDelegate {

    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        logger.info("Did receive invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        logger.error("Advertiser did not start: \(error)")
        state = .error(error)
    }

}
