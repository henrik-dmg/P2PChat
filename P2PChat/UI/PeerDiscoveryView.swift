//
//  PeerDiscoveryView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

import SwiftUI

struct PeerDiscoveryView<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: View {

    @State var discoveryService: any PeerDiscoveryService<ChatPeer>
    @State var advertisingService: any PeerAdvertisingService<ChatPeer>
    @State var dataTransferService: any PeerDataTransferService<ChatPeer>
    let peerInformationService: InformationService

    @State private var inspectedPeer: ChatPeer?

    var body: some View {
        List {
            Section("Advertise") {
                LabeledContent("Service advertised", value: advertisingService.advertisingState.isActive ? "Yes" : "No")
                Button(advertisingService.advertisingState.isActive ? "Stop service" : "Start service") {
                    if advertisingService.advertisingState.isActive {
                        advertisingService.stopAdvertisingService()
                    } else {
                        advertisingService.startAdvertisingService()
                    }
                }
            }
            Section("Browsing") {
                LabeledContent("Browsing for peers", value: discoveryService.discoveryState.isActive ? "Yes" : "No")
                Button(discoveryService.discoveryState.isActive ? "Stop browsing" : "Start browsing") {
                    if discoveryService.discoveryState.isActive {
                        discoveryService.stopDiscoveringPeers()
                    } else {
                        discoveryService.startDiscoveringPeers()
                    }
                }
                ForEach(discoveryService.availablePeers) { peer in
                    peerCellView(peer)
                }
            }
        }
    }

    @ViewBuilder
    private func peerCellView(_ peer: ChatPeer) -> some View {
        NavigationLink {
            ChatView(service: dataTransferService, peer: peer)
        } label: {
            peerInformationService.peerCellView(for: peer)
        }.swipeActions {
            Button {
                inspectedPeer = peer
            } label: {
                Label("Info", systemImage: "person.fill.questionmark")
            }
            .tint(.blue)
            Button {

            } label: {
                Label("Connect", systemImage: "bubble.fill")
            }
            .tint(.green)
        }
        .sheet(item: $inspectedPeer) { peer in
            peerInformationService.peerInformationView(for: peer)
        }
    }

}
