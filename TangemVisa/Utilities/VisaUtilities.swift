//
//  VisaUtilities.swift
//  TangemVisa
//
//  Created by Andrew Son on 18/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

public struct VisaUtilities {
    private let isTestnet: Bool

    // TODO: Replace with real URL
    // Right now dApp is not ready, so we don't have actual page
    public let walletConnectURL = URL(string: "https://tangem.com/pay")!

    public init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    public var visaBatches: [String] {
        [
            "AE05",
        ]
    }

    public var mandatoryCurve: EllipticCurve {
        .secp256k1
    }

    public var tokenId: String {
        "tether"
    }

    public var visaDefaultDerivationStyle: DerivationStyle {
        .v3
    }

    public var visaDefaultDerivationPath: DerivationPath? {
        visaBlockchain.derivationPath(for: visaDefaultDerivationStyle)
    }

    public var mockToken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0x1A826Dfe31421151b3E7F2e4887a00070999150f",
            decimalCount: 18,
            id: tokenId
        )
    }

    public var visaBlockchain: Blockchain {
        .polygon(testnet: isTestnet)
    }

    public var addressService: AddressService {
        AddressServiceFactory(blockchain: visaBlockchain).makeAddressService()
    }

    public func visaDerivationPath(style: DerivationStyle) -> DerivationPath? {
        visaBlockchain.derivationPath(for: style)
    }

    public func isVisaCard(_ card: Card) -> Bool {
        return isVisaCard(firmwareVersion: card.firmwareVersion, batchId: card.batchId)
    }

    public func isVisaCard(firmwareVersion: FirmwareVersion, batchId: String) -> Bool {
        return FirmwareVersion.visaRange.contains(firmwareVersion.doubleValue)
            && visaBatches.contains(batchId)
    }

    public func makeAddress(seedKey: Data, extendedKey: ExtendedPublicKey) throws (VisaError) -> Address {
        guard let visaDefaultDerivationPath else {
            throw VisaError.failedToCreateDerivation
        }

        do {
            let hdKey = Wallet.PublicKey.HDKey(path: visaDefaultDerivationPath, extendedPublicKey: extendedKey)
            let publicKey = Wallet.PublicKey(seedKey: seedKey, derivationType: .plain(hdKey))
            let walletAddress = try addressService.makeAddress(for: publicKey, with: .default)
            return walletAddress
        } catch {
            throw .failedToCreateAddress(error)
        }
    }

    func makeAddress(using cardActivationResponse: CardActivationResponse) throws -> Address {
        guard let derivationPath = visaDefaultDerivationPath else {
            throw VisaActivationError.missingDerivationPath
        }

        guard
            let wallet = cardActivationResponse.signedActivationOrder.cardSignedOrder.wallets.first(where: { $0.curve == mandatoryCurve }),
            let derivedKey = wallet.derivedKeys[derivationPath]
        else {
            throw VisaActivationError.missingWallet
        }

        return try makeAddress(seedKey: wallet.publicKey, extendedKey: derivedKey)
    }
}
