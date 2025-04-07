//
//  Logging.swift
//  P2PKit
//
//  Created by Henrik Panhans on 07.04.25.
//

import OSLog

extension Logger {

    private static var subsystem: String {
        "dev.panhans.P2PKit"
    }

    static let multipeer = Logger(subsystem: subsystem, category: "multipeer")
    static let bluetooth = Logger(subsystem: subsystem, category: "bluetooth")
    static let bonjour = Logger(subsystem: subsystem, category: "bonjour")

}
