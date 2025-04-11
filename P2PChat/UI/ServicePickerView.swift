//
//  ServicePickerView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import P2PKit
import SwiftUI

struct ServicePickerView: View {

    @Environment(NavigationRouter.self) var router
    @Environment(Settings.self) var settings

    @State private var isPresentingNamePicker = false

    var body: some View {
        List {
            NavigationLink(value: NavigationDestination.peerPicker(.bluetooth)) {
                Label("Bluetooth", systemImage: "personalhotspot")
            }
            NavigationLink(value: NavigationDestination.peerPicker(.bonjour)) {
                Label("Bonjour", systemImage: "bonjour")
            }
            NavigationLink(value: NavigationDestination.peerPicker(.multipeer)) {
                Label("Multipeer", systemImage: "wifi")
            }
        }
        .sheet(isPresented: $isPresentingNamePicker) {
            NavigationStack {
                NameOnboardingView()
            }
        }
        .navigationTitle("P2P Services")
        .onAppear {
            guard !settings.isNameValid(settings.name) else {
                return
            }
            isPresentingNamePicker = true
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Change Name", systemImage: "gear") {
                    isPresentingNamePicker = true
                }
            }
        }
    }

}

#Preview {
    @Previewable @State var router = NavigationRouter()
    @Previewable @State var settings = Settings()

    NavigationStack(path: $router.path) {
        router.rootView()
    }
    .environment(settings)
}
