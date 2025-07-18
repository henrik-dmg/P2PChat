//
//  ChatSheetViewModifier.swift
//  P2PChat
//
//  Created by Henrik Panhans on 03.07.25.
//

import P2PKit
import SwiftUI

// MARK: - View Modifier

struct ChatSheetViewModifier<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: ViewModifier {

    @Binding
    var content: ChatSheetContent<ChatPeer>?

    let service: any PeerDataTransferService<ChatPeer>
    let informationService: InformationService

    func body(content: Content) -> some View {
        content
            .sheet(item: $content) { content in
                switch content {
                case let .chat(peerIDs):
                    ChatsListView(peerIDs: peerIDs, service: service)
                case let .inspect(peer):
                    informationService.peerInformationView(for: peer)
                }
            }
            .onChange(of: service.connectedPeers) { _, newValue in
                if newValue.isEmpty {
                    if case .chat = self.content {
                        service.disconnectAll()
                        self.content = nil
                    }
                } else {
                    let now = Date.now
                    for peerID in newValue {
                        PerformanceLogger.shared.track(.connectionReady, date: .now, for: peerID)
                    }
                    self.content = .chat(newValue)
                    if let discoveryService = service as? (any PeerDiscoveryService<ChatPeer>) {
                        discoveryService.stopDiscoveringPeers()
                    }
                }
            }
    }

}

// MARK: - View Extension

extension View {

    func chatSheet<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>(
        _ content: Binding<ChatSheetContent<ChatPeer>?>,
        service: any PeerDataTransferService<ChatPeer>,
        informationService: InformationService
    ) -> some View {
        self.modifier(ChatSheetViewModifier(content: content, service: service, informationService: informationService))
    }

}

// MARK: - SheetContent

enum ChatSheetContent<ChatPeer: Peer>: Identifiable {

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
