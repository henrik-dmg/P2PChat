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

    public typealias PeerID = BonjourPeer.ID
    public typealias ChatPeer = BonjourPeer
    public typealias ConnectionState = NWConnection.State

    // MARK: - Properties

    public weak var delegate: PeerDataTransferServiceDelegate?
    public private(set) var connectedPeers: [PeerID] = []

    @ObservationIgnored
    private var connections: [String: NWConnection] = [:]
    @ObservationIgnored
    private let connectionsQueue = DispatchQueue(label: "connectionsQueue")

    // MARK: - PeerDataTransferService

    open func configure() async throws {}

    public func connect(to peer: BonjourPeer, callback: @escaping (Result<Void, Error>) -> Void) {
        let connection = NWConnection(to: peer.endpoint, using: .tcp)
        connect(with: connection, peerID: peer.id, callback: callback)
    }

    func connect(with connection: NWConnection, peerID: ChatPeer.ID, callback: @escaping (Result<Void, Error>) -> Void) {
        guard connections[peerID] == nil else {
            return  // Already connected to peer
        }
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case.ready:
                print("Connection ready, starting receive")
                self?.delegate?.serviceDidConnectToPeer(with: peerID)
                callback(.success(()))
                self?.receive(on: connection, peerID: peerID)
            case .failed(let error):
                print("Connection error: \(error)")
                callback(.failure(error))
                self?.disconnect(from: peerID)
            case .cancelled:
                print("Connection was stopped")
                self?.delegate?.serviceDidDisconnectFromPeer(with: peerID)
            default:
                print(newState)
            }
        }
        connection.start(queue: connectionsQueue)
        connections[peerID] = connection
    }

    public func send(_ data: Data, to peerID: String) async throws {
        guard let connection = connections[peerID] else {
            return
        }
        try await connection.sendData(data)
    }

    public func disconnect(from peerID: ChatPeer.ID) {
        guard let connection = connections[peerID] else {
            return
        }
        connection.cancel()
        connections[peerID] = nil
    }

    public func disconnectAll() {
        for id in connections.keys {
            disconnect(from: id)
        }
    }

    // MARK: - Helpers

    // Receives messages continuously from a given connection
    func receive(on connection: NWConnection, peerID: ChatPeer.ID) {
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
                    self?.delegate?.serviceReceived(data: data, from: peerID)
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
                self?.receive(on: connection, peerID: peerID)
            }
        }
    }

}
