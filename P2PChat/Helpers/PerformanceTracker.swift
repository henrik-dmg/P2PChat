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

    enum EventType: CustomStringConvertible, Sendable, Equatable {
        case connectionInitiated
        case connectionReady
        case dataDispatched(byteCount: Int)
        case dataReceived

        var description: String {
            switch self {
            case .connectionInitiated:
                "connection-initiated"
            case .connectionReady:
                "connection-ready"
            case let .dataDispatched(byteCount):
                "data-dispatched(\(byteCount))"
            case .dataReceived:
                "data-received"
            }
        }

        var order: Int {
            switch self {
            case .connectionInitiated:
                return 0
            case .connectionReady:
                return 1
            case .dataDispatched:
                return 2
            case .dataReceived:
                return 3
            }
        }
    }

    private struct Event: Identifiable {
        let id = UUID()
        let timestamp: Date
        let eventType: EventType
    }

    // MARK: - Properties

    static let shared = PerformanceLogger()  // In a real application, you should avoid singletons
    private var events: [Event] = []
    private var isServerReachable = false

    // MARK: - Init

    init() {
        checkIfServerIsReachable()
    }

    // MARK: - Methods

    func track(_ eventType: EventType, date: Date, for peerID: String) {
        let event = Event(timestamp: date, eventType: eventType)

        Logger.performance.trace("Tracking event \(eventType) for peer \(peerID)...")

        if let lastEvent = events.last, lastEvent.eventType.order != event.eventType.order - 1 {
            Logger.performance.warning(
                "Invalid order of events, flushing events...",
                metadata: [
                    "event-type": .stringConvertible(eventType),
                    "last-event-type": .stringConvertible(lastEvent.eventType),
                ]
            )
            events.removeAll()
            return
        }

        events.append(event)

        guard events.count == 4 else {
            return
        }

        Logger.performance.debug("Got 4 events, sending measurement to ingress server...")

        let connectionInitiatedEvent = events[0]
        let connectionReadyEvent = events[1]
        let dataDispatchedEvent = events[2]
        let dataReceivedEvent = events[3]

        events.removeAll()

        guard
            connectionInitiatedEvent.eventType == .connectionInitiated,
            connectionReadyEvent.eventType == .connectionReady,
            case let .dataDispatched(byteCount) = dataDispatchedEvent.eventType,
            dataReceivedEvent.eventType == .dataReceived
        else {
            Logger.performance.error("Invalid order of events, skipping measurement...")
            return
        }

        guard isServerReachable else {
            Logger.performance.error("Ingress server not reachable, skipping measurement...")
            return
        }

        let requestBody = PerformanceMeasurementRequest(
            connectionInitiatedTimestamp: connectionInitiatedEvent.timestamp.millisecondsSince1970,
            connectionReadyTimestamp: connectionReadyEvent.timestamp.millisecondsSince1970,
            dataDispatchedTimestamp: dataDispatchedEvent.timestamp.millisecondsSince1970,
            dataReceivedTimestamp: dataReceivedEvent.timestamp.millisecondsSince1970,
            bytesReceived: byteCount
        )

        let bodyData = try? JSONEncoder().encode(requestBody)

        if let bodyData {
            print(String(data: bodyData, encoding: .utf8) ?? "(unprintable)")
        }

        let url = URL(string: "https://barely-rational-jaybird.ngrok-free.app/api/ingress")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = bodyData

        guard request.httpBody != nil else {
            Logger.performance.error("Failed to encode request body")
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                Logger.performance.info("Sent measurement to ingress server: \(String(data: data, encoding: .utf8) ?? "(unprintable)")")
            } catch {
                Logger.performance.error("Failed sending performance report: \(error)")
            }
        }
    }

    private func checkIfServerIsReachable() {
        let url = URL(string: "https://barely-rational-jaybird.ngrok-free.app/api/health-check")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

        Task { [weak self] in
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    Logger.performance.trace("Ingress server responded: \(String(data: data, encoding: .utf8) ?? "no UTF-8 string")")
                    self?.isServerReachable = true
                } else {
                    Logger.performance.error("Ingress server is unreachable")
                }
            } catch {
                Logger.performance.error("Failed sending performance report: \(error)")
            }
        }
    }

}

// MARK: - Request Body

struct PerformanceMeasurementRequest: Encodable {

    let connectionInitiatedTimestamp: Int64
    let connectionReadyTimestamp: Int64
    let dataDispatchedTimestamp: Int64
    let dataReceivedTimestamp: Int64
    let bytesReceived: Int

}
