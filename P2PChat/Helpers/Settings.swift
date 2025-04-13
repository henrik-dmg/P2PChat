//
//  Settings.swift
//  P2PChat
//
//  Created by Henrik Panhans on 27.03.25.
//

import Foundation
import Observation
import P2PKit
import SwiftUI

@Observable
final class Settings {

    #if canImport(UIKit)
    var name: String = UIDevice.current.name
    #else
    var name: String = Host.current().localizedName ?? "Unknown Device"
    #endif

    func isNameValid(_ name: String?) -> Bool {
        guard let name else {
            return false
        }
        return name.count > 2
    }

}
