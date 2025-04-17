//
//  ChatsListView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 17.04.25.
//

import SwiftUI
import P2PKit

struct ChatsListView<ChatPeer: Peer>: View {

    var peerIDs: [String]
    let service: any PeerDataTransferService<ChatPeer>

    var body: some View {
        NavigationStack {
            List {
                ForEach(peerIDs, id: \.self) { peerID in
                    NavigationLink(peerID) {
                        ChatView(service: service, peerID: peerID)
                    }
                }
            }
            .navigationTitle("^[\(peerIDs.count) Chat](inflect: true)")
        }
        .frame(minHeight: 200)
        .onDisappear {
            service.disconnectAll()
        }
    }

}
