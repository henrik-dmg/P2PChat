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

    @State var service: any PeerAdvertisingService<ChatPeer>
    let informationService: InformationService

    @State private var sheetContent: SheetContent<ChatPeer>?

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
                NavigationStack {
                    TabView {
                        ForEach(peerIDs, id: \.self) { peerID in
                            ChatView(service: service, peerID: peerID)
                        }
                    }
                }
            case let .inspect(peer):
                informationService.peerInformationView(for: peer)
            }
        }
        .onChange(of: service.connectedPeers) { oldValue, newValue in
            guard !newValue.isEmpty else {
                if case .chat = sheetContent {
                    self.sheetContent = nil
                }
                return
            }
            self.sheetContent = .chat(newValue)
        }
    }

}
