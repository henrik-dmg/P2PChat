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

    @State private var isPresentingAlert = false
    @State private var errorDescription: String?
    @Environment(\.dismiss) private var dismiss

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
                            .font(.subheadline)
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
                        errorDescription = error.localizedDescription
                    }
                } label: {
                    Label("Send", systemImage: "paperplane")
                }.disabled(!chatMessageHandler.isConnected)
            }
            .padding()
            .background(.regularMaterial)
            .alert("Error", isPresented: $isPresentingAlert, presenting: errorDescription) { error in
                AsyncButton {
                    do {
                        try await chatMessageHandler.sendMessage()
                    } catch {
                        print("Sending failed, show error in UI", error)
                        errorDescription = error.localizedDescription
                    }
                } label: {
                    Label("Retry", systemImage: "paperplane")
                }
            } message: { errorDescription in
                Text(errorDescription)
            }
        }
        .onDisappear {
            chatMessageHandler.onDisappear()
        }
    }

}

#Preview {
    ChatView(
        service: BonjourDiscoveryService(service: Constants.serviceIdentifier),
        peer: BonjourPeer.preview()
    )
}
