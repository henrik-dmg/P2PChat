//
//  BonjourDiscoveryService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import SwiftUI
import Network

@Observable
public final class BonjourDiscoveryService: BonjourDataTransferService, PeerDiscoveryService {

    // MARK: - Properties

    public let service: ServiceIdentifier
    public private(set) var state: ServiceState = .inactive
    public private(set) var availablePeers = [ChatPeer]()

    @ObservationIgnored
    private var browser: NWBrowser?
    @ObservationIgnored
    private let browserQueue = DispatchQueue(label: "browserQueue")

    // MARK: - Init

    public init(service: ServiceIdentifier) {
        self.service = service
        super.init()
    }

    // MARK: - PeerDiscoveryService

    public func startDiscoveringPeers() {
        guard browser == nil else {
            return // TODO: Throw error
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
        let descriptor = NWBrowser.Descriptor.bonjour(type: service.rawValue, domain: "local.")
        let browser = NWBrowser(for: descriptor, using: .tcp)
        browser.stateUpdateHandler = { newState in
            switch newState {
            case.ready:
                print("Browser ready")
            case .failed(let error):
                print("Browser error: \(error)")
            case .cancelled:
                print("Browser was stopped")
            default:
                print(newState)
            }
        }
        browser.browseResultsChangedHandler = { [weak self] updated, changes in
            print("Browser results changed:")
            for change in changes {
                switch change {
                case let .added(result):
                    let peer = BonjourPeer(endpoint: result.endpoint)
                    print("+ \(peer.id)")
                    self?.availablePeers.append(peer)
                case let .removed(result):
                    let peer = BonjourPeer(endpoint: result.endpoint)
                    print("- \(peer.id)")
                    self?.availablePeers.removeAll { peer in
                        peer.endpoint == result.endpoint
                    }
                case let .changed(old, new, flags):
                    let oldPeer = BonjourPeer(endpoint: old.endpoint)
                    let newPeer = BonjourPeer(endpoint: new.endpoint)

                    print("± \(oldPeer.id) \(newPeer.id)")
                    print("± \(old.hashValue.description) \(new.hashValue.description)")
                    print("± \(flags)")
                    let peerIndex = self?.availablePeers.firstIndex { peer in
                        peer.endpoint == old.endpoint
                    }
                    guard let peerIndex else {
                        break
                    }
                    self?.availablePeers[peerIndex] = newPeer
                case .identical:
                    fallthrough
                @unknown default:
                    print("?")
                }
            }
        }

        return browser
    }

}
