// Copyright Keefer Taylor, 2019

import Foundation
import TangemSdk

/// Common prefixes used across Tezos Cryptography.
enum TezosPrefix {
    enum Watermark {
        static let genericOperation: Data = .init(hexString: "03") // 03
    }

    enum Signature: String {
        case ed25519 = "09F5CD8612" // edsig
        case secp256k1 = "0D7365133F" // spsig
        case p256 = "36F02C34" // p2sig

        var bytesValue: Data {
            Data(hexString: rawValue)
        }
    }

    enum PublicKey: String {
        case ed25519 = "0D0F25D9" // edpk
        case secp256k1 = "03FEE256" // sppk
        case p256 = "03B28B7F" // p2pk

        var bytesValue: Data {
            Data(hexString: rawValue)
        }

        var encodedPrefix: String {
            switch self {
            case .ed25519: return "00"
            case .secp256k1: return "01"
            case .p256: return "02"
            }
        }
    }

    enum Address: String {
        case tz1 = "06A19F"
        case tz2 = "06A1A1"
        case tz3 = "06A1A4"
        case kt1 = "025A79"

        var bytesValue: Data {
            Data(hexString: rawValue)
        }

        var encodedPrefix: String {
            switch self {
            case .tz1: return "00"
            case .tz2: return "01"
            case .tz3: return "02"
            case .kt1: fatalError("Nothing to encode")
            }
        }
    }

    enum TransactionKind: String {
        case reveal
        case transaction

        var encodedPrefix: String {
            switch self {
            case .reveal:
                return "6b"
            case .transaction:
                return "6c"
            }
        }
    }

    static let branch = "0134"
}

extension TezosPrefix {
    static func publicPrefix(for curve: EllipticCurve) -> Data {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return PublicKey.ed25519.bytesValue
        case .secp256k1:
            return PublicKey.secp256k1.bytesValue
        case .secp256r1:
            return PublicKey.p256.bytesValue
        default:
            fatalError("unsupported curve")
        }
    }

    static func signaturePrefix(for curve: EllipticCurve) -> Data {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return Signature.ed25519.bytesValue
        case .secp256k1:
            return Signature.secp256k1.bytesValue
        case .secp256r1:
            return Signature.p256.bytesValue
        default:
            fatalError("unsupported curve")
        }
    }

    static func addressPrefix(for curve: EllipticCurve) -> Data {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return Address.tz1.bytesValue
        case .secp256k1:
            return Address.tz2.bytesValue
        case .secp256r1:
            return Address.tz3.bytesValue
        default:
            fatalError("unsupported curve")
        }
    }
}
