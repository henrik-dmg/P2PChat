//
//  Settings.swift
//  P2PChat
//
//  Created by Henrik Panhans on 27.03.25.
//

import Foundation
import P2PKit
import SwiftUI
import Observation

@Observable
final class Settings {

    var name: String = ""

    func isNameValid(_ name: String?) -> Bool {
        guard let name else {
            return false
        }
        return name.count > 2
    }

}
