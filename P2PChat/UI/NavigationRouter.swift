//
//  NavigationRouter.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//


import SwiftUI
import Observation

@Observable
final class NavigationRouter {

    var path = NavigationPath()

    @ViewBuilder
    func rootView() -> some View {
        ServicePickerView() // TODO: More sophisticated onboarding flow
    }

}
