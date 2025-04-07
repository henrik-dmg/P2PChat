//
//  ChatMessage.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Foundation
import P2PKit

struct ChatMessage<ChatPeer: Peer>: Identifiable, Codable {

    let id: UUID
    let date: Date
    let content: String
    let sender: ChatPeer.ID
    let recipient: ChatPeer.ID

    init(date: Date, content: String, sender: ChatPeer.ID, recipient: ChatPeer.ID) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.sender = sender
        self.recipient = recipient
    }

}

struct PreviewPeer: Peer {

    let id: String

}

typealias PreviewMessage = ChatMessage<PreviewPeer>
