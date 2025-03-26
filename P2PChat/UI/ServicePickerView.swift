//
//  ServicePickerView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import SwiftUI
import P2PKit

enum Constants {
    static let serviceIdentifier = ServiceIdentifier("_p2p._tcp")
}

struct ServicePickerView: View {

    var body: some View {
        NavigationStack {
            List {
                NavigationLink(value: ServiceType.bluetooth) {
                    Label("Bluetooth", systemImage: "personalhotspot")
                }
                NavigationLink(value: ServiceType.bonjour) {
                    Label("Bonjour", systemImage: "bonjour")
                }
                NavigationLink(value: ServiceType.multipeer) {
                    Label("Multipeer", systemImage: "wifi")
                }
            }
            .navigationTitle("P2P Services")
            .navigationDestination(for: ServiceType.self) { service in
                makeServiceDestinationView(service)
            }
        }
    }

    @ViewBuilder
    private func makeServiceDestinationView(_ service: ServiceType) -> some View {
        switch service {
        case .bluetooth:
            Text("Bluetooth not supported yet")
        case .bonjour:
            PeerPickerView(
                discoveryService: BonjourDiscoveryService(service: Constants.serviceIdentifier),
                advertisingService: BonjourAdvertisingService(service: Constants.serviceIdentifier),
                informationService: BonjourInformationService()
            )
        case .multipeer:
            PeerPickerView(
                discoveryService: MultipeerDiscoveryService(service: Constants.serviceIdentifier),
                advertisingService: MultipeerAdvertisingService(service: Constants.serviceIdentifier),
                informationService: MultipeerInformationService()
            )
        }
    }

}
