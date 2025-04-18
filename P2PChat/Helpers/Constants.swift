//
//  Constants.swift
//  P2PChat
//
//  Created by Henrik Panhans on 27.03.25.
//

import CoreBluetooth
import Foundation
import P2PKit

extension Service {

    static var bonjour: BonjourService { BonjourService(type: "_p2pchat._tcp") }
    static var multipeer: MultipeerService { MultipeerService(type: "p2pchat") }
    static var bluetooth: BluetoothService {
        BluetoothService(
            uuid: CBUUID(string: "5879ACD3-E7F0-495D-940F-03E702379A1C"),
            characteristicUUID: CBUUID(string: "5879ACD3-E7F0-495D-940F-03E702379A1E")
        )
    }

}
