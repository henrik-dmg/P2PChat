//
//  ChatViewPreview.swift
//  P2PChat
//
//  Created by Henrik Panhans on 29.04.25.
//

import P2PKit
import SwiftUI

struct ChatViewPreview: View {

    @State
    private var chatMessageHandler = ChatMessageHandler(
        peerID: "Bob",
        transferService: PreviewDataTransferService(ownPeerID: "Alice", service: PreviewService())
    )

    var body: some View {
        NavigationStack {
            ChatView(chatMessageHandler: chatMessageHandler)
        }
    }

}

struct PreviewPeer: Peer {
    let id: String
}

struct PreviewService: Service {}

@Observable
final class PreviewDataTransferService: PeerDataTransferService {

    typealias P = PreviewPeer
    typealias S = PreviewService

    let ownPeerID: ID
    var connectedPeers: [ID] = []
    let service: S
    var delegate: (any P2PKit.PeerDataTransferServiceDelegate)?

    init(ownPeerID: ID, service: S, delegate: (any P2PKit.PeerDataTransferServiceDelegate)? = nil) {
        self.ownPeerID = ownPeerID
        self.service = service
        self.delegate = delegate
    }

    func connect(to peer: P) {
        connectedPeers.append(peer.id)
    }

    func send(_ data: Data, to peerID: ID) async throws {
        // Do nothing, indicating success
    }

    func disconnect(from peerID: ID) {
        connectedPeers.removeAll { $0 == peerID }
    }

    func disconnectAll() {
        connectedPeers.removeAll()
    }

}
