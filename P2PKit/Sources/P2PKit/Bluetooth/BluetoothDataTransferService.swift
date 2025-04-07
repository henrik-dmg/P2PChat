//
//  BluetoothDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.04.25.
//

import CoreBluetooth
import Foundation
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
    @ObservationIgnored
    private(set) var centralManager: CBCentralManager?
    @ObservationIgnored
    private(set) var writeCharacteristics: [PeerID: CBCharacteristic] = [:]

    // MARK: - Init

    init(ownPeerID: PeerID) {
        self.ownPeerID = ownPeerID
        super.init()
    }

    // MARK: - PeerDataTransferService

    public func configure() async throws {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    public func connect(to peer: BluetoothPeer) {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            return
        }

        centralManager.connect(peer.peripheral, options: nil)
        peripherals[peer.id] = peer.peripheral
    }

    public func send(_ data: Data, to peerID: PeerID) async throws {
        guard let peripheral = peripherals[peerID],
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

        centralManager?.cancelPeripheralConnection(peripheral)
        peripherals[peerID] = nil
        writeCharacteristics[peerID] = nil
        delegate?.serviceDidDisconnectFromPeer(with: peerID)
    }

    public func disconnectAll() {
        for id in peripherals.keys {
            disconnect(from: id)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothDataTransferService: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            print("Bluetooth is powered off")
            disconnectAll()
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unsupported:
            print("Bluetooth is unsupported")
        case .resetting:
            print("Bluetooth is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("Unknown Bluetooth state")
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.identifier)")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        print("Disconnected from peripheral: \(peripheral.identifier)")
        if let error = error {
            print("Disconnect error: \(error)")
        }

        if let peerID = peripherals.first(where: { $0.value == peripheral })?.key {
            disconnect(from: peerID)
        }
    }

}

// MARK: - CBPeripheralDelegate

extension BluetoothDataTransferService: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!)")
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
            print("Error discovering characteristics: \(error!)")
            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        for characteristic in characteristics {
            if characteristic.properties.contains(.write)
                || characteristic.properties.contains(.writeWithoutResponse)
            {
                if let peerID = peripherals.first(where: { $0.value == peripheral })?.key {
                    writeCharacteristics[peerID] = characteristic
                    delegate?.serviceDidConnectToPeer(with: peerID)
                }
            }

            if characteristic.properties.contains(.notify)
                || characteristic.properties.contains(.read)
            {
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
