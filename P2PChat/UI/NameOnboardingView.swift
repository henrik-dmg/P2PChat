//
//  NameOnboardingView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 27.03.25.
//

import SwiftUI

struct NameOnboardingView: View {

    @State private var editingName = ""

    @Environment(Settings.self) private var settings
    @Environment(NavigationRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            TextField("Name", text: $editingName)
        }
        .navigationTitle("Edit Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    guard isNameValid else {
                        return
                    }
                    settings.name = editingName
                    dismiss()
                }.disabled(!isNameValid)
            }
        }
        .interactiveDismissDisabled(!isNameValid)
        .task {
            editingName = settings.name ?? ""
        }
    }

    private var isNameValid: Bool {
        settings.isNameValid(editingName)
    }

}
