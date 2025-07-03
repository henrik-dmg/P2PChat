//
//  URL+Extensions.swift
//  P2PChat
//
//  Created by Henrik Panhans on 03.07.25.
//

import Foundation

extension URL {

    static var logsDirectory: URL {
        get throws {
            let url = URL.documentsDirectory.appendingPathComponent("logs", conformingTo: .folder)
            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            return url
        }
    }

}
