//
//  BluetoothChunkSender.swift
//  P2PKit
//
//  Created by Henrik Panhans on 18.04.25.
//

import Foundation

final class BluetoothChunkSender {

    // MARK: - Nested Types

    typealias ChunkWriteHandler = (Data) -> Void

    // MARK: - Properties

    private var pendingChunks: [String: [Data]] = [:]
    private var writeHandlers: [String: ChunkWriteHandler] = [:]
    private let chunkSize: Int

    // MARK: - Init

    init(chunkSize: Int = .defaultBluetoothChunkSize) {
        self.chunkSize = chunkSize
    }

    // MARK: - Methods

    func send(_ data: Data, to peerID: String, chunkWriteHandler: @escaping (Data) -> Void) {
        var chunks = stride(from: data.startIndex, to: data.endIndex, by: chunkSize).map { index in
            let fullChunkEndIndex = index.advanced(by: chunkSize)
            if data.endIndex < fullChunkEndIndex {
                return data.subdata(in: index..<data.endIndex)
            } else {
                return data.subdata(in: index..<fullChunkEndIndex)
            }
        }
        chunks.append(.bluetoothEOM)

        for chunk in chunks {
            chunkWriteHandler(chunk)
        }

        // TODO: Store chunkWriteHandler and only move onto next chunk when value was actually written

        // if pendingChunks[peerID] != nil {
        //     pendingChunks[peerID]?.append(contentsOf: chunks)
        // } else {
        //     pendingChunks[peerID] = chunks
        // }

        // writeHandlers[peerID] = chunkWriteHandler
    }

}
