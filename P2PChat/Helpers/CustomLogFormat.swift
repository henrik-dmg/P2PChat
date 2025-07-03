//
//  CustomLogFormat.swift
//  P2PChat
//
//  Created by Henrik Panhans on 03.07.25.
//

import Foundation
import Puppy

struct CustomLogFormat: LogFormattable {

    private let isFormattingForConsole: Bool
    private let dateFormat = DateFormatter()

    init(isFormattingForConsole: Bool) {
        self.isFormattingForConsole = isFormattingForConsole
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    }

    func formatMessage(
        _ level: LogLevel,
        message: String,
        tag: String,
        function: String,
        file: String,
        line: UInt,
        swiftLogInfo: [String: String],
        label: String,
        date: Date,
        threadID: UInt64
    ) -> String {
        let date = dateFormatter(date, withFormatter: dateFormat)
        var info = swiftLogInfo

        let actualLabel = info.removeValue(forKey: "label") ?? label
        let baseMessage = "[\(level): \(actualLabel)] \(message)"

        if isFormattingForConsole {
            return baseMessage
        } else {
            return "\(date) \(baseMessage) \(info)"
        }
    }
}
