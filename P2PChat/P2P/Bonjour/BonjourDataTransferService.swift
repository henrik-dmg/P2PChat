//
//  BonjourDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Observation
import Network

@Observable
final class BonjourDataTransferService: PeerDataTransferService {

    // MARK: - Nested Types

    typealias ChatPeer = BonjourPeer

    // MARK: - Properties

    @ObservationIgnored
    private var connections: [ChatPeer.ID: NWConnection] = [:]
    @ObservationIgnored
    private let connectionsQueue = DispatchQueue(label: "connectionsQueue")

    // MARK: - PeerDataTransferService

    func connect(to peer: ChatPeer) async throws {
        let connection = NWConnection(to: peer.endpoint, using: .tcp)
        try await connection.connect(queue: connectionsQueue)
        receive(on: connection)
        connections[peer.id] = connection
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
