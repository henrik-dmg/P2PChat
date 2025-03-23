//
//  ServiceState.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

enum ServiceState {

    case active
    case inactive
    case error(any Error)

    var isActive: Bool {
        switch self {
        case .active:
            return true
        default:
            return false
        }
    }

}
