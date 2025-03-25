//
//  BonjourDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Observation
import Network

public class BonjourDataTransferService: PeerDataTransferService {

    // MARK: - Nested Types

    public typealias ChatPeer = BonjourPeer

    // MARK: - Properties

    @ObservationIgnored
    var connections: [ChatPeer.ID: NWConnection] = [:]
    @ObservationIgnored
    private let connectionsQueue = DispatchQueue(label: "connectionsQueue")

    // MARK: - PeerDataTransferService

    open func configure() async throws {}

    public func connect(to peer: ChatPeer) {
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

    public func send(_ data: Data, to peer: ChatPeer) async throws {
        guard let connection = connections[peer.id] else {
            return
        }
        try await connection.sendData(data)
    }

    public func disconnect(from peer: ChatPeer) {
        disconnect(from: peer.id)
    }

    func disconnect(from peerID: ChatPeer.ID) {
        guard let connection = connections[peerID] else {
            return
        }
        connection.cancel()
        connections[peerID] = nil
    }

    func disconnectAll() {
        for id in connections.keys {
            disconnect(from: id)
        }
    }

    // MARK: - Helpers

    // Receives messages continuously from a given connection
    func receive(on connection: NWConnection) {
//        connection.receiveMessage { [weak self] data, contentContext, isComplete, error in
//            print("Receive callback called")
//            if let error {
//                print("Receive error: \(error)")
//                //                self?.removeConnection(connection)
//                return
//            }
//
//            if let data, !data.isEmpty {
//                if let message = String(data: data, encoding: .utf8) {
//                    print("Received message: \(message)")
//                } else {
//                    print("Received non-UTF8 data: \(data)")
//                }
//            }
//
//            // Continue receiving messages
//            self?.receive(on: connection)
//        }

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            print("Receive callback called")
            // Check if data was received
            if let data, !data.isEmpty {
                if let message = String(data: data, encoding: .utf8) {
                    print("Received: \(message)")
                } else {
                    print("Received binary data: \(data)")
                }
            }

            // Check for errors or connection end
            if isComplete {
                print("Connection complete")
                connection.cancel()
            } else if let error = error {
                print("Connection error: \(error)")
                connection.cancel()
            } else {
                // If no error and not complete, continue receiving
                self?.receive(on: connection)
            }
        }
    }

}
