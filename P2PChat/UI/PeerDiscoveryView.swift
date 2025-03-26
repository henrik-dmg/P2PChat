//
//  PeerDiscoveryView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

import SwiftUI
import P2PKit
import Observation

struct PeerDiscoveryView<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: View {

    enum SheetContent: Identifiable {
        case inspect(ChatPeer)
        case chat(ChatPeer)

        var id: ChatPeer.ID {
            switch self {
            case let .inspect(peer), let .chat(peer):
                peer.id
            }
        }
    }

    @State private var sheetContent: SheetContent?

    @State var service: any PeerDiscoveryService<ChatPeer>
    let peerInformationService: InformationService

    var body: some View {
        List {
            Section("Discovery") {
                LabeledContent("Discovery peers", value: service.state.isActive ? "Yes" : "No")
                Button(service.state.isActive ? "Stop discovering" : "Start discovering") {
                    if service.state.isActive {
                        service.stopDiscoveringPeers()
                    } else {
                        service.startDiscoveringPeers()
                    }
                }
                ForEach(service.availablePeers) { peer in
                    peerCellView(peer)
                }
            }
        }
    }

    @ViewBuilder
    private func peerCellView(_ peer: ChatPeer) -> some View {
        peerInformationService.peerCellView(for: peer).swipeActions {
            Button {
                sheetContent = .chat(peer)
            } label: {
                Label("Info", systemImage: "bubble.fill")
            }
            .tint(.green)
            Button {
                sheetContent = .inspect(peer)
            } label: {
                Label("Info", systemImage: "person.fill.questionmark")
            }
            .tint(.blue)
        }
        .sheet(item: $sheetContent) { content in
            switch content {
            case let .chat(peer):
                NavigationView {
                    ChatView(service: service, peer: peer)
                }
            case let .inspect(peer):
                peerInformationService.peerInformationView(for: peer)
            }
        }
    }


}
