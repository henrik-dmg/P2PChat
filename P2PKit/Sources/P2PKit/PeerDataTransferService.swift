//
//  PeerDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Foundation
import Observation

public protocol PeerDataTransferService<ChatPeer>: AnyObject, Observable {

    associatedtype ChatPeer: Peer

    func configure() async throws

    func connect(to peer: ChatPeer) async throws
    func send(_ data: Data, to peer: ChatPeer) async throws
    func disconnect(from peer: ChatPeer)

}
