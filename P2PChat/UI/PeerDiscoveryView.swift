//
//  PeerDiscoveryView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

import Observation
import P2PKit
import SwiftUI

enum SheetContent<ChatPeer: Peer>: Identifiable {

    case inspect(ChatPeer)
    case chat([ChatPeer.ID])

    var id: String {
        switch self {
        case let .inspect(peer):
            peer.id
        case let .chat(peerIDs):
            peerIDs.joined(separator: "~")
        }
    }

}

struct PeerDiscoveryView<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: View {

    @State
    var service: any PeerDiscoveryService<ChatPeer>
    let informationService: InformationService

    @State
    private var sheetContent: SheetContent<ChatPeer>?

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
            ForEach(service.availablePeers) { peer in
#if os(iOS)
                swipeActionPeerCellView(peer)
#else
                buttonActionPeerCellView(peer)
#endif
            }
        }
        .navigationTitle("Discovery")
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
                service.stopDiscoveringPeers()
                self.sheetContent = .chat(newValue)
            }
        }
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
            service.connect(to: peer)
        } label: {
            Label("Connect", systemImage: "bubble.fill")
        }
        .tint(.green)
        Button {
            sheetContent = .inspect(peer)
        } label: {
            Label("Info", systemImage: "person.fill.questionmark")
        }
        .tint(.blue)
    }

}
