//
//  PeerDiscoveryView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

import Observation
import P2PKit
import SwiftUI

struct PeerDiscoveryView<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: View {

    @State
    var service: any PeerDiscoveryService<ChatPeer>
    let informationService: InformationService

    @State
    private var sheetContent: ChatSheetContent<ChatPeer>?

    var body: some View {
        List {
            LabeledContent("Discovering peers") {
                Text(service.state.isActive ? "Yes" : "No")
                    .foregroundStyle(service.state.isActive ? .green : .red)
            }
            Button(service.state.isActive ? "Stop discovering" : "Start discovering") {
                if service.state.isActive {
                    service.stopDiscoveringPeers()
                } else {
                    service.startDiscoveringPeers()
                }
            }
            .sensoryFeedback(service.state.isActive ? .start : .stop, trigger: service.state)
            ForEach(service.availablePeers) { peer in
                #if os(iOS)
                swipeActionPeerCellView(peer)
                #else
                buttonActionPeerCellView(peer)
                #endif
            }
        }
        .navigationTitle("Discovery")
        .chatSheet($sheetContent, service: service, informationService: informationService)
    }

    private func swipeActionPeerCellView(_ peer: ChatPeer) -> some View {
        informationService.peerCellView(for: peer).swipeActions {
            peerCellViewButtons(peer)
        }
    }

    private func buttonActionPeerCellView(_ peer: ChatPeer) -> some View {
        HStack {
            informationService.peerCellView(for: peer)
            Spacer()
            peerCellViewButtons(peer)
        }
    }

    @ViewBuilder
    private func peerCellViewButtons(_ peer: ChatPeer) -> some View {
        Button {
            PerformanceLogger.shared.track(.connectionInitiated, date: .now, for: peer.id)
            service.connect(to: peer)
        } label: {
            Label("Connect", systemImage: "bubble.fill")
        }
        .tint(.green)
        .disabled(peer.id == service.ownPeerID)
        Button {
            sheetContent = .inspect(peer)
        } label: {
            Label("Info", systemImage: "person.fill.questionmark")
        }
        .tint(.blue)
    }

}
