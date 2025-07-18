//
//  ServicePickerView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import P2PKit
import SwiftUI

struct ServicePickerView: View {

    @Environment(NavigationRouter.self)
    var router
    @Environment(Settings.self)
    var settings

    @State
    private var isPresentingSettings = false

    var body: some View {
        List {
            NavigationLink(value: NavigationDestination.peerPicker(.bluetooth)) {
                Label("Bluetooth", systemImage: "personalhotspot")
            }
            NavigationLink(value: NavigationDestination.peerPicker(.bonjour)) {
                Label("Bonjour", systemImage: "bonjour")
            }
            NavigationLink(value: NavigationDestination.peerPicker(.multipeer)) {
                Label("Multipeer", systemImage: "dot.radiowaves.left.and.right")
            }
        }
        .navigationTitle("P2P Services")
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
        }
        .onAppear {
            guard !settings.isNameValid(settings.name) else {
                return
            }
            isPresentingSettings = true
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gear") {
                    isPresentingSettings = true
                }
            }
        }
    }

}

#Preview {
    @Previewable
    @State
    var router = NavigationRouter()
    @Previewable
    @State
    var settings = Settings()

    NavigationStack(path: $router.path) {
        router.rootView()
    }
    .environment(settings)
}
