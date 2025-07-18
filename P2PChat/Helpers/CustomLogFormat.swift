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
        let formattedDate = dateFormatter(date, withFormatter: dateFormat)
        var info = swiftLogInfo.filter { !$0.value.isEmpty }
        info["timestamp"] = date.millisecondsSince1970.description
        let actualLabel = info.removeValue(forKey: "label") ?? label

        if isFormattingForConsole {
            // File logging doesn't need timestamp logging
            return "[\(level.emoji) \(level): \(actualLabel)] \(message) \(info)"
        } else {
            return "\(formattedDate) [\(level): \(actualLabel)] \(message) \(info)"
        }
    }
}
