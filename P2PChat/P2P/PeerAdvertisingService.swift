//
//  PeerAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Observation

protocol PeerAdvertisingService<ChatPeer>: AnyObject, Observable {

    associatedtype ChatPeer: Peer

    var service: ServiceIdentifier { get }
    var advertisingState: ServiceState { get }

    func startAdvertisingService()
    func stopAdvertisingService()

}
