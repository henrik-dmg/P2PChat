//
//  BonjourDiscoveryService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import SwiftUI
import Network

@Observable
final class BonjourDiscoveryService: NSObject, PeerDiscoveryService {

    // MARK: - Nested Types

    typealias ChatPeer = BonjourPeer

    // MARK: - Properties

    let service: ServiceIdentifier
    private(set) var discoveryState: ServiceState = .inactive
    private(set) var availablePeers = [ChatPeer]()

    @ObservationIgnored
    private var browser: NWBrowser?
    @ObservationIgnored
    private let browserQueue = DispatchQueue(label: "browserQueue")

    // MARK: - Init

    init(service: ServiceIdentifier) {
        self.service = service
        super.init()
    }

    // MARK: - PeerDiscoveryService

    func startDiscoveringPeers() {
        guard browser == nil else {
            return // TODO: Throw error
        }
        browser = makeBrowser()
        browser?.start(queue: browserQueue)
        discoveryState = .active
    }

    func stopDiscoveringPeers() {
        browser?.cancel()
        browser = nil
        availablePeers = []
        discoveryState = .inactive
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
            print("browser results did change:")
            for change in changes {
                switch change {
                case let .added(result):
                    print("+ \(result.endpoint)")
                    let peer = BonjourPeer(id: result.hashValue.description, endpoint: result.endpoint)
                    self?.availablePeers.append(peer)
                case let .removed(result):
                    print("- \(result.endpoint)")
                    self?.availablePeers.removeAll { peer in
                        peer.endpoint == result.endpoint
                    }
                case let .changed(old, new, flags):
                    print("± \(old.endpoint) \(new.endpoint)")
                    print("± \(old.hashValue.description) \(new.hashValue.description)")
                    print("± \(flags)")
                    let peerIndex = self?.availablePeers.firstIndex { peer in
                        peer.endpoint == old.endpoint
                    }
                    guard let peerIndex else {
                        break
                    }
                    self?.availablePeers[peerIndex] = BonjourPeer(id: new.hashValue.description, endpoint: new.endpoint)
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
