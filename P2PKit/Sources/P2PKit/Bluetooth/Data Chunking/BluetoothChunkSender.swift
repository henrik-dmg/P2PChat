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

    func queue(_ data: Data, to peerID: String, chunkWriteHandler: @escaping (Data) -> Void) {
        var chunks = stride(from: data.startIndex, to: data.endIndex, by: chunkSize).map { index in
            let fullChunkEndIndex = index.advanced(by: chunkSize)
            if data.endIndex < fullChunkEndIndex {
                return data.subdata(in: index..<data.endIndex)
            } else {
                return data.subdata(in: index..<fullChunkEndIndex)
            }
        }
        chunks.append(.bluetoothEOM)

         if pendingChunks[peerID] != nil {
             pendingChunks[peerID]?.append(contentsOf: chunks)
         } else {
             pendingChunks[peerID] = chunks
         }

         writeHandlers[peerID] = chunkWriteHandler
    }

    func sendNextChunk() {
        guard var (peerID, pendingChunks) = pendingChunks.first else {
            // No data cached that is still waiting to be sent
            return
        }

        if pendingChunks.isEmpty {
            self.pendingChunks[peerID] = nil
            self.writeHandlers[peerID] = nil
        }

        guard let writeHandler = writeHandlers[peerID] else {
            return
        }

        let chunkToSend = pendingChunks.removeFirst()
        self.pendingChunks[peerID] = pendingChunks
        writeHandler(chunkToSend)
    }

}
