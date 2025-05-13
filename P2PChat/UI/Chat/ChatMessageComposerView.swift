//
//  ChatMessageComposerView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.04.25.
//

import Observation
import P2PKit
import PhotosUI
import SwiftUI

struct ChatMessageComposerView<ChatPeer: Peer>: View {

    @Bindable
    var chatMessageHandler: ChatMessageHandler<ChatPeer>

    @State
    private var isPresentingAlert = false
    @State
    private var errorDescription: String?
    @State
    private var sendTask: Task<Void, Error>?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if case .success(let chatMessageImage) = chatMessageHandler.imageState {
                imageThumbnail(chatMessageImage)
            }
            HStack(spacing: 12) {
                TextField("Message", text: $chatMessageHandler.currentMessage)
                    .onSubmit {
                        send()
                    }
                    .textFieldStyle(.roundedBorder)
                imagePicker()
                sendButton(title: "Send")
                    .disabled(!isSendButtonEnabled)
            }
        }
        .padding()
        .background(.regularMaterial)
        .alert("Error", isPresented: $isPresentingAlert, presenting: errorDescription) { error in
            sendButton(title: "Retry")
        } message: { errorDescription in
            Text(errorDescription)
        }
    }

    private func imagePicker() -> some View {
        PhotosPicker(
            selection: $chatMessageHandler.imageSelection,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label("Image", systemImage: "photo")
                .symbolVariant(.fill)
                .labelStyle(.iconOnly)
        }
    }

    private func sendButton(title: LocalizedStringKey) -> some View {
        Button {
            send()
        } label: {
            Label(title, systemImage: "paperplane")
                .symbolVariant(.fill)
                .labelStyle(.iconOnly)
        }
    }

    private func send() {
        let task = Task {
            try await chatMessageHandler.sendMessage()
        }
        let currentTask = self.sendTask
        sendTask = Task {
            _ = try await currentTask?.value
            _ = try await task.value
        }
    }

    private var isSendButtonEnabled: Bool {
        let hasMessage = !chatMessageHandler.currentMessage.isEmpty
        let hasImage =
            switch chatMessageHandler.imageState {
            case .success:
                true
            default:
                false
            }

        return hasMessage || hasImage
    }

    private func imageThumbnail(_ chatMessageImage: ChatMessageImage) -> some View {
        chatMessageImage.image { image in
            ZStack(alignment: .topLeading) {
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    }
                    .draggable(chatMessageImage) {
                        image
                    }
                Button("Remove image", systemImage: "xmark.circle") {
                    chatMessageHandler.removeImage()
                }
                .symbolVariant(.fill)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .gray)
                .labelStyle(.iconOnly)
            }
        }
    }

}

#Preview("Chat") {
    ChatViewPreview()
}
