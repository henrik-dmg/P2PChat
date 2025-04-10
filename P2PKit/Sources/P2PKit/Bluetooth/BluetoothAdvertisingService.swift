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
    private lazy var peripheralManager = makeManager()
    @ObservationIgnored
    private lazy var serviceID = CBUUID(string: service.rawValue)

    // MARK: - Init

    public init(service: ServiceIdentifier, ownPeerID: PeerID) {
        self.service = service
        super.init(ownPeerID: ownPeerID)
    }

    // MARK: - PeerAdvertisingService

    public func startAdvertisingService() {
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceID],
            CBAdvertisementDataLocalNameKey: ownPeerID,
        ]

        peripheralManager.startAdvertising(advertisementData)
        state = .active
    }

    public func stopAdvertisingService() {
        peripheralManager.stopAdvertising()
        state = .inactive
    }

    // MARK: - Helpers

    private func makeManager() -> CBPeripheralManager {
        let manager = CBPeripheralManager(delegate: self, queue: nil)
        manager.add(makeService())
        return manager
    }

    private func makeService() -> CBMutableService {
        let transferService = CBMutableService(type: serviceID, primary: true)

        let transferCharacteristic = CBMutableCharacteristic(
            type: serviceID,
            properties: [.write, .notify],
            value: nil,
            permissions: [.writeable]
        )

        transferService.characteristics = [transferCharacteristic]

        return transferService
    }

}

// MARK: - CBPeripheralManagerDelegate

extension BluetoothAdvertisingService: CBPeripheralManagerDelegate {

    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
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
            logger.warning("Unknown peripheral manager state: \(String(describing: peripheral.state))")
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
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

}
