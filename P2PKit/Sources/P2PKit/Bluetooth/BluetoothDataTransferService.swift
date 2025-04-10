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

    private(set) var peripherals: [PeerID: CBPeripheral] = [:]
    private(set) var writeCharacteristics: [PeerID: CBCharacteristic] = [:]

    @ObservationIgnored
    lazy var centralManager = makeManager()
    @ObservationIgnored
    private let connectionsQueue = DispatchQueue(label: "bluetoothQueue")

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
        guard let peripheral = peripherals[peerID], let characteristic = writeCharacteristics[peerID] else {
            return
        }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
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

    private func makeManager() -> CBCentralManager {
        CBCentralManager(delegate: self, queue: nil)
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

    func peerID(for peripheral: CBPeripheral) -> PeerID {
        peripheral.identifier.uuidString
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
        advertisementData: [String : Any], 
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

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        logger.error("Failed to connect to peripheral: \(peripheral.identifier)")
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
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
        isReconnecting: Bool, error: (any Error)?
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
        guard error == nil, let data = characteristic.value else {
            return
        }

        let peerID = peerID(for: peripheral)
        delegate?.serviceReceived(data: data, from: peerID)
    }

}
