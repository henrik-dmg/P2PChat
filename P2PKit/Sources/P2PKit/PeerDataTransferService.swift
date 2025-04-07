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
    typealias PeerID = ChatPeer.ID

    var ownPeerID: PeerID { get }
    var connectedPeers: [PeerID] { get }
    var delegate: PeerDataTransferServiceDelegate? { get set }

    func configure() async throws

    func connect(to peer: ChatPeer)
    func send(_ data: Data, to peerID: PeerID) async throws
    func disconnect(from peerID: PeerID)
    func disconnectAll()

}

public protocol PeerDataTransferServiceDelegate: AnyObject {

    func serviceDidFailToConnectToPeer(with id: String, error: Error)
    func serviceDidConnectToPeer(with id: String)
    func serviceReceived(data: Data, from peerID: String)
    func serviceDidDisconnectFromPeer(with id: String)

}
