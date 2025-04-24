//
//  Logging.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.04.25.
//

import OSLog

extension Logger {

    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "com.example.P2PChat"
    }

    static let chat = Logger(subsystem: subsystem, category: "chat")

    static func multipeer(_ subCategory: String) -> Logger {
        Logger(subsystem: subsystem, category: "multipeer-\(subCategory)")
    }
    static func bluetooth(_ subCategory: String) -> Logger {
        Logger(subsystem: subsystem, category: "bluetooth-\(subCategory)")
    }
    static func bonjour(_ subCategory: String) -> Logger {
        Logger(subsystem: subsystem, category: "bonjour-\(subCategory)")
    }

}
