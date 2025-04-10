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
public class BluetoothDataTransferService: NSObject, PeerDataTransferService {

    // MARK: - Nested Types

    public typealias ChatPeer = BluetoothPeer

    // MARK: - Properties

    public let ownPeerID: PeerID
    public var connectedPeers: [PeerID] {
        Array(peripherals.keys)
    }
    public weak var delegate: PeerDataTransferServiceDelegate?

    private(set) var peripherals: [PeerID: CBPeripheral] = [:]
    private(set) var writeCharacteristics: [PeerID: CBCharacteristic] = [:]

    let centralManager: CBCentralManager
    let connectionsQueue: DispatchQueue

    let logger = Logger.bluetooth

    // MARK: - Init

    init(ownPeerID: PeerID) {
        self.ownPeerID = ownPeerID
        self.connectionsQueue = DispatchQueue(label: "bluetoothQueue")
        self.centralManager = CBCentralManager(delegate: nil, queue: connectionsQueue)
        super.init()
        centralManager.delegate = self
    }

    // MARK: - PeerDataTransferService

    public func connect(to peer: BluetoothPeer) {
        guard centralManager.state == .poweredOn else {
            return
        }

        // Add connection options to prevent pairing UI
        let options: [String: Any] = [
            CBConnectPeripheralOptionNotifyOnConnectionKey: false,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: false,
            CBConnectPeripheralOptionNotifyOnNotificationKey: false,
        ]

        centralManager.connect(peer.peripheral, options: options)
        peripherals[peer.id] = peer.peripheral
    }

    public func send(_ data: Data, to peerID: PeerID) async throws {
        guard let peripheral = peripherals[peerID],
            let characteristic = writeCharacteristics[peerID]
        else {
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

    public func disconnect(from peerID: PeerID) {
        guard let peripheral = peripherals[peerID] else {
            return
        }

        centralManager.cancelPeripheralConnection(peripheral)
    }

    public func disconnectAll() {
        for id in peripherals.keys {
            disconnect(from: id)
        }
    }

    // MARK: - Helpers

    func peerID(for peripheral: CBPeripheral) -> PeerID {
        peripheral.identifier.uuidString
    }

    private func handlePeripheralConnected(_ peripheral: CBPeripheral) {
        let peerID = peerID(for: peripheral)
        peripherals[peerID] = peripheral
        // We're not calling the delegate here, because we are connected, but didn't discover write characteristics yet
    }

    private func handlePeripheralDisconnected(_ peripheral: CBPeripheral) {
        let peerID = peerID(for: peripheral)
        peripherals[peerID] = nil
        writeCharacteristics[peerID] = nil
        delegate?.serviceDidDisconnectFromPeer(with: peerID)
    }

}

// MARK: - CBCentralManagerDelegate

extension BluetoothDataTransferService: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            logger.info("Bluetooth is powered on")
        case .poweredOff:
            logger.info("Bluetooth is powered off")
            disconnectAll()
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
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        logger.info("Discovered peripheral: \(peripheral.identifier)")
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to peripheral: \(peripheral.identifier)")
        handlePeripheralConnected(peripheral)
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    public func centralManager(
        _ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?
    ) {
        logger.error("Failed to connect to peripheral: \(peripheral.identifier)")
    }

    public func centralManager(
        _ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        logger.info("Disconnected from peripheral 1: \(peripheral.identifier)")
        if let error {
            logger.error("Disconnect error: \(error)")
        }

        handlePeripheralDisconnected(peripheral)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: (any Error)?
    ) {
        logger.info("Disconnected from peripheral 2: \(peripheral.identifier)")
        if let error {
            logger.error("Disconnect error: \(error)")
        }

        handlePeripheralDisconnected(peripheral)
    }

}

// MARK: - CBPeripheralDelegate

extension BluetoothDataTransferService: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            logger.error("Error discovering services: \(error!)")
            return
        }

        guard let services = peripheral.services else {
            return
        }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil else {
            logger.error("Error discovering characteristics: \(error!)")
            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        for characteristic in characteristics {
            let properties = characteristic.properties
            if properties.contains(.write) || properties.contains(.writeWithoutResponse) {
                if let peerID = peripherals.first(where: { $0.value == peripheral })?.key {
                    writeCharacteristics[peerID] = characteristic
                    delegate?.serviceDidConnectToPeer(with: peerID)
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
        guard error == nil, let data = characteristic.value else {
            logger.error(
                "Error updating value for characteristic: \(error?.localizedDescription ?? "Unknown error")"
            )
            return
        }

        let peerID = peerID(for: peripheral)
        delegate?.serviceReceived(data: data, from: peerID)
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
