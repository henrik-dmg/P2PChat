//
//  ChatMessageCellView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.04.25.
//

import SwiftUI

struct ChatMessageCellView: View {

    let message: ChatMessage
    let ownPeerID: String
    let peerGivenName: String?

    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer()
                bubbleView
            } else {
                bubbleView
                Spacer()
            }
        }
    }

    private var bubbleView: some View {
        VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
            bubbleContent
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(bubbleColor)
                }
            Text(isOwnMessage ? ownPeerID : peerGivenName ?? message.sender)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.content {
        case let .text(string):
            Text(string)
                .font(.body)
                .foregroundStyle(textColor)
                .padding(8)
        case .nameAnnouncement:
            Text("This should not be displayed")
        case let .image(chatMessageImage):
            chatMessageImage.image { image in
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100)
            }
        }
    }

    private var isOwnMessage: Bool {
        message.sender == ownPeerID
    }

    private var textColor: Color {
        isOwnMessage ? .black : .white
    }

    private var bubbleColor: Color {
        isOwnMessage ? Color(white: 0.9) : .blue
    }

}

#Preview("Chat") {
    ChatViewPreview()
}
