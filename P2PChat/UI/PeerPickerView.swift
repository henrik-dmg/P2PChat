//
//  PeerPickerView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 26.03.25.
//

import SwiftUI
import P2PKit

struct PeerPickerView<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: View {

    @State var discoveryService: any PeerDiscoveryService<ChatPeer>
    @State var advertisingService: any PeerAdvertisingService<ChatPeer>
    let informationService: InformationService

    var body: some View {
        List {
            NavigationLink("Advertise service") {
                PeerAdvertisingView(service: advertisingService)
            }
            NavigationLink("Discover peers") {
                PeerDiscoveryView(service: discoveryService, peerInformationService: informationService)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PeerPickerView(
            discoveryService: BonjourDiscoveryService(service: Constants.serviceIdentifier),
            advertisingService: BonjourAdvertisingService(service: Constants.serviceIdentifier),
            informationService: BonjourInformationService()
        )
    }
}
