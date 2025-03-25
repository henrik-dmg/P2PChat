//
//  MultipeerPeer.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import MultipeerConnectivity

public struct MultipeerPeer: Peer {

    public let identifier: MCPeerID
    public let info: [String : String]?

    public var id: String {
        identifier.displayName
    }

}
