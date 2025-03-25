//
//  BonjourDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Observation
import Network

open class BonjourDataTransferService: PeerDataTransferService {

    // MARK: - Nested Types

    typealias ChatPeer = BonjourPeer

    // MARK: - Properties

    @ObservationIgnored
    var connections: [ChatPeer.ID: NWConnection] = [:]
    @ObservationIgnored
    private let connectionsQueue = DispatchQueue(label: "connectionsQueue")

    // MARK: - PeerDataTransferService

    open func configure() async throws {}

    func connect(to peer: ChatPeer) {
        let connection = NWConnection(to: peer.endpoint, using: .tcp)
        connect(with: connection, peerID: peer.id)
    }

    func connect(with connection: NWConnection, peerID: ChatPeer.ID) {
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case.ready:
                print("Connection ready, starting receive")
                self?.receive(on: connection)
            case .failed(let error):
                print("Connection error: \(error)")
            case .cancelled:
                print("Connection was stopped")
            default:
                print(newState)
            }
        }
        connection.start(queue: connectionsQueue)
        connections[peerID] = connection
    }

    func send(_ data: Data, to peer: ChatPeer) async throws {
        guard let connection = connections[peer.id] else {
            return
        }
        try await connection.sendData(data)
    }

    func disconnect(from peer: ChatPeer) {
        guard let connection = connections[peer.id] else {
            return
        }
        connection.cancel()
        connections[peer.id] = nil
    }

    // MARK: - Helpers

    // Receive messages continuously from a given connection
    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, contentContext, isComplete, error in
            print("Receive callback called")
            if let error {
                print("Receive error: \(error)")
                //                self?.removeConnection(connection)
                return
            }

            if let data, !data.isEmpty {
                if let message = String(data: data, encoding: .utf8) {
                    print("Received message: \(message)")
                } else {
                    print("Received non-UTF8 data: \(data)")
                }
            }

            // Continue receiving messages
            self?.receive(on: connection)
        }
    }

}
