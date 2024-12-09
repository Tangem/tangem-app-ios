//
//  VisaApprovePairSearchUtility.swift
//  TangemApp
//
//  Created by Andrew Son on 09.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk
import TangemVisa

struct VisaApprovePairSearchUtility {
    let visaUtilities: VisaUtilities
    let visaWalletPublicKeyUtility: VisaWalletPublicKeyUtility

    init(isTestnet: Bool) {
        visaUtilities = .init(isTestnet: isTestnet)
        visaWalletPublicKeyUtility = .init(isTestnet: isTestnet)
    }

    func findApprovePair(for targetAddress: String, userWalletModels: [UserWalletModel]) -> VisaOnboardingTangemWalletConfirmationViewModel.ApprovePair? {
        for userWalletModel in userWalletModels {
            if userWalletModel.isUserWalletLocked {
                continue
            }

            let config = userWalletModel.config
            guard let cardContainer = config as? CardContainer else {
                continue
            }
            let cardDTO = cardContainer.card

            do {
                var derivationPath: DerivationPath?
                if let derivationStyle = config.derivationStyle,
                   let path = visaUtilities.visaBlockchain.derivationPath(for: derivationStyle) {
                    derivationPath = path
                }
                let publicKey = try findPublicKey(for: targetAddress, derivationStyle: config.derivationStyle, in: cardDTO)
                return .init(
                    cardId: cardContainer.card.cardId,
                    publicKey: publicKey,
                    derivationPath: derivationPath,
                    tangemSdk: config.makeTangemSdk()
                )
            } catch {
                print("Failed to find wallet. Error: \(error)")
            }
        }

        return nil
    }

    private func findPublicKey(for targetAddress: String, in cardDTO: CardDTO) throws (VisaWalletPublicKeyUtility.SearchError) -> Data {
        let wallet = try findWalletOnVisaCurve(in: cardDTO)
        let publicKey = wallet.publicKey

        try visaWalletPublicKeyUtility.validatePublicKey(targetAddress: targetAddress, publicKey: publicKey)

        return publicKey
    }

    private func findPublicKey(for targetAddress: String, derivationStyle: DerivationStyle?, in cardDTO: CardDTO) throws (VisaWalletPublicKeyUtility.SearchError) -> Data {
        if let derivationStyle {
            return try findPublicKey(for: targetAddress, derivationStyle: derivationStyle, in: cardDTO)
        } else {
            return try findPublicKey(for: targetAddress, in: cardDTO)
        }
    }

    private func findPublicKey(for targetAddress: String, derivationStyle: DerivationStyle, in cardDTO: CardDTO) throws (VisaWalletPublicKeyUtility.SearchError) -> Data {
        guard let derivationPath = visaUtilities.visaBlockchain.derivationPath(for: derivationStyle) else {
            throw .failedToGenerateDerivationPath
        }

        let wallet = try findWalletOnVisaCurve(in: cardDTO)

        guard let extendedPublicKey = wallet.derivedKeys[derivationPath] else {
            throw .missingDerivedKeys
        }

        try visaWalletPublicKeyUtility.validateExtendedPublicKey(targetAddress: targetAddress, extendedPublicKey: extendedPublicKey, derivationPath: derivationPath)

        return extendedPublicKey.publicKey
    }

    private func findWalletOnVisaCurve(in cardDTO: CardDTO) throws (VisaWalletPublicKeyUtility.SearchError) -> CardDTO.Wallet {
        guard let wallet = cardDTO.wallets.first(where: { $0.curve == visaUtilities.mandatoryCurve }) else {
            throw .missingWalletOnTargetCurve
        }

        return wallet
    }
}
