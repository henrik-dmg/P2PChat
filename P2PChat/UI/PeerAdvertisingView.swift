//
//  PeerAdvertisingView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 26.03.25.
//

import P2PKit
import SwiftUI
import Observation

@Observable
final class PeerAdvertisingViewModel: NSObject, PeerDataTransferServiceDelegate {

    func serviceDidConnectToPeer(with id: String) {

    }
    
    func serviceReceived(data: Data, from peerID: String) {

    }
    
    func serviceDidDisconnectFromPeer(with id: String) {

    }

}

struct PeerAdvertisingView<ChatPeer: Peer>: View {

    @State var service: any PeerAdvertisingService<ChatPeer>
    @State private var peer: ChatPeer?

    var body: some View {
        List {
            Section("Advertise") {
                LabeledContent("Service advertised", value: service.state.isActive ? "Yes" : "No")
                Button(service.state.isActive ? "Stop service" : "Start service") {
                    if service.state.isActive {
                        service.stopAdvertisingService()
                    } else {
                        service.startAdvertisingService { result in
                            switch result {
                            case let .success(peers):
                                self.peer = peers.first
                            case let .failure(error):
                                print(error)
                            }
                        }
                    }
                }.sheet(item: $peer) { peer in
                    NavigationStack {
                        ChatView(service: service, peer: peer)
                    }
                }
            }
        }
    }

}
