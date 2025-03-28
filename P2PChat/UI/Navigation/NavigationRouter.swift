//
//  NavigationRouter.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

import SwiftUI
import Observation
import P2PKit

@Observable
final class NavigationRouter {

    var path = NavigationPath()

    @ViewBuilder
    func rootView() -> some View {
        ServicePickerView()
            .environment(self)
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.view()
            }
    }

    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }

}
