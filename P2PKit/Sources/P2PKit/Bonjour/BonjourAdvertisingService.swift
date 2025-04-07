//
//  BonjourAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Network
import Observation

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

    public init(service: ServiceIdentifier, ownPeerID: PeerID) {
        self.service = service
        super.init(ownPeerID: ownPeerID)
    }

    // MARK: - PeerDiscoveryService

    public func startAdvertisingService() {
        guard listener == nil else {
            return  // TODO: Throw error
        }
        do {
            listener = try makeListener()
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

    func makeListener() throws -> NWListener {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true  // Allow discovery on Bluetooth, etc.

        let service = NWListener.Service(name: "P2P Chat Service", type: service.rawValue)
        let listener = try NWListener(service: service, using: parameters)
        listener.stateUpdateHandler = { [weak self] (newState: NWListener.State) in
            guard let self else {
                return
            }
            switch newState {
            case .setup:
                logger.info("Listener setting up")
            case let .waiting(error):
                logger.error("Listener waiting with error: \(error)")
            case .ready:
                logger.info("Listener ready")
            case let .failed(error):
                logger.error("Listener error: \(error)")
            case .cancelled:
                logger.info("Listener stopped")
                disconnectAll()
            @unknown default:
                logger.warning("Unknown listener state: \(String(describing: newState))")
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.logger.info("New connection \(connection.debugDescription)")
            let peer = BonjourPeer(endpoint: connection.endpoint)
            self?.connect(with: connection, peerID: peer.id)
        }
        listener.newConnectionLimit = 1

        listener.serviceRegistrationUpdateHandler = { [weak self] registrationState in
            guard let self else { return }
            switch registrationState {
            case .add:
                logger.info("Service added")
                state = .active
            case .remove:
                logger.info("Service removed")
                state = .inactive
            @unknown default:
                logger.warning("Unknown service registration state: \(String(describing: registrationState))")
            }
        }

        return listener
    }

}
