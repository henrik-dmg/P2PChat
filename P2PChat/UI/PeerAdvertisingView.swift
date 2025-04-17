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
    private var sheetContent: SheetContent<ChatPeer>?

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
                }
            }
        }
        .navigationTitle("Advertising")
        .sheet(item: $sheetContent) { content in
            switch content {
            case let .chat(peerIDs):
                ChatsListView(peerIDs: peerIDs, service: service)
            case let .inspect(peer):
                informationService.peerInformationView(for: peer)
            }
        }
        .onChange(of: service.connectedPeers) { oldValue, newValue in
            if newValue.isEmpty {
                if case .chat = sheetContent {
                    service.disconnectAll()
                    self.sheetContent = nil
                }
            } else {
                self.sheetContent = .chat(newValue)
            }
        }
    }

}
