//
//  MultipeerAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import MultipeerConnectivity
import Network

@Observable
final class MultipeerAdvertisingService: NSObject, PeerAdvertisingService {

    // MARK: - Nested Types

    typealias ChatPeer = MultipeerPeer

    // MARK: - Properties

    let service: ServiceIdentifier

    private(set) var advertisingState: ServiceState = .inactive

    @ObservationIgnored
    private var listener: MCNearbyServiceAdvertiser?
    @ObservationIgnored
    private let listenerQueue = DispatchQueue(label: "listenerQueue")

    // MARK: - Init

    init(service: ServiceIdentifier) {
        self.service = service
        super.init()
    }

    // MARK: - PeerDiscoveryService

    func startAdvertisingService() {
        guard listener == nil else {
            return // TODO: Throw error
        }
        listener = makeListener()
        listener?.startAdvertisingPeer()
        advertisingState = .active
    }

    func stopAdvertisingService() {
        listener?.stopAdvertisingPeer()
        listener = nil
        advertisingState = .inactive
    }

    // MARK: - Helpers

    func makeListener() -> MCNearbyServiceAdvertiser {
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

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        advertisingState = .error(error)
    }

}
