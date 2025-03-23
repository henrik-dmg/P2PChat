//
//  MultipeerDataTransferService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation
import Observation
import Network

@Observable
final class MultipeerDataTransferService: PeerDataTransferService {
    func connect(to peer: MultipeerPeer) async throws {
        
    }
    
    func send(_ data: Data, to peer: MultipeerPeer) async throws {

    }
    
    func disconnect(from peer: MultipeerPeer) {

    }
    

    // MARK: - Nested Types

    typealias ChatPeer = MultipeerPeer

}
