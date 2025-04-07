//
//  BluetoothDiscoveryService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.04.25.
//

import CoreBluetooth
import Foundation
import Observation

@Observable
public final class BluetoothDiscoveryService: BluetoothDataTransferService, PeerDiscoveryService {

    // MARK: - Properties

    public let service: ServiceIdentifier
    public private(set) var state: ServiceState = .inactive
    public private(set) var availablePeers: [ChatPeer] = []

    @ObservationIgnored
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]

    // MARK: - Init

    public init(service: ServiceIdentifier, ownPeerID: PeerID) {
        self.service = service
        super.init(ownPeerID: ownPeerID)
    }

    // MARK: - PeerDiscoveryService

    public func startDiscoveringPeers() {
        guard centralManager.state == .poweredOn else {
            return
        }

        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]

        centralManager.scanForPeripherals(
            withServices: [CBUUID(string: service.rawValue)],
            options: options
        )

        state = .active
    }

    public func stopDiscoveringPeers() {
        centralManager.stopScan()
        availablePeers = []
        discoveredPeripherals.removeAll()
        state = .inactive
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothDiscoveryService {

    // TODO: Fill out stuff here

}
