//
//  ChatView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import SwiftUI
import P2PKit

struct ChatView<ChatPeer: Peer>: View {

    @State private var chatMessageHandler: ChatMessageHandler<ChatPeer>

    init(service: any PeerDataTransferService<ChatPeer>, peer: ChatPeer) {
        self.chatMessageHandler = ChatMessageHandler(peer: peer, transferService: service)
    }

    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack(spacing: 8) {
                    ForEach(chatMessageHandler.chatMessages) { message in
                        Text(message.content)
                    }
                    if chatMessageHandler.chatMessages.isEmpty {
                        Text("No messages yet.")
                    }
                }
            }.defaultScrollAnchor(.bottom)
            HStack(spacing: 12) {
                TextField("Message", text: $chatMessageHandler.currentMessage)
                    .textFieldStyle(.roundedBorder)
                AsyncButton {
                    do {
                        try await chatMessageHandler.sendMessage()
                    } catch {
                        print("Sending failed, show error in UI", error)
                    }
                } label: {
                    Label("Send", systemImage: "paperplane")
                }
            }
            .padding()
            .background(.regularMaterial)
        }.task {
            do {
                try await chatMessageHandler.connect()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}

#Preview {
    ChatView(
        service: BonjourDiscoveryService(service: Constants.serviceIdentifier),
        peer: BonjourPeer.preview()
    )
}
