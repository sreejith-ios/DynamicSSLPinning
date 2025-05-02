//
//  PinningSessionDelegate.swift
//  DynamicSSLPinning
//
//  Created by Sreejith Rajan on 02/05/25.
//

import Foundation

public final class PinningSessionDelegate: NSObject, URLSessionDelegate {
    private let certStore: CertStore
    
    public init(certStore: CertStore) {
        self.certStore = certStore
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        if certStore.validate(serverTrust: serverTrust) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
