//
//  ChatMessageHandler.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Foundation
import Logging
import Observation
import P2PKit
import PhotosUI
import SwiftUI

enum ImageState {
    case empty
    case loading(Progress)
    case success(ChatMessageImage)
    case failure(any Error)
}

@Observable
final class ChatMessageHandler<ChatPeer: Peer> {

    // MARK: - Properties

    private(set) var isConnected: Bool
    private(set) var chatMessages: [ChatMessage] = []
    private(set) var imageState: ImageState = .empty

    var currentMessage = ""
    var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }

    var peerGivenName: String?
    let peerID: String
    var ownPeerID: String {
        transferService.ownPeerID
    }

    @ObservationIgnored
    private let transferService: any PeerDataTransferService<ChatPeer>
    @ObservationIgnored
    private let encoder = JSONEncoder()
    @ObservationIgnored
    private let decoder = JSONDecoder()
    @ObservationIgnored
    private let byteCountFormatter = ByteCountFormatter()
    @ObservationIgnored
    private var sendTask: Task<Void, Error>?

    // MARK: - Init

    init(peerID: String, transferService: any PeerDataTransferService<ChatPeer>) {
        self.peerID = peerID
        self.transferService = transferService
        self.isConnected = true  // Let's believe in good faith here
        transferService.delegate = self
    }

    // MARK: - Methods

    func sendMessage() {
        performAsync { [weak self] in
            guard let self else {
                return
            }

            if case .success(let chatMessageImage) = imageState {
                try await sendContent(.image(chatMessageImage))
            }
            if !currentMessage.isEmpty {
                try await sendContent(.text(currentMessage))
            }
        }
    }

    func announceNameToPeer() async throws {
        try await sendContent(.nameAnnouncement(ownPeerID))
    }

    func onDisappear() {
        transferService.disconnect(from: peerID)
    }

    func removeImage() {
        imageState = .empty
    }

    // MARK: - Helpers

    private func performAsync(_ action: @escaping () async throws -> Void) {
        let task = Task {
            try await action()
        }
        let currentTask = self.sendTask
        sendTask = Task {
            _ = try await currentTask?.value
            _ = try await task.value
        }
    }

    private func sendContent(_ content: ChatMessageContent) async throws {
        let chatMessage = ChatMessage(date: .now, sender: transferService.ownPeerID, recipient: peerID, content: content)
        let chatData = try encoder.encode(chatMessage)

        switch content {
        case .nameAnnouncement:
            break
        case .deliveredReceipt:
            break
        case .image:
            imageState = .empty
            chatMessages.append(chatMessage)
            PerformanceLogger.shared.track(.dataDispatched(byteCount: chatData.count), date: .now, for: peerID)
        case .text:
            currentMessage = ""
            chatMessages.append(chatMessage)
            PerformanceLogger.shared.track(.dataDispatched(byteCount: chatData.count), date: .now, for: peerID)
        }

        try await transferService.send(chatData, to: peerID)
    }

    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        imageSelection.loadTransferable(type: ChatMessageImage.self) { result in
            DispatchQueue.main.async { [weak self] in
                guard imageSelection == self?.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                self?.imageSelection = nil
                switch result {
                case .success(let chatMessageImage?):
                    self?.imageState = .success(chatMessageImage)
                case .success(nil):
                    self?.imageState = .empty
                case .failure(let error):
                    self?.imageState = .failure(error)
                }
            }
        }
    }

    private func handleMessageReceived(_ message: ChatMessage, date: Date) {
        Logger.chat.debug(
            "Handling incoming message \(message.id)",
            metadata: [
                "message-type": .string(message.content.typeName),
                "message-received": .stringConvertible(date.millisecondsSince1970)
            ]
        )

        switch message.content {
        case let .nameAnnouncement(name):
            if !name.isEmpty {
                peerGivenName = name
            }
        case let .deliveredReceipt(messageID, date):
            PerformanceLogger.shared.track(.dataReceived, date: date, for: peerID)
            for (index, chatMessage) in chatMessages.enumerated() where chatMessage.id == messageID {
                Logger.chat.trace("Marking message \(messageID) as read")
                chatMessages[index].deliveredDate = date
            }
        case .text, .image:
            performAsync { [weak self] in
                try await self?.sendContent(.deliveredReceipt(message.id, date))
            }
            chatMessages.append(message)
        }
    }

}

extension ChatMessageHandler: PeerDataTransferServiceDelegate {

    func serviceDidFailToConnectToPeer(with id: String, error: any Error) {
        Logger.chat.error("Did fail to connect to peer with id: \(id)")
    }

    func serviceReceived(data: Data, from peer: String) {
        let date = Date.now
        do {
            let message = try decoder.decode(ChatMessage.self, from: data)
            handleMessageReceived(message, date: date)
        } catch {
            Logger.chat.error("Error decoding message: \(error.localizedDescription)")
            Logger.chat.error("\(String(data: data, encoding: .utf8) ?? "No UTF-8 decoding")")
        }
    }

    func serviceDidDisconnectFromPeer(with id: String) {
        isConnected = false
    }

    func serviceDidConnectToPeer(with id: String) {
        isConnected = true
    }

}

extension Data {

    /// Hexadecimal string representation of `Data` object.
    var hexadecimal: String {
        map { String(format: "%02x", $0) }
            .joined()
    }

}
