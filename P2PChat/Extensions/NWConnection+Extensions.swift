//
//  NWConnection+Extensions.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Network

extension NWConnection {

    func connect(queue: DispatchQueue) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stateUpdateHandler = { [weak self] newState in
                self?.stateUpdateHandler = nil
                switch newState {
                case.ready:
                    print("Connection ready")
                    continuation.resume()
                case .failed(let error):
                    print("Connection error: \(error)")
                    continuation.resume(throwing: error)
                case .cancelled:
                    print("Connection was stopped")
                default:
                    print(newState)
                }
            }
            start(queue: queue)
        }
    }

    func sendData(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completion = NWConnection.SendCompletion.contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            send(content: data, completion: completion)
        }
    }

}
