import CoreBluetooth
import Foundation
import Testing

@testable import P2PKit

protocol AdvertisingTests {

    func serviceGetsAdvertised() async throws

}

@Suite("Bonjour Advertising Tests")
struct BonjourAdvertisingTests: AdvertisingTests {

    let service = BonjourService(type: "_p2pchat._tcp")

    @Test
    func serviceGetsAdvertised() async throws {
        let advertiser = BonjourAdvertisingService(ownPeerID: UUID().uuidString, service: service)

        advertiser.startAdvertisingService()
        try await Task.sleep(for: .seconds(2))
        #expect(advertiser.state == .active)

        advertiser.stopAdvertisingService()
        try await Task.sleep(for: .seconds(2))
        #expect(advertiser.state == .inactive)
    }

}

@Suite("Multipeer Advertising Tests")
struct MultipeerAdvertisingTests: AdvertisingTests {

    let service = MultipeerService(type: "p2pchat-test")

    @Test
    func serviceGetsAdvertised() async throws {
        let advertiser = MultipeerAdvertisingService(ownPeerID: UUID().uuidString, service: service)

        advertiser.startAdvertisingService()
        try await Task.sleep(for: .seconds(2))
        #expect(advertiser.state == .active)

        advertiser.stopAdvertisingService()
        try await Task.sleep(for: .seconds(2))
        #expect(advertiser.state == .inactive)
    }

}

@Suite("Bonjour Advertising Tests", .disabled())
struct BluetoothAdvertisingTests: AdvertisingTests {

    let service = BluetoothService(type: CBUUID(), writeCharacteristicUUID: UUID().uuidString, readCharacteristicUUID: UUID().uuidString)

    @Test
    func serviceGetsAdvertised() async throws {
        let advertiser = BluetoothAdvertisingService(ownPeerID: UUID().uuidString, service: service)

        advertiser.startAdvertisingService()
        try await Task.sleep(for: .seconds(2))
        #expect(advertiser.state == .active)

        advertiser.stopAdvertisingService()
        try await Task.sleep(for: .seconds(2))
        #expect(advertiser.state == .inactive)
    }

}
