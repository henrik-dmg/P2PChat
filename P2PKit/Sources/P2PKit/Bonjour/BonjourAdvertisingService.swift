//
//  BonjourAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Observation
import Network

@Observable
public final class BonjourAdvertisingService: BonjourDataTransferService, PeerAdvertisingService {

    // MARK: - Properties

    public let service: ServiceIdentifier
    public private(set) var state: ServiceState = .inactive

    @ObservationIgnored
    private var listener: NWListener?
    @ObservationIgnored
    private let listenerQueue = DispatchQueue(label: "listenerQueue")

    // MARK: - Init

    public init(service: ServiceIdentifier) {
        self.service = service
        super.init()
    }

    // MARK: - PeerDiscoveryService

    public func startAdvertisingService(callback: @escaping (Result<[ChatPeer], any Error>) -> Void) {
        guard listener == nil else {
            return // TODO: Throw error
        }
        do {
            listener = try makeListener(callback: callback)
            listener?.start(queue: listenerQueue)
        } catch {
            state = .error(error)
        }
    }

    public func stopAdvertisingService() {
        listener?.cancel()
        listener = nil
        state = .inactive
    }

    // MARK: - Helpers

    func makeListener(callback: @escaping Callback) throws -> NWListener {
        let service = NWListener.Service(name: "P2P Chat Service", type: service.rawValue)
        let listener = try NWListener(service: service, using: .tcp)
        listener.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case.ready:
                print("Listener ready")
            case .failed(let error):
                print("Listener error: \(error)")
            case .cancelled:
                print("Listener was stopped")
                self?.disconnectAll()
            default:
                print(newState)
            }
        }

        listener.newConnectionHandler = { [weak self]  connection in
            print("New connection", connection, connection.state)
            let peer = BonjourPeer(endpoint: connection.endpoint)
            self?.connect(with: connection, peerID: peer.id) { result in
                switch result {
                case .success:
                    callback(.success([peer]))
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }
        listener.newConnectionLimit = 1

        listener.serviceRegistrationUpdateHandler = { [weak self] registrationState in
            print("Registration state changed:", registrationState)
            switch registrationState {
            case .add:
                self?.state = .active
            case .remove:
                self?.state = .inactive
            @unknown default:
                print("Unknown service registration state")
            }
        }

        return listener
    }

}
