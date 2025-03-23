//
//  BonjourInformationService.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import SwiftUI

struct BonjourInformationService: PeerInformationService {

    // MARK: - Nested Types

    typealias ChatPeer = BonjourPeer

    func peerCellView(for peer: ChatPeer) -> some View {
        VStack(alignment: .leading) {
            Text(peer.id)
            Text("Bonjour peer")
        }
    }

    func peerInformationView(for peer: ChatPeer) -> some View {
        NavigationView {
            List {
                LabeledContent("ID", value: peer.id)
                switch peer.endpoint {
                case let .service(name, type, domain, interface):
                    LabeledContent("Name", value: name)
                    LabeledContent("Type", value: type)
                    LabeledContent("Domain", value: domain)
                    if let interface {
                        LabeledContent("Interface", value: interface.name)
                    }
                case .unix, .url, .hostPort, .opaque:
                    Text("Unimplemented endpoint type")
                @unknown default:
                    Text("Unknown endpoint type")
                }
            }
        }
    }

}
