//
//  SettingsNameEditView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 27.03.25.
//

import Logging
import SwiftUI

struct SettingsNameEditView: View {

    @State
    private var editingName = ""

    @Environment(Settings.self)
    private var settings
    @Environment(NavigationRouter.self)
    private var router
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        List {
            Text("Please enter a name for your chat session. This name will be shown to other users.")
            TextField("Name", text: $editingName) {
                updateNameIfValid()
            }
        }
        .navigationTitle("Edit Name")
        .task {
            editingName = settings.name
        }
        .onDisappear {
            updateNameIfValid()
        }
    }

    private func updateNameIfValid() {
        if isNameValid && settings.name != editingName {
            settings.name = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
            Logger.app.notice("Name changed to \(editingName)")
        }
    }

    private var isNameValid: Bool {
        settings.isNameValid(editingName)
    }

}
