//
//  PeerAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Observation

public protocol PeerAdvertisingService<ChatPeer>: PeerDataTransferService {

    var service: ServiceIdentifier { get }
    var advertisingState: ServiceState { get }

    func startAdvertisingService()
    func stopAdvertisingService()

}
