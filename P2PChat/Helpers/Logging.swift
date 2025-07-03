//
//  Logging.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.04.25.
//

import Foundation
import Logging
import Puppy

// MARK: - Loggers

extension Logger {

    static let app = Logger(label: "app")
    static let chat = Logger(label: "chat")
    static let performance = Logger(label: "performance")

    static func multipeer(_ subCategory: String) -> Logger {
        Logger(label: "multipeer-\(subCategory)")
    }
    static func bluetooth(_ subCategory: String) -> Logger {
        Logger(label: "bluetooth-\(subCategory)")
    }
    static func bonjour(_ subCategory: String) -> Logger {
        Logger(label: "bonjour-\(subCategory)")
    }

}

// MARK: - Puppy Destinations

extension OSLogger {

    static let `default` = OSLogger("dev.panhans.p2pchat.console", logFormat: CustomLogFormat(isFormattingForConsole: true))

}

extension FileRotationLogger {

    static let `default`: FileRotationLogger = {
        let fileURL = try! URL.logsDirectory
        let rotationConfig = RotationConfig(
            suffixExtension: .numbering,
            maxFileSize: 10 * 1024 * 1024,
            maxArchivedFilesCount: 5
        )
        return try! FileRotationLogger(
            "dev.panhans.p2pchat.filerotation",
            logLevel: .debug,
            logFormat: CustomLogFormat(isFormattingForConsole: true),
            fileURL: fileURL.appendingPathComponent("current.log", conformingTo: .log),
            rotationConfig: rotationConfig,
            delegate: nil
        )
    }()

}

// MARK: - Bootstrapping

extension LoggingSystem {

    static func bootstrapWithPuppy() {
        let puppy = Puppy(loggers: [OSLogger.default, FileRotationLogger.default])

        bootstrap { loggerLabel in
            var handler = PuppyLogHandler(label: loggerLabel, puppy: puppy)
            // Set the logging level.
            handler.logLevel = .trace
            return handler
        }
    }

}
