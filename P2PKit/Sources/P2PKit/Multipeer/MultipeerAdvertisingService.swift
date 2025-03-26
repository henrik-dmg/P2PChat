//
//  MultipeerAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import MultipeerConnectivity
import Network

@Observable
public final class MultipeerAdvertisingService: MultipeerDataTransferService, PeerAdvertisingService {

    // MARK: - Properties

    public let service: ServiceIdentifier
    public private(set) var state: ServiceState = .inactive

    @ObservationIgnored
    private lazy var advertiser = makeAdvertiser()

    // MARK: - Init

    public init(service: ServiceIdentifier) {
        self.service = service
        super.init()
    }

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
        let advertiser = MCNearbyServiceAdvertiser(
            peer: MCPeerID(displayName: UIDevice.current.name),
            discoveryInfo: nil,
            serviceType: service.rawValue
        )
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
        print("Did receive invitation from \(peerID.displayName)")
    }
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        print("Advertiser did not start", error.localizedDescription)
        state = .error(error)
    }

}
