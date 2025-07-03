//
//  P2PChatApp.swift
//  P2PChat
//
//  Created by Henrik Panhans on 02.03.25.
//

import Logging
import Puppy
import SwiftUI

// MARK: - App

@main
struct P2PChatApp: App {

    init() {
        LoggingSystem.bootstrapWithPuppy()
        Logger.app.notice("App initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }.defaultSize(width: 500, height: 400)
    }

}

// MARK: - RootView

struct ContentView: View {

    @State
    private var router = NavigationRouter()
    @State
    private var settings = Settings()

    @Environment(\.scenePhase)
    private var scenePhase

    var body: some View {
        NavigationStack(path: $router.path) {
            router.rootView()
        }
        .environment(settings)
        .onChange(of: scenePhase) { oldValue, newValue in
            Logger.app.debug(
                "Scene phase changed from \(oldValue) -> \(newValue)",
                metadata: ["previous": .string("\(oldValue)"), "current": .string("\(newValue)")]
            )
        }
    }

}

// MARK: - Preview

#Preview {
    ContentView()
}
