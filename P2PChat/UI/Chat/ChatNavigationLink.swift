//
//  ChatNavigationLink.swift
//  P2PChat
//
//  Created by Henrik Panhans on 29.04.25.
//

import OSLog
import P2PKit
import SwiftUI

// Wrapper view used to have a NavigationLink that automatically updates the display name of the peer
struct ChatNavigationLink<ChatPeer: Peer>: View {

    @State
    private var chatMessageHandler: ChatMessageHandler<ChatPeer>

    init(service: any PeerDataTransferService<ChatPeer>, peerID: String) {
        self.chatMessageHandler = ChatMessageHandler(peerID: peerID, transferService: service)
    }

    var body: some View {
        NavigationLink(chatMessageHandler.peerGivenName ?? chatMessageHandler.peerID) {
            ChatView(chatMessageHandler: chatMessageHandler)
        }
        .id(chatMessageHandler.peerID)
        .task {
            do {
                try await chatMessageHandler.announceNameToPeer()
            } catch {
                Logger.chat.error("Failed to setup chat: \(error)")
            }
        }
    }

}
