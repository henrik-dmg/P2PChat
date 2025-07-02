//
//  Logging.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.04.25.
//

import Foundation
import Logging

extension Logger {

    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "dev.panhans.P2PChat"
    }

    static let chat = Logger(label: subsystem + ".chat")
    static let performance = Logger(label: subsystem + ".performance")

    static func multipeer(_ subCategory: String) -> Logger {
        Logger(label: subsystem + ".multipeer-\(subCategory)")
    }
    static func bluetooth(_ subCategory: String) -> Logger {
        Logger(label: subsystem + ".bluetooth-\(subCategory)")
    }
    static func bonjour(_ subCategory: String) -> Logger {
        Logger(label: subsystem + ".bonjour-\(subCategory)")
    }

}
