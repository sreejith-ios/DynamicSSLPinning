//
//  Models.swift
//  DynamicSSLPinning
//
//  Created by Sreejith Rajan on 02/05/25.
//

import Foundation

public struct PinningFingerprint: Codable, Equatable {
    public let sha256: String
}

public struct PinningList: Codable {
    public let fingerprints: [PinningFingerprint]
    public let signature: String
}
