//
//  MultipeerDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Observation
import MultipeerConnectivity

public class MultipeerDataTransferService: NSObject, PeerDataTransferService {

    // MARK: - Nested Types

    public typealias ChatPeer = MultipeerPeer
    public typealias ConnectionState = Bool

    // MARK: - Properties

    public weak var delegate: PeerDataTransferServiceDelegate?

    @ObservationIgnored
    public private(set) var connections: [ChatPeer.ID: MCSession] = [:]

    // MARK: - PeerDataTransferService

    public func configure() async throws {}

    public func connect(to peer: ChatPeer, callback: @escaping (Result<Void, Error>) -> Void) {}

    public func send(_ data: Data, to peer: ChatPeer) async throws {}

    public func disconnect(from peer: ChatPeer) {}

    public func disconnectAll() {}

}
