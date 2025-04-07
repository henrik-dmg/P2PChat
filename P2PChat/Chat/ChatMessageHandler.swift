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

    var chatMessages: [ChatMessage<ChatPeer>] = []
    var currentMessage = ""
    private(set) var isConnected: Bool

    let peerID: ChatPeer.ID
    var ownPeerID: ChatPeer.ID {
        transferService.ownPeerID
    }

    @ObservationIgnored
    let transferService: any PeerDataTransferService<ChatPeer>
    @ObservationIgnored
    let encoder = JSONEncoder()
    @ObservationIgnored
    let decoder = JSONDecoder()

    init(peerID: String, transferService: any PeerDataTransferService<ChatPeer>) {
        self.peerID = peerID
        self.transferService = transferService
        self.isConnected = true  // Let's believe in good faith here
        transferService.delegate = self
    }

    func sendMessage() async throws {
        guard !currentMessage.isEmpty else {
            return
        }
        // TODO: Plugin local peerID here
        let chatMessage = ChatMessage<ChatPeer>(date: .now, content: currentMessage, sender: transferService.ownPeerID, recipient: peerID)
        let chatData = try encoder.encode(chatMessage)
        try await transferService.send(chatData, to: peerID)
        currentMessage = ""
        chatMessages.append(chatMessage)
    }

    func onDisappear() {
        transferService.disconnect(from: peerID)
    }

}

extension ChatMessageHandler: PeerDataTransferServiceDelegate {

    func serviceDidFailToConnectToPeer(with id: String, error: any Error) {
        print("Did fail to connect to peer", id)
    }

    func serviceReceived(data: Data, from peer: String) {
        // TODO: Handle incomming messages here
        do {
            let message = try decoder.decode(ChatMessage<ChatPeer>.self, from: data)
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
