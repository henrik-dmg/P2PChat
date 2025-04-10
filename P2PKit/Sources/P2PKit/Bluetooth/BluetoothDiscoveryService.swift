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
    @ObservationIgnored
    private lazy var serviceID = CBUUID(string: service.rawValue)

    // MARK: - Init

    public init(service: ServiceIdentifier, ownPeerID: PeerID) {
        self.service = service
        super.init(ownPeerID: ownPeerID)
        centralManager.delegate = self  // TODO: Double-check if this is needed
    }

    // MARK: - PeerDiscoveryService

    public func startDiscoveringPeers() {
        guard centralManager.state == .poweredOn else {
            logger.error("Bluetooth is not powered on")
            return
        }

        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ]

        centralManager.scanForPeripherals(withServices: [serviceID], options: options)
    }

    public func stopDiscoveringPeers() {
        discoveredPeripherals.removeAll()
        centralManager.stopScan()
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothDiscoveryService {

    public override func centralManagerDidUpdateState(_ central: CBCentralManager) {
        super.centralManagerDidUpdateState(central)
        state = central.isScanning ? .active : .inactive
    }

    public override func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        super.centralManager(
            central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)

        let peerID = peerID(for: peripheral)
        discoveredPeripherals[peerID] = BluetoothPeer(
            peripheral: peripheral, advertisementData: advertisementData)
    }

}
