//
//  PeerDiscoveryView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 22.03.25.
//

import SwiftUI
import P2PKit

struct PeerDiscoveryView<ChatPeer: Peer, InformationService: PeerInformationService<ChatPeer>>: View {

    enum SheetContent: Identifiable {
        case inspect(ChatPeer)
        case chat(ChatPeer)

        var id: ChatPeer.ID {
            switch self {
            case let .inspect(peer), let .chat(peer):
                peer.id
            }
        }
    }

    @State var discoveryService: any PeerDiscoveryService<ChatPeer>
    @State var advertisingService: any PeerAdvertisingService<ChatPeer>
    let peerInformationService: InformationService

    @State private var isSetupComplete = false
    @State private var sheetContent: SheetContent?

    var body: some View {
        List {
            Section("Advertise") {
                LabeledContent("Service advertised", value: advertisingService.advertisingState.isActive ? "Yes" : "No")
                Button(advertisingService.advertisingState.isActive ? "Stop service" : "Start service") {
                    if advertisingService.advertisingState.isActive {
                        advertisingService.stopAdvertisingService()
                    } else {
                        advertisingService.startAdvertisingService()
                    }
                }.disabled(!isSetupComplete || discoveryService.discoveryState.isActive)
            }
            Section("Browsing") {
                LabeledContent("Browsing for peers", value: discoveryService.discoveryState.isActive ? "Yes" : "No")
                Button(discoveryService.discoveryState.isActive ? "Stop browsing" : "Start browsing") {
                    if discoveryService.discoveryState.isActive {
                        discoveryService.stopDiscoveringPeers()
                    } else {
                        discoveryService.startDiscoveringPeers()
                    }
                }.disabled(!isSetupComplete || advertisingService.advertisingState.isActive)
                ForEach(discoveryService.availablePeers) { peer in
                    peerCellView(peer)
                }
            }
        }.task {
            do {
                try await advertisingService.configure()
                try await discoveryService.configure()
                isSetupComplete = true
            } catch {
                print(error)
                isSetupComplete = false
            }
        }
    }

    @ViewBuilder
    private func peerCellView(_ peer: ChatPeer) -> some View {
        peerInformationService.peerCellView(for: peer).swipeActions {
            Button {
                sheetContent = .chat(peer)
            } label: {
                Label("Info", systemImage: "bubble.fill")
            }
            .tint(.green)
            Button {
                sheetContent = .inspect(peer)
            } label: {
                Label("Info", systemImage: "person.fill.questionmark")
            }
            .tint(.blue)
        }
        .sheet(item: $sheetContent) { content in
            switch content {
            case let .chat(peer):
                NavigationView {
                    ChatView(service: serviceToForward, peer: peer)
                }
            case let .inspect(peer):
                peerInformationService.peerInformationView(for: peer)
            }
        }
    }

    private var serviceToForward: any PeerDataTransferService<ChatPeer> {
        if advertisingService.advertisingState.isActive {
            return advertisingService
        }
        if discoveryService.discoveryState.isActive, advertisingService.advertisingState.isActive {
            fatalError("Cant be listener and server simultaneously")
        }
        return discoveryService
    }

}
