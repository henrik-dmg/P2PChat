//
//  BonjourPeer.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

import Network

struct BonjourPeer: Peer {

    let endpoint: NWEndpoint

    var id: String {
        endpoint.debugDescription
    }

}
