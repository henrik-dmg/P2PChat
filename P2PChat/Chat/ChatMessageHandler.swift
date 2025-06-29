//
//  ChatMessageHandler.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import Foundation
import OSLog
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

    // MARK: - Init

    init(peerID: String, transferService: any PeerDataTransferService<ChatPeer>) {
        self.peerID = peerID
        self.transferService = transferService
        self.isConnected = true  // Let's believe in good faith here
        transferService.delegate = self
    }

    // MARK: - Methods

    func sendMessage() async throws {
        if case .success(let chatMessageImage) = imageState {
            try await sendContent(.image(chatMessageImage))
        }
        if !currentMessage.isEmpty {
            try await sendContent(.text(currentMessage))
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

    private func sendContent(_ content: ChatMessageContent) async throws {
        let chatMessage = ChatMessage(date: .now, sender: transferService.ownPeerID, recipient: peerID, content: content)
        let chatData = try encoder.encode(chatMessage)
        try await transferService.send(chatData, to: peerID)
        currentMessage = ""
        imageState = .empty

        switch content {
        case .nameAnnouncement:
            break
        default:
            chatMessages.append(chatMessage)
        }
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

    private func handleMessageReceived(_ message: ChatMessage) {
        Logger.chat.debug("Handling incoming message \(message.id)")
        switch message.content {
        case let .nameAnnouncement(name):
            if !name.isEmpty {
                peerGivenName = name
            }
        case .file(let name, _):
            let url = URL.documentsDirectory.appendingPathComponent(name)
            print("Received file \(name), saving to \(url.path())")
        default:
            chatMessages.append(message)
        }
    }

}

extension ChatMessageHandler: PeerDataTransferServiceDelegate {

    func serviceDidFailToConnectToPeer(with id: String, error: any Error) {
        print("Did fail to connect to peer", id)
    }

    func serviceReceived(data: Data, from peer: String) {
        do {
            let formattedMessageSize = byteCountFormatter.string(from: .init(value: Double(data.count), unit: .bytes))
            Logger.chat.debug("Received message from \(peer): \(formattedMessageSize)")
            let message = try decoder.decode(ChatMessage.self, from: data)
            handleMessageReceived(message)
        } catch {
            print("Error decoding message:" + error.localizedDescription)
            print(String(data: data, encoding: .utf8) ?? "No UTF-8 decoding")
            print(data.hexadecimal)
        }
    }

    func serviceDidDisconnectFromPeer(with id: String) {
        isConnected = false
    }

    func serviceDidConnectToPeer(with id: String) {
        PerformanceLogger.shared.track(.connectionReady, for: id)
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
