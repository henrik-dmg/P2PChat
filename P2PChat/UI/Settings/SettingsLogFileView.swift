//
//  SettingsLogFileView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 02.07.25.
//

import SwiftUI

struct SettingsLogFileView: View {

    let url: URL

    @Environment(Settings.self)
    private var settings
    @State
    private var content = "Content not yet loaded..."

    var body: some View {
        ScrollView {
            Text(content)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
        .navigationTitle(url.lastPathComponent)
        .task {
            guard let data = try? Data(contentsOf: url), let string = String(data: data, encoding: .utf8) else {
                return
            }
            content = string
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: url) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

}
