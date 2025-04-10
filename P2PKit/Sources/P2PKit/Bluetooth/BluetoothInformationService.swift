//
//  BluetoothInformationService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.04.25.
//

import SwiftUI

public struct BluetoothInformationService: PeerInformationService {

    // MARK: - Nested Types

    public typealias P = BluetoothPeer

    // MARK: - Init

    public init() {}

    // MARK: - Methods

    public func peerCellView(for peer: P) -> some View {
        VStack(alignment: .leading) {
            Text(peer.name)
            //            if let rssi = peer.rssi {
            //                Text("Signal Strength: \(rssi.intValue) dBm")
            //            }
        }
    }

    public func peerInformationView(for peer: P) -> some View {
        NavigationView {
            List {
                LabeledContent("Name", value: peer.name)
                LabeledContent("ID", value: peer.id)
                //                if let rssi = peer.rssi {
                //                    LabeledContent("Signal Strength", value: "\(rssi.intValue) dBm")
                //                }
            }
        }
    }

}
