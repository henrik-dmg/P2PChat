//
//  Settings.swift
//  P2PChat
//
//  Created by Henrik Panhans on 27.03.25.
//

import Foundation
import Observation
import P2PKit
import Puppy
import SwiftUI

@Observable
final class Settings {

    // This weird workaround is necessary because @AppStorage is not compatible with @Observable as of July 3rd, 2025
    var name: String {
        get {
            access(keyPath: \.name)
            #if canImport(UIKit)
            return UserDefaults.standard.string(forKey: "name") ?? UIDevice.current.name
            #else
            return UserDefaults.standard.string(forKey: "name") ?? Host.current().localizedName ?? "Unknown Device"
            #endif
        }
        set {
            withMutation(keyPath: \.name) {
                UserDefaults.standard.setValue(newValue, forKey: "name")
            }
        }
    }

    func isNameValid(_ name: String?) -> Bool {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return name.count > 2
    }

}
