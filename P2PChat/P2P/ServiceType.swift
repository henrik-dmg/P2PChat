//
//  ServiceType.swift
//  P2PChat
//
//  Created by Henrik Panhans on 23.03.25.
//

import Foundation

enum ServiceType: Hashable, CaseIterable {

    case bluetooth
    case bonjour
    case multipeer

    func discoveryService(_ serviceIdentifier: ServiceIdentifier) -> any PeerDiscoveryService {
        switch self {
        case .bluetooth:
            fatalError()
        case .bonjour:
            return BonjourDiscoveryService(service: serviceIdentifier)
        case .multipeer:
            fatalError()
        }
    }

    func advertisingService(_ serviceIdentifier: ServiceIdentifier) -> any PeerAdvertisingService {
        switch self {
        case .bluetooth:
            fatalError()
        case .bonjour:
            return BonjourAdvertisingService(service: serviceIdentifier)
        case .multipeer:
            fatalError()
        }
    }

}
