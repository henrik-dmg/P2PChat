//
//  PeerPickerView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 26.03.25.
//

import P2PKit
import SwiftUI

struct PeerPickerView<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: View {

    @State var discoveryService: any PeerDiscoveryService<ChatPeer>
    @State var advertisingService: any PeerAdvertisingService<ChatPeer>
    let informationService: InformationService
    let serviceType: ServiceType

    var body: some View {
        List {
            NavigationLink("Advertise service") {
                PeerAdvertisingView(service: advertisingService, informationService: informationService)
            }
            NavigationLink("Discover peers") {
                PeerDiscoveryView(service: discoveryService, informationService: informationService)
            }
        }.navigationTitle(serviceType.name)
    }
}

#Preview {
    NavigationStack {
        PeerPickerView(
            discoveryService: BonjourDiscoveryService(service: .bonjourIdentifier, ownPeerID: "test2"),
            advertisingService: BonjourAdvertisingService(service: .bonjourIdentifier, ownPeerID: "test2"),
            informationService: BonjourInformationService(),
            serviceType: .bonjour
        )
    }
}
