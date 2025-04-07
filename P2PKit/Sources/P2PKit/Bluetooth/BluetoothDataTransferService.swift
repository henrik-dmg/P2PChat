//
//  BluetoothDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.04.25.
//

import CoreBluetooth
import Foundation
import Observation
import OSLog

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

    private var peripherals: [PeerID: CBPeripheral] = [:]
    @ObservationIgnored
    lazy var centralManager = makeManager()
    @ObservationIgnored
    private(set) var writeCharacteristics: [PeerID: CBCharacteristic] = [:]

    let logger = Logger.bluetooth

    // MARK: - Init

    init(ownPeerID: PeerID) {
        self.ownPeerID = ownPeerID
        super.init()
    }

    // MARK: - PeerDataTransferService

    public func connect(to peer: BluetoothPeer) {
        guard centralManager.state == .poweredOn else {
            return
        }

        centralManager.connect(peer.peripheral, options: nil)
        peripherals[peer.id] = peer.peripheral
    }

    public func send(_ data: Data, to peerID: PeerID) async throws {
        guard
            let peripheral = peripherals[peerID],
            let characteristic = writeCharacteristics[peerID]
        else {
            return
        }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    public func disconnect(from peerID: PeerID) {
        guard let peripheral = peripherals[peerID] else {
            return
        }

        centralManager.cancelPeripheralConnection(peripheral)
        peripherals[peerID] = nil
        writeCharacteristics[peerID] = nil
        delegate?.serviceDidDisconnectFromPeer(with: peerID)
    }

    public func disconnectAll() {
        for id in peripherals.keys {
            disconnect(from: id)
        }
    }

    // MARK: - Helpers

    private func makeManager() -> CBCentralManager {
        CBCentralManager(delegate: self, queue: nil)
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
            logger.info("Bluetooth is unauthorized")
        case .unsupported:
            logger.info("Bluetooth is unsupported")
        case .resetting:
            logger.info("Bluetooth is resetting")
        case .unknown:
            logger.info("Bluetooth state is unknown")
        @unknown default:
            logger.warning("Unknown Bluetooth state")
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to peripheral: \(peripheral.identifier)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        logger.info("Disconnected from peripheral: \(peripheral.identifier)")
        if let error = error {
            logger.error("Disconnect error: \(error)")
        }

        if let peerID = peripherals.first(where: { $0.value == peripheral })?.key {
            disconnect(from: peerID)
        }
    }

    public func centralManager(
        _ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?
    ) {

    }

    public func centralManager(
        _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any], rssi RSSI: NSNumber
    ) {

    }

    public func centralManager(
        _ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?
    ) {

    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {

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
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                if let peerID = peripherals.first(where: { $0.value == peripheral })?.key {
                    writeCharacteristics[peerID] = characteristic
                    delegate?.serviceDidConnectToPeer(with: peerID)
                }
            }

            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.read) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil,
            let data = characteristic.value,
            let peerID = peripherals.first(where: { $0.value == peripheral })?.key
        else {
            return
        }

        delegate?.serviceReceived(data: data, from: peerID)
    }

}
