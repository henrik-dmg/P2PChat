//
//  MultipeerDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Observation
import MultipeerConnectivity

class MultipeerDataTransferService: NSObject, PeerDataTransferService {

    // MARK: - Nested Types

    typealias ChatPeer = MultipeerPeer

    // MARK: - Properties

    @ObservationIgnored
    private var connections: [ChatPeer.ID: MCSession] = [:]

    // MARK: - PeerDataTransferService

    func configure() async throws {}

    func connect(to peer: ChatPeer) async throws {}

    func send(_ data: Data, to peer: ChatPeer) async throws {}

    func disconnect(from peer: ChatPeer) {}

}
