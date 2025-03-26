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
    var peer: ChatPeer?
    var isConnected = false

    @ObservationIgnored
    let transferService: any PeerDataTransferService<ChatPeer>
    @ObservationIgnored
    let encoder = JSONEncoder()

    init(peer: ChatPeer, transferService: any PeerDataTransferService<ChatPeer>) {
        self.peer = peer
        self.transferService = transferService
        transferService.delegate = self
    }

    func connect() {
        guard let peer else {
            return
        }
        transferService.connect(to: peer) { [weak self] result in
            switch result {
            case .success:
                self?.isConnected = true
            case let .failure(error):
                self?.isConnected = false
                print(error)
            }
        }
    }

    func disconnect() {
        guard let peer else {
            return
        }
        transferService.disconnect(from: peer)
    }

    func sendMessage() async throws {
        guard !currentMessage.isEmpty else {
            return
        }
        guard let peer else {
            return
        }
        let chatMessage = ChatMessage(id: UUID(), date: .now, content: currentMessage, sender: "me", recipient: peer.id)
        let chatData = try encoder.encode(chatMessage)
        try await transferService.send(chatData, to: peer)
        currentMessage = ""
        chatMessages.append(chatMessage)
    }

}

extension ChatMessageHandler: PeerDataTransferServiceDelegate {

    func serviceDidDisconnectFromPeer(with id: String) {
        isConnected = false
    }

}
