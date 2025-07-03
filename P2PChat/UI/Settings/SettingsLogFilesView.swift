//
//  SettingsLogFilesView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 02.07.25.
//

import Puppy
import SwiftUI

struct SettingsLogFilesView: View {

    @State
    private var archivedLogFiles: [URL] = []

    var body: some View {
        List {
            NavigationLink("Current Log") {
                SettingsLogFileView(url: FileRotationLogger.default.fileURL)
            }
            ForEach(archivedLogFiles, id: \.absoluteString) { url in
                NavigationLink(url.lastPathComponent) {
                    SettingsLogFileView(url: url)
                }
            }
        }
        .navigationTitle("Log Files")
        .onAppear {
            // Enumerate urls in directory
            let enumerator = FileManager.default.enumerator(
                at: FileRotationLogger.default.fileURL.deletingLastPathComponent(),
                includingPropertiesForKeys: nil
            )
            guard let enumerator else {
                return
            }

            var collectedURLs = [URL]()
            for element in enumerator {
                guard let url = element as? URL else {
                    continue
                }
                if url.pathExtension == "log" && !url.lastPathComponent.contains("current") {
                    collectedURLs.append(url)
                }
            }
            archivedLogFiles = collectedURLs
        }
    }

}

#Preview {
    SettingsLogFilesView()
}
