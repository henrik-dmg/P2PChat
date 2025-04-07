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

    public let service: ServiceIdentifier
    public private(set) var state: ServiceState = .inactive

    @ObservationIgnored
    private var peripheralManager: CBPeripheralManager?
    @ObservationIgnored
    private var transferCharacteristic: CBMutableCharacteristic?
    @ObservationIgnored
    private var transferService: CBMutableService?

    // MARK: - Init

    public init(service: ServiceIdentifier, ownPeerID: PeerID) {
        self.service = service
        super.init(ownPeerID: ownPeerID)
    }

    // MARK: - PeerAdvertisingService

    public func startAdvertisingService() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    public func stopAdvertisingService() {
        peripheralManager?.stopAdvertising()
        peripheralManager = nil
        state = .inactive
    }

}

// MARK: - CBPeripheralManagerDelegate

extension BluetoothAdvertisingService: CBPeripheralManagerDelegate {

    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            logger.info("Peripheral manager is powered on")
            setupService()
        case .poweredOff:
            logger.info("Peripheral manager is powered off")
            stopAdvertisingService()
        case .unauthorized:
            logger.info("Peripheral manager is unauthorized")
        case .unsupported:
            logger.info("Peripheral manager is unsupported")
        case .resetting:
            logger.info("Peripheral manager is resetting")
        case .unknown:
            logger.info("Peripheral manager state is unknown")
        @unknown default:
            logger.warning("Unknown peripheral manager state: \(String(describing: peripheral.state))")
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        logger.info("Central subscribed to characteristic")
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        logger.info("Central unsubscribed from characteristic")
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard let data = request.value else {
                peripheral.respond(to: request, withResult: .invalidAttributeValueLength)
                return
            }

            delegate?.serviceReceived(data: data, from: request.central.identifier.uuidString)
            peripheral.respond(to: request, withResult: .success)
        }
    }

    // MARK: - Helpers

    private func setupService() {
        transferCharacteristic = CBMutableCharacteristic(
            type: CBUUID(nsuuid: UUID()),
            properties: [.write, .notify],
            value: nil,
            permissions: [.writeable]
        )

        transferService = CBMutableService(
            type: CBUUID(nsuuid: UUID()),
            primary: true
        )

        transferService?.characteristics = [transferCharacteristic!]

        peripheralManager?.add(transferService!)

        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(nsuuid: UUID())],
            CBAdvertisementDataLocalNameKey: ownPeerID,
        ]

        peripheralManager?.startAdvertising(advertisementData)
        state = .active
    }

}
