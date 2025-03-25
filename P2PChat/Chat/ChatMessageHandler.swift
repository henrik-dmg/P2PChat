//
//  ChatMessageHandler.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Foundation
import Observation
import P2PKit

@Observable
final class ChatMessageHandler<ChatPeer: Peer> {

    var chatMessages: [ChatMessage] = []
    var currentMessage = ""

    @ObservationIgnored
    let peer: ChatPeer
    @ObservationIgnored
    let transferService: any PeerDataTransferService<ChatPeer>

    @ObservationIgnored
    let encoder = JSONEncoder()

    init(peer: ChatPeer, transferService: any PeerDataTransferService<ChatPeer>) {
        self.peer = peer
        self.transferService = transferService
    }

    func connect() async throws {
        try await transferService.connect(to: peer)
    }

    func sendMessage() async throws {
        guard !currentMessage.isEmpty else {
            return
        }
        let chatMessage = ChatMessage(id: UUID(), date: .now, content: currentMessage, sender: "me", recipient: peer.id)
        let chatData = try encoder.encode(chatMessage)
        try await transferService.send(chatData, to: peer)
        currentMessage = ""
        chatMessages.append(chatMessage)
    }

}
