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

    func findApprovePair(for targetAddress: String, userWalletModels: [UserWalletModel]) -> VisaOnboardingTangemWalletDeployApproveViewModel.ApprovePair? {
        for userWalletModel in userWalletModels {
            if userWalletModel.isUserWalletLocked {
                continue
            }

            let config = userWalletModel.config
            let sessionFilter = config.cardSessionFilter
            guard
                let wallet = userWalletModel.keysRepository.keys.first(where: { $0.curve == visaUtilities.mandatoryCurve })
            else {
                continue
            }

            do {
                var derivationPath: DerivationPath?
                if let derivationStyle = config.derivationStyle,
                   let path = visaUtilities.visaBlockchain.derivationPath(for: derivationStyle) {
                    derivationPath = path
                }

                let publicKey = try findPublicKey(for: targetAddress, derivationPath: derivationPath, in: wallet)
                return .init(
                    sessionFilter: sessionFilter,
                    publicKey: publicKey,
                    derivationPath: derivationPath,
                    tangemSdk: config.makeTangemSdk()
                )
            } catch {
                AppLog.error("Failed to find wallet", error: error)
            }
        }

        return nil
    }

    private func findPublicKey(for targetAddress: String, derivationPath: DerivationPath?, in wallet: CardDTO.Wallet) throws (VisaWalletPublicKeyUtility.SearchError) -> Data {
        guard let derivationPath else {
            return try findPublicKey(for: targetAddress, in: wallet)
        }

        guard let extendedPublicKey = wallet.derivedKeys[derivationPath] else {
            throw .missingDerivedKeys
        }

        try visaWalletPublicKeyUtility.validateExtendedPublicKey(targetAddress: targetAddress, extendedPublicKey: extendedPublicKey, derivationPath: derivationPath)

        return wallet.publicKey
    }

    private func findPublicKey(for targetAddress: String, in wallet: CardDTO.Wallet) throws (VisaWalletPublicKeyUtility.SearchError) -> Data {
        let publicKey = wallet.publicKey

        try visaWalletPublicKeyUtility.validatePublicKey(targetAddress: targetAddress, publicKey: publicKey)

        return publicKey
    }
}
