//
//  ChatsListView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 17.04.25.
//

import Logging
import P2PKit
import SwiftUI

struct ChatsListView<ChatPeer: Peer>: View {

    let peerIDs: [String]
    let service: any PeerDataTransferService<ChatPeer>

    var body: some View {
        NavigationStack {
            List(peerIDs, id: \.self) { peerID in
                ChatNavigationLink(service: service, peerID: peerID)
            }
            .navigationTitle("^[\(peerIDs.count) Chat](inflect: true)")
        }
        .frame(minHeight: 300)
        .onDisappear {
            Logger.app.debug("Disconnecting all peers due to chat list disappearing")
            service.disconnectAll()
        }
    }

}
