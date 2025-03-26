//
//  PeerAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Observation

public protocol PeerAdvertisingService<ChatPeer>: PeerDataTransferService {

    associatedtype Callback = (Result<[ChatPeer], any Error>) -> Void

    var service: ServiceIdentifier { get }
    var state: ServiceState { get }

    func startAdvertisingService(callback: @escaping (Result<[ChatPeer], Error>) -> Void)
    func stopAdvertisingService()

}
