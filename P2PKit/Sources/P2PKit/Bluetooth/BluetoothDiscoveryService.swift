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

    public private(set) var state: ServiceState = .inactive
    public var availablePeers: [P] {
        Array(discoveredPeripherals.values)
    }

    private var discoveredPeripherals: [ID: P] = [:]

    // MARK: - PeerDiscoveryService

    public func startDiscoveringPeers() {
        guard centralManager.state == .poweredOn else {
            logger.error("Bluetooth is not powered on")
            return
        }

        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ]

        centralManager.scanForPeripherals(withServices: [service.type], options: options)
        updateState()
    }

    public func stopDiscoveringPeers() {
        discoveredPeripherals.removeAll()
        centralManager.stopScan()
        updateState()
    }

    // MARK: - Helpers

    private func updateState() {
        state = centralManager.isScanning ? .active : .inactive
    }

}

// MARK: - CBCentralManagerDelegate

extension BluetoothDiscoveryService {

    public override func centralManagerDidUpdateState(_ central: CBCentralManager) {
        super.centralManagerDidUpdateState(central)
        logger.info("Delegate is called")
        updateState()
    }

    public override func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        super.centralManager(
            central,
            didDiscover: peripheral,
            advertisementData: advertisementData,
            rssi: RSSI
        )

        let peerID = peerID(for: peripheral)
        discoveredPeripherals[peerID] = BluetoothPeer(
            peripheral: peripheral,
            advertisementData: advertisementData
        )
    }

}
