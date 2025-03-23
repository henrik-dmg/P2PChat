//
//  ChatView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import SwiftUI

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

import Network

//#Preview {
//    ChatView(
//        service: BonjourService(service: BonjourServiceType(type: "_p2p._tcp")),
//        peer: BonjourPeer(id: "test", endpoint: .url(URL(string: "https://example.com")!))
//    )
//}

struct AsyncButton<Label: View>: View {
    var action: () async -> Void
    var actionOptions = Set(ActionOption.allCases)
    @ViewBuilder var label: () -> Label

    @State private var isDisabled = false
    @State private var showProgressView = false

    var body: some View {
        Button(
            action: {
                if actionOptions.contains(.disableButton) {
                    isDisabled = true
                }

                Task {
                    var progressViewTask: Task<Void, Error>?

                    if actionOptions.contains(.showProgressView) {
                        progressViewTask = Task {
                            try await Task.sleep(nanoseconds: 150_000_000)
                            showProgressView = true
                        }
                    }

                    await action()
                    progressViewTask?.cancel()

                    isDisabled = false
                    showProgressView = false
                }
            },
            label: {
                ZStack {
                    label().opacity(showProgressView ? 0 : 1)

                    if showProgressView {
                        ProgressView()
                    }
                }
            }
        )
        .disabled(isDisabled)
    }
}
extension AsyncButton {
    enum ActionOption: CaseIterable {
        case disableButton
        case showProgressView
    }
}
extension AsyncButton where Label == Text {
    init(_ label: String,
         actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
         action: @escaping () async -> Void) {
        self.init(action: action) {
            Text(label)
        }
    }
}

extension AsyncButton where Label == Image {
    init(systemImageName: String,
         actionOptions: Set<ActionOption> = Set(ActionOption.allCases),
         action: @escaping () async -> Void) {
        self.init(action: action) {
            Image(systemName: systemImageName)
        }
    }
}
