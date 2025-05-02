# DynamicSSLPinning

**DynamicSSLPinning** is a Swift package for **dynamic SSL pinning** on iOS.

It enables your app to securely fetch and verify a signed list of trusted certificate fingerprints from your backend, so you can rotate certificates without forcing a manual app update.  
The package uses Combine for reactive updates and is easy to integrate with existing `URLSession` network calls-including sensitive APIs like payment gateways.

---

## Features

- **Dynamic SSL Pinning:** No app update needed for certificate changes-just update your backend’s pin list.
- **Combine Support:** Observe pinning state changes reactively.
- **Easy Integration:** Drop-in replacement for your existing `URLSession` network stack.
- **Secure:** Uses ECDSA signatures for pin list validation.

---

## Installation

Add the package via **Swift Package Manager**:

1. In Xcode, go to **File > Add Packages...**
2. Enter the repository URL:

https://github.com/sreejith-ios/DynamicSSLPinning.git

text

3. Select the latest version and add the package to your project.

---

## Usage

### 1. Initialize the CertStore

import DynamicSSLPinning

let certStore = try CertStore(
serviceUrl: URL(string: "https://your-backend.com/pinning-list.json")!,
verificationKeyBase64: "BASE64_P256_PUBLIC_KEY"
)

text

- `serviceUrl`: The endpoint serving your signed pinning list (see Backend section).
- `verificationKeyBase64`: The base64-encoded ECDSA P-256 public key used to verify the list’s signature.

---

### 2. Create a PinningSessionDelegate

let delegate = PinningSessionDelegate(certStore: certStore)
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

text

---

### 3. Make a Secure Network Request

let request = URLRequest(url: URL(string: "https://your-secure-api.com/payment")!)
session.dataTask(with: request) { data, response, error in
// Handle response or error
}.resume()

text

---

### 4. Observe Pinning State with Combine

import Combine

let cancellable = certStore.$state.sink { state in
switch state {
case .upToDate:
print("Pinning list is up to date.")
case .refreshing:
print("Refreshing pinning list...")
case .error(let error):
print("Pinning error: $$error)")
default:
break
}
}

text

---

## Integrating with Existing URLSession Calls

**To add SSL pinning to your current network layer:**

- Replace your existing `URLSession` initialization with one that uses `PinningSessionDelegate`.
- Pass the same delegate to all your sensitive API calls (e.g., payment transactions, authentication, etc.).
- No changes to your request logic are needed-just use the new session instance.

**Example-Securing Payment Gateway Calls:**

// Existing code (before)
let session = URLSession.shared
session.dataTask(with: paymentRequest) { ... }

// After integrating DynamicSSLPinning
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
session.dataTask(with: paymentRequest) { ... }

text

---

## Backend

- Serve a JSON file containing an array of certificate fingerprints (SHA256 hashes) and a digital signature.
- Sign the list with your ECDSA P-256 private key.
- Example pinning list structure:

{
"fingerprints": [
{ "sha256": "abcdef123456..." },
{ "sha256": "123456abcdef..." }
],
"signature": "BASE64_SIGNATURE"
}

text

- Provide the matching public key to your app.

---

## Example: Full Flow

import DynamicSSLPinning
import Combine

let certStore = try CertStore(
serviceUrl: URL(string: "https://your-backend.com/pinning-list.json")!,
verificationKeyBase64: "BASE64_P256_PUBLIC_KEY"
)
let delegate = PinningSessionDelegate(certStore: certStore)
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

let paymentRequest = URLRequest(url: URL(string: "https://your-secure-api.com/payment")!)
session.dataTask(with: paymentRequest) { data, response, error in
// Handle payment response
}.resume()

let cancellable = certStore.$state.sink { state in
print("CertStore state: $$state)")
}

text

---

## License

MIT

---

This package is ready to be used in your apps and by other developers via Swift Package Manager.  
For questions, contributions, or issues, please open an issue or pull request.

---

**Happy secure coding!**
