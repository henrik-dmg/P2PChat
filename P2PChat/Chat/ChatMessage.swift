//
//  ChatMessage.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Foundation
import P2PKit

enum ChatMessageContent: Codable {
    case text(String)
    case image(ChatMessageImage)
    case nameAnnouncement(String)
    case file(String, Data)
}

struct ChatMessage: Identifiable, Codable {

    let id: UUID
    let date: Date
    let sender: String
    let recipient: String
    let content: ChatMessageContent

    init(date: Date, sender: String, recipient: String, content: ChatMessageContent) {
        self.id = UUID()
        self.date = date
        self.sender = sender
        self.recipient = recipient
        self.content = content
    }

}
