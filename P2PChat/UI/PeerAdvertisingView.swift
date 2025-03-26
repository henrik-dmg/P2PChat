//
//  PeerAdvertisingView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 26.03.25.
//

import P2PKit
import SwiftUI

struct PeerAdvertisingView<ChatPeer: Peer>: View {

    @State var service: any PeerAdvertisingService<ChatPeer>

    var body: some View {
        List {
            Section("Advertise") {
                LabeledContent("Service advertised", value: service.state.isActive ? "Yes" : "No")
                Button(service.state.isActive ? "Stop service" : "Start service") {
                    if service.state.isActive {
                        service.stopAdvertisingService()
                    } else {
                        service.startAdvertisingService()
                    }
                }
            }
        }
    }

}
