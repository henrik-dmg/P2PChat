//
//  P2PChatApp.swift
//  P2PChat
//
//  Created by Henrik Panhans on 02.03.25.
//

import SwiftUI

@main
struct P2PChatApp: App {

    @State private var router = NavigationRouter()
    @State private var settings = Settings()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                router.rootView()
            }
            .environment(settings)
        }
    }

}
