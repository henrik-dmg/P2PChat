//
//  BonjourAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Observation
import Network

@Observable
final class BonjourAdvertisingService: NSObject, PeerAdvertisingService {

    // MARK: - Nested Types

    typealias ChatPeer = BonjourPeer

    // MARK: - Properties

    let service: ServiceIdentifier

    private(set) var advertisingState: ServiceState = .inactive

    @ObservationIgnored
    private var listener: NWListener?
    @ObservationIgnored
    private let listenerQueue = DispatchQueue(label: "listenerQueue")

    // MARK: - Init

    init(service: ServiceIdentifier) {
        self.service = service
        super.init()
    }

    // MARK: - PeerDiscoveryService

    func startAdvertisingService() {
        guard listener == nil else {
            return // TODO: Throw error
        }
        do {
            listener = try makeListener()
            listener?.start(queue: listenerQueue)
        } catch {
            advertisingState = .error(error)
        }
    }

    func stopAdvertisingService() {
        listener?.cancel()
        listener = nil
        advertisingState = .inactive
    }

    // MARK: - Helpers

    func makeListener() throws -> NWListener {
        let service = NWListener.Service(name: "P2P Chat Service", type: service.rawValue)
        let listener = try NWListener(service: service, using: .tcp)
        listener.stateUpdateHandler = { newState in
            switch newState {
            case.ready:
                print("Listener ready")
            case .failed(let error):
                print("Listener error: \(error)")
            case .cancelled:
                print("Listener was stopped")
            default:
                print(newState)
            }
        }

        listener.newConnectionHandler = { connection in
            print("New connection", connection)
        }
        listener.newConnectionLimit = 1

        listener.serviceRegistrationUpdateHandler = { [weak self] registrationState in
            print("Registration state changed:", registrationState)
            switch registrationState {
            case .add:
                self?.advertisingState = .active
            case .remove:
                self?.advertisingState = .inactive
            @unknown default:
                print("Unknown service registration state")
            }
        }

        return listener
    }

}
