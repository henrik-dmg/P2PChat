//
//  NameOnboardingView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 27.03.25.
//

import SwiftUI

struct NameOnboardingView: View {

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
                saveAndDismiss()
            }
        }
        .navigationTitle("Edit Name")
        //        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save", action: saveAndDismiss)
                    .disabled(!isNameValid)
            }
        }
        .interactiveDismissDisabled(!isNameValid)
        .task {
            editingName = settings.name
        }
    }

    private func saveAndDismiss() {
        guard isNameValid else {
            return
        }
        settings.name = editingName
        dismiss()
    }

    private var isNameValid: Bool {
        settings.isNameValid(editingName)
    }

}
