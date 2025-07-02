//
//  PerformanceLogger.swift
//  P2PChat
//
//  Created by Henrik Panhans on 08.06.25.
//

import Foundation
import Logging

final class PerformanceLogger {

    // MARK: - Nested Types

    enum EventType: String {
        case connectionInitiated
        case connectionReady
        case dataDispatched
        case dataSent

        var relatedEventType: EventType {
            switch self {
            case .connectionReady:
                return .connectionInitiated
            case .dataDispatched:
                return .dataSent
            default:
                return self
            }
        }
    }

    private struct Event: Identifiable {
        let id = UUID()
        let eventType: EventType
        let timestamp: Date
    }

    // MARK: - Properties

    static let shared = PerformanceLogger()  // In a real application, you should avoid singletons
    private var events: [String: [Event]] = [:]

    // MARK: - Methods

    func track(_ eventType: EventType, for peerID: String) {
        let now = Date.now
        let event = Event(eventType: eventType, timestamp: now)

        if events[peerID] == nil {
            events[peerID] = []
        }

        switch eventType {
        case .connectionReady, .dataSent:
            let relatedEvent = findLatestEvent(of: eventType.relatedEventType, for: peerID) { event in
                event.timestamp < now
            }
            if let relatedEvent {
                logDuration(relatedEvent.timestamp.distance(to: now), for: eventType, peerID: peerID)
            }
        case .connectionInitiated, .dataDispatched:
            break
        }

        events[peerID]?.append(event)
    }

    private func findLatestEvent(of kind: EventType, for peerID: String, filter: (Event) -> Bool) -> Event? {
        guard let eventsForPeer = events[peerID], !eventsForPeer.isEmpty else {
            return nil
        }

        let numberOfEvents = eventsForPeer.count

        for i in 0..<numberOfEvents {
            let event = eventsForPeer[numberOfEvents - i - 1]
            print(event)
            if event.eventType == kind, filter(event) {
                print("Returning event: \(event)")
                return event
            }
        }

        print(eventsForPeer)
        return nil
    }

    private func logDuration(_ duration: TimeInterval, for eventType: EventType, peerID: String) {
        Logger.performance.trace("Duration for \(eventType.rawValue) for \(peerID): \(duration) seconds")
    }

}
