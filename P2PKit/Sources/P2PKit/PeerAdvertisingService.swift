//
//  PeerAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Observation

public protocol PeerAdvertisingService<P>: PeerDataTransferService {

    associatedtype Callback = (Result<[P.ID], any Error>) -> Void

    var state: ServiceState { get }

    func startAdvertisingService()
    func stopAdvertisingService()

}
