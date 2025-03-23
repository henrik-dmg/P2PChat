//
//  MultipeerInformationService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import SwiftUI

struct MultipeerInformationService: PeerInformationService {

    // MARK: - Nested Types

    typealias ChatPeer = MultipeerPeer

    func peerCellView(for peer: ChatPeer) -> some View {
        VStack(alignment: .leading) {
            Text(peer.id)
            Text("Multipeer peer")
        }
    }

    func peerInformationView(for peer: ChatPeer) -> some View {
        NavigationView {
            List {
                LabeledContent("ID", value: peer.id)
            }
        }
    }

}
