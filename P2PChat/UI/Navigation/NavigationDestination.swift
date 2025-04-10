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
                    discoveryService: BluetoothDiscoveryService(ownPeerID: ownPeerID, service: .bluetooth),
                    advertisingService: BluetoothAdvertisingService(ownPeerID: ownPeerID, service: .bluetooth),
                    informationService: BluetoothInformationService(),
                    serviceType: .bluetooth
                )
            case .bonjour:
                PeerPickerView(
                    discoveryService: BonjourDiscoveryService(ownPeerID: ownPeerID, service: .bonjour),
                    advertisingService: BonjourAdvertisingService(ownPeerID: ownPeerID, service: .bonjour),
                    informationService: BonjourInformationService(),
                    serviceType: .bonjour
                )
            case .multipeer:
                PeerPickerView(
                    discoveryService: MultipeerDiscoveryService(ownPeerID: ownPeerID, service: .multipeer),
                    advertisingService: MultipeerAdvertisingService(ownPeerID: ownPeerID, service: .multipeer),
                    informationService: MultipeerInformationService(),
                    serviceType: .multipeer
                )
            }
        }
    }

}
