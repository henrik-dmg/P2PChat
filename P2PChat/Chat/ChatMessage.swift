//
//  ChatMessage.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Foundation
import P2PKit

struct ChatMessage: Identifiable, Codable {

    let id: UUID
    let date: Date
    let content: String
    let sender: String
    let recipient: String

    init(date: Date, content: String, sender: String, recipient: String) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.sender = sender
        self.recipient = recipient
    }

}
