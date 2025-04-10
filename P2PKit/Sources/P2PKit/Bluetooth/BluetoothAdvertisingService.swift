//
//  BluetoothAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.04.25.
//

import CoreBluetooth
import Foundation
import Observation

@Observable
public final class BluetoothAdvertisingService: BluetoothDataTransferService, PeerAdvertisingService
{

    // MARK: - Properties

    public let service: ServiceIdentifier
    public private(set) var state: ServiceState = .inactive

    private let peripheralManager: CBPeripheralManager
    private let peripheralQueue: DispatchQueue
    @ObservationIgnored
    private lazy var serviceID = CBUUID(string: service.rawValue)

    // MARK: - Init

    public init(service: ServiceIdentifier, ownPeerID: PeerID) {
        self.service = service
        self.peripheralQueue = DispatchQueue(label: "peripheralQueue")
        self.peripheralManager = CBPeripheralManager(delegate: nil, queue: peripheralQueue, options: nil)
        super.init(ownPeerID: ownPeerID)
        peripheralManager.delegate = self
        peripheralManager.add(makeService())
    }

    // MARK: - PeerAdvertisingService

    public func startAdvertisingService() {
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceID],
            CBAdvertisementDataLocalNameKey: ownPeerID,
        ]

        peripheralManager.startAdvertising(advertisementData)
    }

    public func stopAdvertisingService() {
        peripheralManager.stopAdvertising()
    }

    // MARK: - Helpers

    private func makeManager() -> CBPeripheralManager {
        let manager = CBPeripheralManager(delegate: self, queue: nil)
        manager.add(makeService())
        return manager
    }

    private func makeService() -> CBMutableService {
        let transferService = CBMutableService(type: serviceID, primary: true)

        // Create separate UUIDs for read and write characteristics
        let readCharacteristicUUID = CBUUID(string: "\(service.rawValue)-read")
        let writeCharacteristicUUID = CBUUID(string: "\(service.rawValue)-write")

        // Read characteristic for receiving data
        let readCharacteristic = CBMutableCharacteristic(
            type: readCharacteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )

        // Write characteristic for sending data
        let writeCharacteristic = CBMutableCharacteristic(
            type: writeCharacteristicUUID,
            properties: [.write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )

        transferService.characteristics = [readCharacteristic, writeCharacteristic]

        return transferService
    }

}

// MARK: - CBPeripheralManagerDelegate

extension BluetoothAdvertisingService: CBPeripheralManagerDelegate {

    public func peripheralManagerDidUpdateState(_ peripheralManager: CBPeripheralManager) {
        switch peripheralManager.state {
        case .poweredOn:
            logger.info("Peripheral manager is powered on")
        case .poweredOff:
            logger.info("Peripheral manager is powered off")
        case .unauthorized:
            logger.info("Peripheral manager is unauthorized")
        case .unsupported:
            logger.info("Peripheral manager is unsupported")
        case .resetting:
            logger.info("Peripheral manager is resetting")
        case .unknown:
            logger.info("Peripheral manager state is unknown")
        @unknown default:
            logger.warning(
                "Unknown peripheral manager state: \(String(describing: peripheralManager.state))"
            )
        }

        state = peripheralManager.isAdvertising ? .active : .inactive
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        logger.info("Central subscribed to characteristic")
        // When a central subscribes, we can start sending data through notifications
        if let data = "Hello from peripheral".data(using: .utf8) {
            peripheral.updateValue(
                data,
                for: characteristic as! CBMutableCharacteristic,
                onSubscribedCentrals: [central]
            )
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        logger.info("Central unsubscribed from characteristic")
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for request in requests {
            guard let data = request.value else {
                peripheral.respond(to: request, withResult: .invalidAttributeValueLength)
                return
            }

            // Notify the delegate about received data
            delegate?.serviceReceived(data: data, from: request.central.identifier.uuidString)
            peripheral.respond(to: request, withResult: .success)
        }
    }

}
