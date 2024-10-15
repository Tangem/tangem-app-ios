# XRPKit

<div align="left">
    <img src="logo.png" width="250px"</img> 
</div>

[![Version](https://img.shields.io/cocoapods/v/XRPKit.svg?style=flat&label=version)](https://cocoapods.org/pods/XRPKit)
[![License](https://img.shields.io/cocoapods/l/XRPKit.svg?style=flat)](https://cocoapods.org/pods/XRPKit)
![badge-platforms][]
![badge-pms][]

XRPKit is a Swift SDK built for interacting with the XRP Ledger.  XRPKit supports offline wallet creation, offline transaction creation/signing, and submitting transactions to the XRP ledger.  XRPKit supports both the secp256k1 and ed25519 algorithms.  XRPKit is available on iOS, macOS and Linux.  WIP - use at your own risk.

## Installation

#### CocoaPods

XRPKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'XRPKit'
```
#### Swift Package Manager

You can use [The Swift Package Manager](https://swift.org/package-manager) to
install `XRPKit` by adding it to your `Package.swift` file:

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
    .package(url: "https://github.com/MitchLang009/XRPKit.git", from: "0.3.0"),
    ]
)
```

## Linux Compatibility

One of the goals of this library is to provide cross-platform support for Linux and support server-side
Swift, however some features may only be available in iOS/macOS due to a lack of Linux supported
libraries (ex. WebSockets).  A test_linux.sh file is included that will run tests in a docker container. All
contributions must compile on Linux.

## Wallets

### Create a new wallet

```swift

import XRPKit

// create a completely new, randomly generated wallet
let wallet = XRPWallet() // defaults to secp256k1
let wallet2 = XRPWallet(type: .secp256k1)
let wallet3 = XRPWallet(type: .ed25519)

```

### Derive wallet from a seed

```swift

import XRPKit

// generate a wallet from an existing seed
let wallet = try! XRPWallet(seed: "snsTnz4Wj8vFnWirNbp7tnhZyCqx9")

```

### Wallet properties
```swift

import XRPKit

let wallet = XRPWallet()

print(wallet.address) // rJk1prBA4hzuK21VDK2vK2ep2PKGuFGnUD
print(wallet.seed) // snsTnz4Wj8vFnWirNbp7tnhZyCqx9
print(wallet.publicKey) // 02514FA7EF3E9F49C5D4C487330CC8882C0B4381BEC7AC61F1C1A81D5A62F1D3CF
print(wallet.privateKey) // 003FC03417669696AB4A406B494E6426092FD9A42C153E169A2B469316EA4E96B7

```

### Validation
```swift

import XRPKit

// Address
let btc = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
let xrp = "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK"

XRPWallet.validate(address: btc) // returns false
XRPWallet.validate(address: xrp) // returns true

// Seed
let seed = "shrKftFK3ZkMPkq4xe5wGB8HaNSLf"

XRPWallet.validate(seed: xrp) // returns false
XRPWallet.validate(seed: seed) // returns true

```

## Transactions

### Sending XRP
```swift

import XRPKit

let wallet = try! XRPWallet(seed: "shrKftFK3ZkMPkq4xe5wGB8HaNSLf")
let amount = try! XRPAmount(drops: 100000000)

XRPTransaction.send(from: wallet, to: "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK", amount: amount) { (result) in
    switch result {
    case .success(let txResult):
        print(txResult)
    case .failure(let error):
        print(error)
    }
}

```

### Sending XRP with custom fields
```swift

import XRPKit

let wallet = try! XRPWallet(seed: "shrKftFK3ZkMPkq4xe5wGB8HaNSLf")

let fields: [String:Any] = [
    "TransactionType" : "Payment",
    "Account" : wallet.address,
    "Destination" : "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK",
    "Amount" : "10000000",
    "Flags" : 2147483648,
    "LastLedgerSequence" : 951547,
    "Fee" : "40",
    "Sequence" : 11,
]

// create the transaction (offline)
let transaction = XRPTransaction(fields: fields)

// sign the transaction (offline)
let signedTransaction = try! transaction.sign(wallet: wallet)
    
// submit the transaction (online)
signedTransaction.submit { (result) in
    switch result {
    case .success(let txResult):
        print(txResult)
    case .failure(let error):
        print(error)
    }
}

```


### Sending XRP with autofilled fields

```swift

import XRPKit

let wallet = try! XRPWallet(seed: "shrKftFK3ZkMPkq4xe5wGB8HaNSLf")

// dictionary containing partial transaction fields
let fields: [String:Any] = [
    "TransactionType" : "Payment",
    "Destination" : "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK",
    "Amount" : "100000000",
    "Flags" : 2147483648,
]

// create the transaction from dictionary
let partialTransaction = XRPTransaction(fields: fields)

// autofill missing transaction fields (online)
partialTransaction.autofill(address: wallet.address, completion: { (result) in
    switch result {
    case .success(let transaction):
        // sign the transaction (offline)
        let signedTransaction = try! transaction.sign(wallet: wallet)
        
        // submit the signed transaction (online)
        signedTransaction.submit(completion: { (result) in
            switch result {
            case .success(let txResult):
                print(txResult)
            case .failure(let error):
                print(error)
            }
        })
    case .failure(let error):
        print(error)
    }
})

```

### Transaction Result 

```swift

//    SUCCESS: {
//        result =     {
//            "engine_result" = tesSUCCESS;
//            "engine_result_code" = 0;
//            "engine_result_message" = "The transaction was applied. Only final in a validated ledger.";
//            status = success;
//            "tx_blob" = 12000022800000002400000008201B000E83A6614000000005F5E100684000000000000028732102890EDF51199AEB1815324BA985C192D369B324AF6ABC1EBAD450E07EFBF5997E7446304402203765F06FB1D1D9FE942680A39C0925E95DC0AE18893268FDB5AF3CAFC5F6A87802201EFCE19E9C7ABBDD7C73F651A9AF6A323DDB4CE060A4CB63866512365830BEED81142B2DFB7FF7A2E9D8022144727A06141E4B3907248314F841A55DBAB1296D9A95F4CA8C05B721C1B0585C;
//            "tx_json" =         {
//                Account = rhAK9w7X64AaZqSWEhajcq5vhGtxEcaUS7;
//                Amount = 100000000;
//                Destination = rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK;
//                Fee = 40;
//                Flags = 2147483648;
//                LastLedgerSequence = 951206;
//                Sequence = 8;
//                SigningPubKey = 02890EDF51199AEB1815324BA985C192D369B324AF6ABC1EBAD450E07EFBF5997E;
//                TransactionType = Payment;
//                TxnSignature = 304402203765F06FB1D1D9FE942680A39C0925E95DC0AE18893268FDB5AF3CAFC5F6A87802201EFCE19E9C7ABBDD7C73F651A9AF6A323DDB4CE060A4CB63866512365830BEED;
//                hash = 4B709C7DFA8F8F396E4BB2CEACAFD61CA07000940736971AA788754267EE69AD;
//            };
//        };
//    }

```

## Ledger Info

### Check balance
```swift

import XRPKit

XRPLedger.getBalance(address: "rPdCDje24q4EckPNMQ2fmUAMDoGCCu3eGK") { (result) in
    switch result {
    case .success(let amount):
        print(amount.prettyPrinted()) // 1,800.000000
    case .failure(let error):
        print(error)
    }
}

```

## WebSocket Support

WebSockets are only supported on Apple platforms through URLSessionWebSocketTask.  On Linux XRPLedger.ws is unavailable.  Support for Linux
will be possible with the availability of a WebSocket client library.

More functionality to come.

### Example Command
```swift

import XRPKit

XRPLedger.ws.delegate = self // XRPWebSocketDelegate
XRPLedger.ws.connect(url: .xrpl_ws_Devnet)
let parameters: [String: Any] = [
    "id" : "test",
    "method" : "fee"
]
let data = try! JSONSerialization.data(withJSONObject: parameters, options: [])
XRPLedger.ws.send(data: data)

```

### Transaction Stream Request
```swift

import XRPKit

XRPLedger.ws.delegate = self // XRPWebSocketDelegate
XRPLedger.ws.connect(url: .xrpl_ws_Devnet)
XRPLedger.ws.subscribe(account: "r34XnDB2zS11NZ1wKJzpU1mjWExGVugTaQ")

```

### Responses/Streams and XRPWebSocketDelegate

```swift

import XRPKit

class MyClass: XRPWebSocketDelegate {

    func onConnected(connection: XRPWebSocket) {
        
    }
    
    func onDisconnected(connection: XRPWebSocket, error: Error?) {
        
    }
    
    func onError(connection: XRPWebSocket, error: Error) {
        
    }
    
    func onResponse(connection: XRPWebSocket, response: XRPWebSocketResponse) {
        
    }
    
    func onStream(connection: XRPWebSocket, object: NSDictionary) {
        
    }
    
}

```



## Author

MitchLang009, mitch.s.lang@gmail.com

## License

XRPKit is available under the MIT license. See the LICENSE file for more info.


[badge-pms]: https://img.shields.io/badge/supports-CocoaPods%20%7C%20SwiftPM-green.svg
[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-lightgrey.svg
