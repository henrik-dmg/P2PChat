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

        var id: String {
            switch self {
            case let .inspect(peer):
                peer.id
            case let .chat(peer):
                peer.id
            }
        }
    }

    @State private var sheetContent: SheetContent?

    @State var service: any PeerDiscoveryService<ChatPeer>
    let peerInformationService: InformationService
    @State private var isConnectingToPeer = false

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
            }.disabled(isConnectingToPeer)
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

    @ViewBuilder
    private func peerCellView(_ peer: ChatPeer) -> some View {
        peerInformationService.peerCellView(for: peer).swipeActions {
            Button {
                isConnectingToPeer = true
                service.connect(to: peer) { result in
                    print(result)
                    switch result {
                    case .success:
                        sheetContent = .chat(peer)
                    case let .failure(error):
                        print(error)
                    }
                    isConnectingToPeer = false
                }
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
    }


}
