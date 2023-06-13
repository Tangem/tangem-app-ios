//
//  ReferralViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 02/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import BlockchainSdk

class ReferralViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var isProcessingRequest: Bool = false
    @Published private(set) var referralProgramInfo: ReferralProgramInfo?
    @Published var errorAlert: AlertBinder?
    @Published var showCodeCopiedToast: Bool = false

    private weak var coordinator: ReferralRoutable?
    private let cardModel: CardViewModel
    private let userWalletId: Data

    private var shareLink: String {
        guard let referralInfo = referralProgramInfo?.referral else {
            return ""
        }

        return Localization.referralShareLink(referralInfo.shareLink)
    }

    init(cardModel: CardViewModel, userWalletId: Data, coordinator: ReferralRoutable) {
        self.cardModel = cardModel
        self.userWalletId = userWalletId
        self.coordinator = coordinator

        runTask(loadReferralInfo)
    }

    @MainActor
    func participateInReferralProgram() async {
        if isProcessingRequest {
            return
        }

        isProcessingRequest = true
        Analytics.log(.referralButtonParticipate)

        guard
            let award = referralProgramInfo?.conditions.awards.first,
            let blockchain = Blockchain(from: award.token.networkId)
        else {
            AppLog.shared.error(Localization.referralErrorFailedToLoadInfo)
            errorAlert = AlertBuilder.makeOkErrorAlert(
                message: Localization.referralErrorFailedToLoadInfo,
                okAction: coordinator?.dismiss ?? {}
            )
            isProcessingRequest = false
            return
        }

        let token = award.token

        guard let address = cardModel.walletModels.first(where: { $0.blockchainNetwork.blockchain == blockchain })?.wallet.address else {
            requestDerivation(for: blockchain, with: token)
            return
        }

        saveToStorageIfNeeded(token, for: blockchain)
        do {
            let referralProgramInfo = try await runInTask {
                try await self.tangemApiService.participateInReferralProgram(using: token, for: address, with: self.userWalletId.hexString)
            }
            self.referralProgramInfo = referralProgramInfo
        } catch {
            let referralError = ReferralError(error)
            let message = Localization.referralErrorFailedToParticipate(referralError.code)
            errorAlert = AlertBuilder.makeOkErrorAlert(message: message)
            AppLog.shared.error(referralError)
        }

        isProcessingRequest = false
    }

    func copyPromoCode() {
        Analytics.log(.referralButtonCopyCode)
        UIPasteboard.general.string = referralProgramInfo?.referral?.promoCode
        showCodeCopiedToast = true
    }

    func sharePromoCode() {
        Analytics.log(.referralButtonShareCode)
        let shareActivityVC = UIActivityViewController(activityItems: [shareLink], applicationActivities: nil)
        AppPresenter.shared.show(shareActivityVC)
    }

    @MainActor
    private func loadReferralInfo() async {
        do {
            let referralProgramInfo = try await runInTask {
                try await self.tangemApiService.loadReferralProgramInfo(for: self.userWalletId.hexString)
            }
            self.referralProgramInfo = referralProgramInfo
        } catch {
            let referralError = ReferralError(error)
            let message = Localization.referralErrorFailedToLoadInfoWithReason(referralError.code)
            AppLog.shared.error(referralError)
            errorAlert = AlertBuilder.makeOkErrorAlert(message: message, okAction: coordinator?.dismiss ?? {})
        }
    }

    private func requestDerivation(for blockchain: Blockchain, with referralToken: ReferralProgramInfo.Token) {
        let network = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: nil)
        let token = convertToStorageToken(from: referralToken)

        let storageEntry = StorageEntry(blockchainNetwork: network, token: token)
        if let model = cardModel.walletModels.first(where: { $0.blockchainNetwork == network }),
           let token {
            model.addTokens([token])
        }

        cardModel.add(entries: [storageEntry]) { [weak self] result in
            guard let self else { return }

            isProcessingRequest = false
            switch result {
            case .success:
                runTask(participateInReferralProgram)
            case .failure(let error):
                if case .userCancelled = error.toTangemSdkError() {
                    return
                }

                AppLog.shared.error(error)
                errorAlert = error.alertBinder
            }
        }
    }

    private func saveToStorageIfNeeded(_ referralToken: ReferralProgramInfo.Token, for blockchain: Blockchain) {
        let network = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: nil)
        guard
            let storageToken = convertToStorageToken(from: referralToken)
        else {
            return
        }

        var savedEntries = cardModel.getSavedEntries()

        if let savedNetworkIndex = savedEntries.firstIndex(where: { $0.blockchainNetwork == network }),
           !savedEntries[savedNetworkIndex].tokens.contains(where: { $0 == storageToken }) {
            savedEntries[savedNetworkIndex].tokens.append(storageToken)
            cardModel.update(entries: savedEntries)
        }
    }

    private func convertToStorageToken(from token: ReferralProgramInfo.Token) -> Token? {
        guard
            let contractAddress = token.contractAddress,
            let decimalCount = token.decimalCount
        else {
            return nil
        }

        return Token(
            name: token.name,
            symbol: token.symbol,
            contractAddress: contractAddress,
            decimalCount: decimalCount,
            id: token.id
        )
    }
}

// MARK: UI stuff

extension ReferralViewModel {
    var award: String {
        guard
            let info = referralProgramInfo,
            let award = info.conditions.awards.first
        else {
            return ""
        }

        return "\(award.amount) \(award.token.symbol)"
    }

    var awardDescriptionSuffix: String {
        var addressContent = ""
        var tokenName = ""
        if let address = referralProgramInfo?.referral?.address {
            let addressFormatter = AddressFormatter(address: address)
            addressContent = " \(addressFormatter.truncated())"
        }

        if let token = referralProgramInfo?.conditions.awards.first?.token,
           let blockchain = Blockchain(from: token.networkId) {
            tokenName = blockchain.displayName
        }

        return " " + Localization.referralPointCurrenciesDescriptionSuffix(tokenName, addressContent)
    }

    var discount: String {
        guard let info = referralProgramInfo else {
            return ""
        }

        return Localization.referralPointDiscountDescriptionValue("\(info.conditions.discount.amount)\(info.conditions.discount.type.symbol)")
    }

    var numberOfWalletsBought: String {
        let count = referralProgramInfo?.referral?.walletsPurchased ?? 0
        return Localization.referralWalletsPurchasedCount(count)
    }

    var promoCode: String {
        guard let info = referralProgramInfo?.referral else {
            return ""
        }

        return info.promoCode
    }

    var tosButtonPrefix: String {
        if referralProgramInfo?.referral == nil {
            return Localization.referralTosNotEnroledPrefix + " "
        }

        return Localization.referralTosEnroledPrefix + " "
    }

    var isProgramInfoLoaded: Bool { referralProgramInfo != nil }
    var isAlreadyReferral: Bool { referralProgramInfo?.referral != nil }
}

// MARK: - Navigation

extension ReferralViewModel {
    func openTOS() {
        guard
            let link = referralProgramInfo?.conditions.tosLink,
            let url = URL(string: link)
        else {
            AppLog.shared.debug("Failed to create link")
            return
        }

        Analytics.log(.referralButtonOpenTos)
        coordinator?.openTOS(with: url)
    }
}
