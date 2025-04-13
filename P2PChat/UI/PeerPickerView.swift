//
//  PeerPickerView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 26.03.25.
//

import P2PKit
import SwiftUI

struct PeerPickerView: View {

    let serviceType: ServiceType

    @Environment(Settings.self)
    private var settings

    var body: some View {
        List {
            NavigationLink("Advertise service", value: NavigationDestination.advertising(serviceType, settings.name))
            NavigationLink("Discover peers", value: NavigationDestination.discovery(serviceType, settings.name))
        }.navigationTitle(serviceType.name)
    }

}

#Preview {
    NavigationStack {
        PeerPickerView(serviceType: .bonjour)
    }
}
