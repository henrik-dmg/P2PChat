//
//  MultipeerPeer.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import MultipeerConnectivity

struct MultipeerPeer: Peer {

    let identifier: MCPeerID
    let info: [String : String]?

    var id: String {
        identifier.displayName
    }

}
