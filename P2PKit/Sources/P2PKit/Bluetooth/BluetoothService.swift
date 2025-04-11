//
//  BluetoothService.swift
//  P2PKit
//
//  Created by Henrik Panhans on 10.04.25.
//

import CoreBluetooth

public struct BluetoothService: Service {

    public let type: CBUUID
    public let writeCharacteristicUUID: String
    public let readCharacteristicUUID: String

    public init(type: CBUUID, writeCharacteristicUUID: String, readCharacteristicUUID: String) {
        self.type = type
        self.writeCharacteristicUUID = writeCharacteristicUUID
        self.readCharacteristicUUID = readCharacteristicUUID
    }

}
