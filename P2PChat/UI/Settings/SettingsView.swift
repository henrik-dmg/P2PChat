//
//  SettingsView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 02.07.25.
//

import SwiftUI

struct SettingsView: View {

    @Environment(Settings.self)
    private var settings

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    SettingsNameEditView()
                } label: {
                    LabeledContent("Name", value: settings.name)
                }
                NavigationLink("Log Files") {
                    SettingsLogFilesView()
                }
            }
            .navigationTitle("Settings")
        }
    }

}

#Preview {
    SettingsView()
}
