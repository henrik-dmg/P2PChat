//
//  ChatMessage.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//


import Foundation

enum User {}
typealias UserID = Identifier<User, UUID>

struct ChatMessage: Identifiable, Codable {

    let id: UUID
    let date: Date
    let content: String
    let sender: String
    let recipient: String

}
