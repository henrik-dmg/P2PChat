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
    case peerPicker(ServiceType)
    case advertising(ServiceType, String)
    case discovery(ServiceType, String)

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .nameOnboarding:
            NameOnboardingView()
        case .servicePicker:
            ServicePickerView()
        case let .peerPicker(serviceType):
            PeerPickerView(serviceType: serviceType)
        case let .advertising(serviceType, ownPeerID):
            switch serviceType {
            case .bluetooth:
                #if os(visionOS)
                Text("Advertising via Bluetooth is not supported on visionOS.")
                #else
                PeerAdvertisingView(
                    service: BluetoothAdvertisingService(ownPeerID: ownPeerID, service: .bluetooth),
                    informationService: BluetoothInformationService()
                )
                #endif
            case .bonjour:
                PeerAdvertisingView(
                    service: BonjourAdvertisingService(ownPeerID: ownPeerID, service: .bonjour),
                    informationService: BonjourInformationService()
                )
            case .multipeer:
                PeerAdvertisingView(
                    service: MultipeerAdvertisingService(ownPeerID: ownPeerID, service: .multipeer),
                    informationService: MultipeerInformationService()
                )
            }
        case let .discovery(serviceType, ownPeerID):
            switch serviceType {
            case .bluetooth:
                PeerDiscoveryView(
                    service: BluetoothDiscoveryService(ownPeerID: ownPeerID, service: .bluetooth),
                    informationService: BluetoothInformationService()
                )
            case .bonjour:
                PeerDiscoveryView(
                    service: BonjourDiscoveryService(ownPeerID: ownPeerID, service: .bonjour),
                    informationService: BonjourInformationService()
                )
            case .multipeer:
                PeerDiscoveryView(
                    service: MultipeerDiscoveryService(ownPeerID: ownPeerID, service: .multipeer),
                    informationService: MultipeerInformationService()
                )
            }
        }
    }

}
