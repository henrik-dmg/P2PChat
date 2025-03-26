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

    var delegate: PeerDataTransferServiceDelegate? { get set }

    func configure() async throws

    func connect(to peer: ChatPeer, callback: @escaping (Result<Void, Error>) -> Void)
    func send(_ data: Data, to peerID: String) async throws
    func disconnect(from peerID: String)
    func disconnectAll()

}

public protocol PeerDataTransferServiceDelegate: AnyObject {

    func serviceDidConnectToPeer(with id: String)
    func serviceReceived(data: Data, from peerID: String)
    func serviceDidDisconnectFromPeer(with id: String)

}
