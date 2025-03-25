//
//  ServiceState.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

public enum ServiceState {

    case active
    case inactive
    case error(any Error)

    public var isActive: Bool {
        switch self {
        case .active:
            return true
        default:
            return false
        }
    }

}
