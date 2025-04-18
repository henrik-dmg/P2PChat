//
//  BluetoothDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.04.25.
//

import CoreBluetooth
import Foundation
import OSLog
import Observation

@Observable
public class BluetoothDiscoveryService: NSObject, PeerDiscoveryService {

    // MARK: - Nested Types

    public typealias P = BluetoothPeer
    public typealias S = BluetoothService

    // MARK: - Properties

    public private(set) var state: ServiceState = .inactive
    public let ownPeerID: ID
    public let service: S
    public weak var delegate: PeerDataTransferServiceDelegate?

    public var availablePeers: [P] {
        Array(discoveredPheripherals.values)
    }
    public var connectedPeers: [ID] {
        Array(connectedPheripherals.keys)
    }

    private var discoveredPheripherals: [ID: P] = [:]
    private var connectedPheripherals: [ID: CBPeripheral] = [:]
    @ObservationIgnored
    private var writeCharacteristics: [ID: CBCharacteristic] = [:]
    @ObservationIgnored
    private var receivedData: [ID: Data] = [:]
    private let centralManager: CBCentralManager
    private let centralsQueue: DispatchQueue
    private let logger = Logger.bluetooth

    // MARK: - Init

    public init(ownPeerID: ID, service: S) {
        self.ownPeerID = ownPeerID
        self.service = service
        self.centralsQueue = DispatchQueue(label: "bluetoothQueue")
        self.centralManager = CBCentralManager(delegate: nil, queue: centralsQueue)
        super.init()
        centralManager.delegate = self
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

        centralManager.scanForPeripherals(withServices: [service.uuid], options: options)
        updateState()
    }

    public func stopDiscoveringPeers() {
        centralManager.stopScan()
        discoveredPheripherals.removeAll()
        updateState()
    }

    // MARK: - Helpers

    private func updateState() {
        state = centralManager.isScanning ? .active : .inactive
    }

    private func peerID(for peripheral: CBPeripheral) -> ID {
        peripheral.identifier.uuidString
    }

    private func handlePeripheralConnected(_ peripheral: CBPeripheral) {
        let peerID = peerID(for: peripheral)
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        connectedPheripherals[peerID] = peripheral
        delegate?.serviceDidConnectToPeer(with: peerID)
    }

    private func handlePeripheralDisconnected(_ peripheral: CBPeripheral) {
        let peerID = peerID(for: peripheral)
        connectedPheripherals[peerID] = nil
        writeCharacteristics[peerID] = nil
        receivedData[peerID] = nil
        delegate?.serviceDidDisconnectFromPeer(with: peerID)
    }

}

// MARK: - PeerDataTransferService

extension BluetoothDiscoveryService: PeerDataTransferService {

    public func connect(to peer: BluetoothPeer) {
        guard centralManager.state == .poweredOn else {
            logger.error("Bluetooth is not powered on")
            return
        }

        // Add connection options to prevent pairing UI
        let options: [String: Any] = [:]
        //            CBConnectPeripheralOptionNotifyOnConnectionKey: false,
        //            CBConnectPeripheralOptionNotifyOnDisconnectionKey: false,
        //            CBConnectPeripheralOptionNotifyOnNotificationKey: false,
        //        ]

        centralManager.connect(peer.peripheral, options: options)
    }

    public func send(_ data: Data, to peerID: ID) async throws {
        guard let peripheral = connectedPheripherals[peerID], let characteristic = writeCharacteristics[peerID] else {
            return
        }

        // Split data into chunks if it's too large (BLE has a 20-byte limit per packet)
        let chunkSize = 20
        let chunks = stride(from: 0, to: data.count, by: chunkSize).map {
            data[$0..<min($0 + chunkSize, data.count)]
        }

        for chunk in chunks {
            peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
        }
    }

    public func disconnect(from peerID: ID) {
        guard let peripheral = connectedPheripherals[peerID] else {
            logger.error("No peripheral \(peerID) to disconnect from")
            return
        }

        centralManager.cancelPeripheralConnection(peripheral)
    }

