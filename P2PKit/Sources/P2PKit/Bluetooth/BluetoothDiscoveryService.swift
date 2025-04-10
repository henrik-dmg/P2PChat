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
    public var availablePeers: [ChatPeer] {
        Array(discoveredPeripherals.values)
    }

    @ObservationIgnored
    private var discoveredPeripherals: [PeerID: ChatPeer] = [:]

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

        centralManager.scanForPeripherals(withServices: [CBUUID(string: service.rawValue)], options: options)
        state = .active
    }

    public func stopDiscoveringPeers() {
        discoveredPeripherals.removeAll()
        centralManager.stopScan()
        state = .inactive
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothDiscoveryService {

    public override func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        super.centralManager(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)

        let peerID = peerID(for: peripheral)
        discoveredPeripherals[peerID] = BluetoothPeer(peripheral: peripheral, advertisementData: advertisementData)
    }

}
