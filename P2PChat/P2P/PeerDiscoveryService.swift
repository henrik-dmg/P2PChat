//
//  PeerDiscoveryService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Observation

protocol PeerDiscoveryService<ChatPeer>: PeerDataTransferService {

    var service: ServiceIdentifier { get }
    var availablePeers: [ChatPeer] { get }
    var discoveryState: ServiceState { get }

    func startDiscoveringPeers()
    func stopDiscoveringPeers()

}
