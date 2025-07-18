//
//  Date+Extensions.swift
//  P2PChat
//
//  Created by Henrik Panhans on 03.07.25.
//

import Foundation

extension Date {

    var millisecondsSince1970:Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

}
