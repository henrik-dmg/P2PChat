//
//  BluetoothAdvertisingService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.04.25.
//

import CoreBluetooth
import Foundation
import OSLog
import Observation

@Observable
@available(visionOS, unavailable)
public final class BluetoothAdvertisingService: NSObject, PeerAdvertisingService {

    // MARK: - Nested Types

    public typealias P = BluetoothPeer
    public typealias S = BluetoothService

    // MARK: - Properties

    public private(set) var state: ServiceState = .inactive
    public let ownPeerID: ID
    public let service: S
    public weak var delegate: PeerDataTransferServiceDelegate?
    public weak var advertisingDelegate: (any PeerAdvertisingServiceDelegate<S>)?

    public var connectedPeers: [ID] {
        Array(centrals.keys)
    }

    private var centrals: [ID: CBCentral] = [:]
    private let peripheralManager: CBPeripheralManager
    private let peripheralQueue: DispatchQueue
    private let logger = Logger.bluetooth

    @ObservationIgnored
    private lazy var cbService: CBMutableService = makeService()

    @ObservationIgnored
    private lazy var readCharacteristic: CBMutableCharacteristic = {
        CBMutableCharacteristic(
            type: service.readCharacteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
    }()

    @ObservationIgnored
    private lazy var writeCharacteristic: CBMutableCharacteristic = {
        CBMutableCharacteristic(
            type: service.writeCharacteristicUUID,
            properties: [.write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
    }()

    // MARK: - Init

    public init(ownPeerID: ID, service: S) {
        self.ownPeerID = ownPeerID
        self.service = service
        self.peripheralQueue = DispatchQueue(label: "peripheralQueue")
        self.peripheralManager = CBPeripheralManager(
            delegate: nil,
            queue: peripheralQueue,
            options: nil
        )
        super.init()
        peripheralManager.delegate = self
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
            self?.updateState(self?.peripheralManager.isAdvertising == true ? .active : .inactive)
        }
    }

    // MARK: - Helpers

    private func makeService() -> CBMutableService {
        let transferService = CBMutableService(type: service.uuid, primary: true)
        transferService.characteristics = [readCharacteristic, writeCharacteristic]
        return transferService
    }

    private func updateState(_ newState: ServiceState) {
        switch newState {
        case .active:
            logger.info("Peripheral manager started advertising")
            advertisingDelegate?.serviceDidStartAdvertising(service)
        case .inactive:
            logger.info("Peripheral manager stopped advertising")
            advertisingDelegate?.serviceDidStopAdvertising(service)
        case let .error(error):
            logger.error("Advertiser did not start: \(error)")
        }
        state = newState
    }

    private func peerID(for central: CBCentral) -> ID {
        central.identifier.uuidString
    }

    private func handlePeripheralConnected(_ central: CBCentral) {
        let peerID = peerID(for: central)
        centrals[peerID] = central
        delegate?.serviceDidConnectToPeer(with: peerID)
    }

    private func handlePeripheralDisconnected(_ central: CBCentral) {
        let peerID = peerID(for: central)
        centrals[peerID] = nil
        delegate?.serviceDidDisconnectFromPeer(with: peerID)
    }

}

// MARK: - PeerDataTransferService

extension BluetoothAdvertisingService: PeerDataTransferService {

    public func connect(to peer: BluetoothPeer) {
        logger.error("Connect should never be called on peripheral mode")
    }

    public func send(_ data: Data, to peerID: ID) async throws {
        guard let central = centrals[peerID] else {
            logger.error("No central found for peer \(peerID)")
            return
        }

        // Split data into chunks if it's too large (BLE has a 20-byte limit per packet)
        let chunkSize = 20
        let chunks = stride(from: 0, to: data.count, by: chunkSize).map {
            data[$0..<min($0 + chunkSize, data.count)]
        }

        for chunk in chunks {
            peripheralManager.updateValue(
                chunk,
                for: readCharacteristic,
                onSubscribedCentrals: [central]
            )
        }
    }

    public func disconnect(from peerID: ID) {
        guard let central = centrals[peerID] else {
            logger.error("No central \(peerID) to disconnect from")
            return
        }

        // Remove the central from our tracking
        centrals[peerID] = nil
        delegate?.serviceDidDisconnectFromPeer(with: peerID)
    }

    public func disconnectAll() {
        for id in centrals.keys {
            disconnect(from: id)
        }
    }

}

// MARK: - CBPeripheralManagerDelegate

@available(visionOS, unavailable)
extension BluetoothAdvertisingService: CBPeripheralManagerDelegate {

    public func peripheralManagerDidUpdateState(_ peripheralManager: CBPeripheralManager) {
        switch peripheralManager.state {
        case .poweredOn:
            logger.info("Peripheral manager is powered on")
            peripheralManager.add(cbService)
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
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        logger.info("Central subscribed to characteristic \(characteristic.uuid)")
        handlePeripheralConnected(central)
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        logger.info("Central unsubscribed from characteristic \(characteristic.uuid)")
        handlePeripheralDisconnected(central)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        logger.info("Peripheral manager received \(requests.count) write requests")
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
        if let error {
            updateState(.error(error))
            return
        }
        updateState(.active)
    }

    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        logger.info("Peripheral manager is ready")
    }

}
