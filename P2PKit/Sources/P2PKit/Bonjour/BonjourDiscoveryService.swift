//
//  BonjourDiscoveryService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Network
import SwiftUI

@Observable
public final class BonjourDiscoveryService: BonjourDataTransferService, PeerDiscoveryService {

    // MARK: - Properties

    public let service: ServiceIdentifier
    public private(set) var state: ServiceState = .inactive
    public private(set) var availablePeers: [ChatPeer] = []

    @ObservationIgnored
    private var browser: NWBrowser?
    @ObservationIgnored
    private let browserQueue = DispatchQueue(label: "browserQueue")

    // MARK: - Init

    public init(service: ServiceIdentifier, ownPeerID: PeerID) {
        self.service = service
        super.init(ownPeerID: ownPeerID)
    }

    // MARK: - PeerDiscoveryService

    public func startDiscoveringPeers() {
        guard browser == nil else {
            return  // TODO: Throw error
        }
        browser = makeBrowser()
        browser?.start(queue: browserQueue)
        state = .active
    }

    public func stopDiscoveringPeers() {
        browser?.cancel()
        browser = nil
        availablePeers = []
        state = .inactive
    }

    // MARK: - Helpers

    func makeBrowser() -> NWBrowser {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true  // Allow discovery on Bluetooth, etc.

        let descriptor = NWBrowser.Descriptor.bonjour(type: service.rawValue, domain: nil)
        let browser = NWBrowser(for: descriptor, using: parameters)
        browser.stateUpdateHandler = { [weak self] newState in
            guard let self else { return }
            switch newState {
            case .setup:
                logger.info("Browser setup")
            case .ready:
                logger.info("Browser ready")
            case let .waiting(error):
                logger.error("Browser waiting: \(error)")
            case let .failed(error):
                logger.error("Browser failed: \(error)")
            case .cancelled:
                logger.info("Browser was stopped")
            @unknown default:
                logger.warning("Unknown browser state: \(String(describing: newState))")
            }
        }
        browser.browseResultsChangedHandler = { [weak self] updated, changes in
            print("Browser results changed:")
            for change in changes {
                switch change {
                case let .added(result):
                    let peer = BonjourPeer(endpoint: result.endpoint)
                    print("+ \(peer.id)")
                    print("+ \(result.interfaces)")
                    self?.availablePeers.append(peer)
                case let .removed(result):
                    let peer = BonjourPeer(endpoint: result.endpoint)
                    print("- \(peer.id)")
                    print("- \(result.interfaces)")
                    self?.availablePeers.removeAll { peer in
                        peer.endpoint == result.endpoint
                    }
                case let .changed(old, new, flags):
                    let oldPeer = BonjourPeer(endpoint: old.endpoint)
                    let newPeer = BonjourPeer(endpoint: new.endpoint)

                    print("± \(oldPeer.id) -> \(newPeer.id)")
                    print("± \(old.endpoint) -> \(new.endpoint)")
                    print("± \(flags)")
                    print("± \(old.interfaces) -> \(new.interfaces)")
                    let peerIndex = self?.availablePeers.firstIndex { peer in
                        peer.endpoint == old.endpoint
                    }
                    guard let peerIndex else {
                        continue
                    }
                    print("Updating peer")
                    self?.availablePeers[peerIndex] = newPeer
                case .identical:
                    continue
                @unknown default:
                    self?.logger.warning("Unknown change: \(String(describing: change))")
                }
            }
        }

        return browser
    }

}
