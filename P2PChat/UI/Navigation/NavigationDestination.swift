//
//  NavigationDestination.swift
//  P2PChat
//
//  Created by Henrik Panhans on 27.03.25.
//

import P2PKit
import SwiftUI

enum NavigationDestination: Hashable {

    case nameOnboarding
    case servicePicker
    case peerPicker(ServiceType, String)

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .nameOnboarding:
            NameOnboardingView()
        case .servicePicker:
            ServicePickerView()
        case let .peerPicker(serviceType, ownPeerID):
            switch serviceType {
            case .bluetooth:
                PeerPickerView(
                    discoveryService: BluetoothDiscoveryService(service: .bluetoothIdentifier, ownPeerID: ownPeerID),
                    advertisingService: BluetoothAdvertisingService(service: .bluetoothIdentifier, ownPeerID: ownPeerID),
                    informationService: BluetoothInformationService(),
                    serviceType: .bluetooth
                )
            case .bonjour:
                PeerPickerView(
                    discoveryService: BonjourDiscoveryService(service: .bonjourIdentifier, ownPeerID: ownPeerID),
                    advertisingService: BonjourAdvertisingService(service: .bonjourIdentifier, ownPeerID: ownPeerID),
                    informationService: BonjourInformationService(),
                    serviceType: .bonjour
                )
            case .multipeer:
                PeerPickerView(
                    discoveryService: MultipeerDiscoveryService(service: .multipeerIdentifier, ownPeerID: ownPeerID),
                    advertisingService: MultipeerAdvertisingService(service: .multipeerIdentifier, ownPeerID: ownPeerID),
                    informationService: MultipeerInformationService(),
                    serviceType: .multipeer
                )
            }
        }
    }

}
