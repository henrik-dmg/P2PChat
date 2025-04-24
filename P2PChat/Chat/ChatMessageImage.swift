//
//  ChatMessageImage.swift
//  P2PChat
//
//  Created by Henrik Panhans on 18.04.25.
//

import CoreTransferable
import Foundation
import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum TransferError: LocalizedError {
    case importFailed
}

struct ChatMessageImage: Transferable, Codable {

    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            ChatMessageImage(data: data)
        }
    }

    @ViewBuilder
    func image(@ViewBuilder configurator: (Image) -> some View) -> some View {
        #if canImport(AppKit)
        if let nsImage = NSImage(data: data) {
            configurator(Image(nsImage: nsImage))
        } else {
            makeFallbackImage()
        }

        #elseif canImport(UIKit)
        if let uiImage = UIImage(data: data) {
            configurator(Image(uiImage: uiImage))
        } else {
            makeFallbackImage()
        }
        #else
        makeFallbackImage()
        #endif
    }

    private func makeFallbackImage() -> some View {
        Image(systemName: "photo.badge.exclamationmark")
            .symbolVariant(.fill)
            .padding()
    }

}
