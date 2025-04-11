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
public final class BluetoothAdvertisingService: BluetoothDataTransferService, PeerAdvertisingService {

    // MARK: - Properties

    public private(set) var state: ServiceState = .inactive

    private let peripheralManager: CBPeripheralManager
    private let peripheralQueue: DispatchQueue

    @ObservationIgnored
    private lazy var cbService: CBMutableService = makeService()

    @ObservationIgnored
    private lazy var readCharacteristic: CBMutableCharacteristic = {
        // Create separate UUIDs for read characteristics
        let readCharacteristicUUID = CBUUID(string: service.readCharacteristicUUID)

        // Read characteristic for receiving data
        return CBMutableCharacteristic(
            type: readCharacteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
    }()

    @ObservationIgnored
    private lazy var writeCharacteristic: CBMutableCharacteristic = {
        // Create separate UUIDs for write characteristics
        let writeCharacteristicUUID = CBUUID(string: service.writeCharacteristicUUID)

        // Write characteristic for sending data
        return CBMutableCharacteristic(
            type: writeCharacteristicUUID,
            properties: [.write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
    }()

    // MARK: - Init

    public override init(ownPeerID: ID, service: S) {
        self.peripheralQueue = DispatchQueue(label: "peripheralQueue")
        self.peripheralManager = CBPeripheralManager(delegate: nil, queue: peripheralQueue, options: nil)
        super.init(ownPeerID: ownPeerID, service: service)
        peripheralManager.delegate = self
        peripheralManager.add(cbService)
    }

    // MARK: - PeerAdvertisingService

    public func startAdvertisingService() {
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [cbService.uuid],
            CBAdvertisementDataLocalNameKey: ownPeerID,
        ]

        peripheralManager.startAdvertising(advertisementData)
    }

    public func stopAdvertisingService() {
        peripheralManager.stopAdvertising()
        peripheralQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.logger.info("Peripheral manager stopped advertising")
            self?.updateState()
        }
    }

    // MARK: - Helpers

    private func makeService() -> CBMutableService {
        let transferService = CBMutableService(type: service.type, primary: true)
        transferService.characteristics = [readCharacteristic, writeCharacteristic]
        return transferService
    }

    private func updateState() {
        state = peripheralManager.isAdvertising ? .active : .inactive
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

        updateState()
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

    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: (any Error)?) {
        logger.info("Peripheral manager added service \(service.uuid)")
    }

    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        logger.info("Peripheral manager started advertising \(peripheral.isAdvertising)")
        updateState()
    }

}