    public func disconnectAll() {
        for peripheral in connectedPheripherals.values {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothDiscoveryService: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ centralManager: CBCentralManager) {
        switch centralManager.state {
        case .poweredOn:
            logger.info("Bluetooth is powered on")
        case .poweredOff:
            logger.info("Bluetooth is powered off")
        case .unauthorized:
            logger.warning("Bluetooth is unauthorized")
        case .unsupported:
            logger.warning("Bluetooth is unsupported")
        case .resetting:
            logger.info("Bluetooth is resetting")
        case .unknown:
            logger.warning("Bluetooth state is unknown")
        @unknown default:
            logger.warning("Unknown Bluetooth state")
        }
    }

    public func centralManager(
        _ centralManager: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        logger.info("Discovered peripheral: \(peripheral.identifier) with RSSI \(RSSI)")
        let peerID = peerID(for: peripheral)
        discoveredPheripherals[peerID] = BluetoothPeer(
            peripheral: peripheral,
            advertisementData: advertisementData
        )
    }

    public func centralManager(_ centralManager: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to peripheral: \(peripheral.safeName)")
        handlePeripheralConnected(peripheral)
    }

    public func centralManager(
        _ centralManager: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        logger.error("Failed to connect to peripheral \(peripheral.safeName): \(error?.localizedDescription ?? "unknown")")
    }

    public func centralManager(
        _ centralManager: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        logger.info("Disconnected from peripheral 1: \(peripheral.safeName)")
        if let error {
            logger.error("Disconnect error 1: \(error)")
        }
        handlePeripheralDisconnected(peripheral)
    }

    public func centralManager(
        _ centralManager: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        logger.info("Disconnected from peripheral 2: \(peripheral.safeName)")
        if let error {
            logger.error("Disconnect error 2: \(error)")
        }
        handlePeripheralDisconnected(peripheral)
    }

}

// MARK: - CBPeripheralDelegate

extension BluetoothDiscoveryService: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            logger.error("Error discovering services: \(error!)")
            return
        }

        guard let services = peripheral.services else {
            return
        }

        for service in services where service.uuid == self.service.uuid {
            peripheral.discoverCharacteristics([self.service.readCharacteristicUUID, self.service.writeCharacteristicUUID], for: service)
            break
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error {
            logger.error("Error discovering characteristic: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        logger.info("Discovered \(characteristics.count) characteristics for peripheral \(peripheral.safeName)")

        for characteristic in characteristics {
            let properties = characteristic.properties
            if properties.contains(.write) || properties.contains(.writeWithoutResponse) {
                if let peerID = connectedPheripherals.first(where: { $0.value == peripheral })?.key {
                    writeCharacteristics[peerID] = characteristic
                }
            }

            if properties.contains(.notify) || properties.contains(.read) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            logger.error("Error updating value for characteristic: \(error.localizedDescription)")
            return
        }

        guard let characteristicData = characteristic.value, let stringFromData = String(data: characteristicData, encoding: .utf8) else {
            return
        }

        let peerID = peerID(for: peripheral)
        logger.debug("Received \(characteristicData.count)")

        //        // Have we received the end-of-message token?
        //        if stringFromData == "EOM" {
        //            // End-of-message case: show the data.
        //            // Dispatch the text view update to the main queue for updating the UI, because
        //            // we don't know which thread this method will be called back on.
        //            if let receivedData = receivedData[peerID] {
        //                self.receivedData[peerID] = nil
        //                delegate?.serviceReceived(data: receivedData, from: peerID)
        //            }
        //        } else {
        //            // Otherwise, just append the data to what we have previously received.
        //            if receivedData[peerID] != nil {
        //                receivedData[peerID]?.append(characteristicData)
        //            } else {
        //                receivedData[peerID] = characteristicData
        //            }
        //        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            logger.error("Error writing value for characteristic: \(error)")
        } else {
            logger.info("Successfully wrote value for characteristic")
        }
    }

}
