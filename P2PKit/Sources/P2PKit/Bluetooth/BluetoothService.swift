//
//  BluetoothService.swift
//  P2PKit
//
//  Created by Henrik Panhans on 10.04.25.
//

import CoreBluetooth

public struct BluetoothService: Service {

    public let uuid: CBUUID
    public let writeCharacteristicUUID: CBUUID
    public let readCharacteristicUUID: CBUUID

    public init(uuid: CBUUID, writeCharacteristicUUID: CBUUID, readCharacteristicUUID: CBUUID) {
        self.uuid = uuid
        self.writeCharacteristicUUID = writeCharacteristicUUID
        self.readCharacteristicUUID = readCharacteristicUUID
    }

}
