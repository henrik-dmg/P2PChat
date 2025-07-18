//
//  PeerAdvertisingView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 26.03.25.
//

import Observation
import P2PKit
import SwiftUI

struct PeerAdvertisingView<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: View {

    @State
    var service: any PeerAdvertisingService<ChatPeer>
    let informationService: InformationService

    @State
    private var sheetContent: ChatSheetContent<ChatPeer>?

    var body: some View {
        List {
            Section("Advertise") {
                LabeledContent("Service advertised") {
                    Text(service.state.isActive ? "Yes" : "No")
                        .foregroundStyle(service.state.isActive ? .green : .red)
                }
                Button(service.state.isActive ? "Stop service" : "Start service") {
                    if service.state.isActive {
                        service.stopAdvertisingService()
                    } else {
                        service.startAdvertisingService()
                    }
                }.sensoryFeedback(service.state.isActive ? .start : .stop, trigger: service.state)
            }
        }
        .navigationTitle("Advertising")
        .chatSheet($sheetContent, service: service, informationService: informationService)
    }

}
