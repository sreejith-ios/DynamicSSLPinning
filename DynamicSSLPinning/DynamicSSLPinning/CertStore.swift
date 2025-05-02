//
//  CertStore.swift
//  DynamicSSLPinning
//
//  Created by Sreejith Rajan on 02/05/25.
//

import Foundation
import Combine
import CryptoKit

public enum CertStoreState: Equatable {
    case idle
    case refreshing
    case upToDate
    case error(String)
}

public final class CertStore: ObservableObject {
    @Published public private(set) var state: CertStoreState = .idle
    private let serviceUrl: URL
    private let verificationKey: P256.Signing.PublicKey
    private let refreshInterval: TimeInterval
    private var cancellables = Set<AnyCancellable>()
    private var fingerprints: [String] = []
    private var timer: AnyCancellable?
    
    public init(serviceUrl: URL, verificationKeyBase64: String, refreshInterval: TimeInterval = 3600) throws {
        self.serviceUrl = serviceUrl
        self.refreshInterval = refreshInterval
        guard let keyData = Data(base64Encoded: verificationKeyBase64) else {
            throw NSError(domain: "CertStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid public key"])
        }
        self.verificationKey = try P256.Signing.PublicKey(rawRepresentation: keyData)
        self.scheduleRefresh()
        self.refresh()
    }
    
    private func scheduleRefresh() {
        timer = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }
    
    public func refresh() {
        state = .refreshing
        URLSession.shared.dataTaskPublisher(for: serviceUrl)
            .tryMap { data, _ -> PinningList in
                let list = try JSONDecoder().decode(PinningList.self, from: data)
                // Verify signature
                guard let sigData = Data(base64Encoded: list.signature) else {
                    throw NSError(domain: "CertStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid signature"])
                }
                let fingerprintsData = try JSONEncoder().encode(list.fingerprints)
                let signature = try P256.Signing.ECDSASignature(derRepresentation: sigData)
                guard self.verificationKey.isValidSignature(signature, for: fingerprintsData) else {
                    throw NSError(domain: "CertStore", code: 3, userInfo: [NSLocalizedDescriptionKey: "Signature verification failed"])
                }
                return list
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state = .error(error.localizedDescription)
                }
            }, receiveValue: { [weak self] list in
                self?.fingerprints = list.fingerprints.map { $0.sha256.lowercased() }
                self?.state = .upToDate
            })
            .store(in: &cancellables)
    }
    
    public func validate(serverTrust: SecTrust) -> Bool {
        guard let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else { return false }
        let certData = SecCertificateCopyData(serverCert) as Data
        let sha256 = sha256Hex(data: certData)
        return fingerprints.contains(sha256)
    }
    
    private func sha256Hex(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
