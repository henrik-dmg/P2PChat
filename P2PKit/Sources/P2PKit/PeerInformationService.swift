//
//  PeerInformationService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

import Observation
import SwiftUI

public protocol PeerInformationService<ChatPeer> {

    associatedtype ChatPeer: Peer
    associatedtype CellView: View
    associatedtype InformationView: View

    func peerCellView(for peer: ChatPeer) -> CellView
    func peerInformationView(for peer: ChatPeer) -> InformationView

}
