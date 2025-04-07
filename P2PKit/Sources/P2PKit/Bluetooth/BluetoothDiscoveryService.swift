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
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
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
        centralManager?.stopScan()
        availablePeers = []
        discoveredPeripherals.removeAll()
        state = .inactive
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothDiscoveryService {

    public override func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        print("Discovered peripheral: \(peripheral.identifier)")

        //        var updatedAdvertisementData = peripheral.

        let peer = BluetoothPeer(
            peripheral: peripheral,
            advertisementData: [:]
        )

        discoveredPeripherals[peripheral.identifier] = peripheral

        if !availablePeers.contains(where: { $0.id == peer.id }) {
            availablePeers.append(peer)
        }
    }

    public override func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {

    }

    public override func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        super.centralManager(central, didDisconnectPeripheral: peripheral, error: error)

        discoveredPeripherals[peripheral.identifier] = nil
        availablePeers.removeAll { $0.peripheral.identifier == peripheral.identifier }
    }

}
