//
//  P2PChatApp.swift
//  P2PChat
//
//  Created by Henrik Panhans on 02.03.25.
//

import Logging
import SwiftUI

@main
struct P2PChatApp: App {

    init() {

    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }.defaultSize(width: 500, height: 400)
    }

}

struct ContentView: View {

    @State
    private var router = NavigationRouter()
    @State
    private var settings = Settings()

    var body: some View {
        NavigationStack(path: $router.path) {
            router.rootView()
        }
        .environment(settings)
    }

}

#Preview {
    ContentView()
}
