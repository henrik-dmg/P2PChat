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
    let peer: ChatPeer
    var isConnected: Bool

    @ObservationIgnored
    let transferService: any PeerDataTransferService<ChatPeer>
    @ObservationIgnored
    let encoder = JSONEncoder()
    @ObservationIgnored
    let decoder = JSONDecoder()

    init(peer: ChatPeer, transferService: any PeerDataTransferService<ChatPeer>) {
        self.peer = peer
        self.transferService = transferService
        self.isConnected = true  // Let's believe in good faith here
        transferService.delegate = self
    }

    func sendMessage() async throws {
        guard !currentMessage.isEmpty else {
            return
        }
        // TODO: Plugin local peerID here
        let chatMessage = ChatMessage(id: UUID(), date: .now, content: currentMessage, sender: "me", recipient: peer.id)
        let chatData = try encoder.encode(chatMessage)
        try await transferService.send(chatData, to: peer.id)
        currentMessage = ""
        chatMessages.append(chatMessage)
    }

    func onDisappear() {
        transferService.disconnect(from: peer.id)
    }

}

extension ChatMessageHandler: PeerDataTransferServiceDelegate {

    func serviceReceived(data: Data, from peer: String) {
        // TODO: Handle incomming messages here
        do {
            let message = try decoder.decode(ChatMessage.self, from: data)
            chatMessages.append(message)
        } catch {
            print("Error decoding message:" + error.localizedDescription)
        }
    }

    func serviceDidDisconnectFromPeer(with id: String) {
        isConnected = false
    }

    func serviceDidConnectToPeer(with id: String) {
        isConnected = true
    }

}
