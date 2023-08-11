//
//  PromotionService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk
import BlockchainSdk
import Moya

class PromotionService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var readyForAwardPublisher: AnyPublisher<Void, Never> {
        readyForAwardSubject.eraseToAnyPublisher()
    }

    let currentProgramName = "1inch"
    private let promoCodeStorageKey = "promo_code"

    // "491" -- hack to reset the storage in 4.9.1 due to the change in the way we record finished promotions.
    // Worst case the users will send one more network request per device.
    private let finishedPromotionNamesStorageKey = "finished_promotion_names_491"
    private let awardedPromotionNamesStorageKey = "awarded_promotion_names"

    var awardAmount: Int?
    var promotionAvailable: Bool = false

    private let readyForAwardSubject = PassthroughSubject<Void, Never>()
    private var supportedBlockchains: Set<Blockchain> {
        userWalletRepository.selectedModel?.config.supportedBlockchains ?? []
    }

    init() {}
}

extension PromotionService: PromotionServiceProtocol {
    var questionnaireFinished: Bool {
        AppSettings.shared.promotionQuestionnaireFinished
    }

    var promoCode: String? {
        let secureStorage = SecureStorage()
        guard
            let promoCodeData = try? secureStorage.get(promoCodeStorageKey),
            let promoCode = String(data: promoCodeData, encoding: .utf8)
        else {
            return nil
        }

        return promoCode
    }

    func didBecomeReadyForAward() {
        readyForAwardSubject.send(())
    }

    func checkPromotion(isNewCard: Bool, userWalletId: String?, timeout: TimeInterval?) async {
        let promotionAvailable: Bool
        let award: Int?

        if !FeatureProvider.isAvailable(.learnToEarn) || currentPromotionIsFinished() {
            promotionAvailable = false
            award = nil
        } else {
            do {
                let promotion = try await tangemApiService.promotion(programName: currentProgramName, timeout: timeout)

                let cardParameters: PromotionParameters.CardParameters
                if isNewCard {
                    cardParameters = promotion.newCard
                } else {
                    cardParameters = promotion.oldCard
                }

                let promotionActive = (cardParameters.status == .active)
                let alreadyClaimedAward = await alreadyClaimedAward(userWalletId: userWalletId)

                let madePurchase: Bool
                let madePromotionalPurchase: Bool
                if let promoCode, let userWalletId {
                    // New user
                    // Only able to claim the reward AFTER they made a purchase
                    // Regardless of whether or not promotion has finished or not
                    let hasPromoCodePurchase = await hasPurchaseForPromoCode(promoCode, userWalletId: userWalletId)

                    madePurchase = hasPromoCodePurchase
                    madePromotionalPurchase = hasPromoCodePurchase
                } else {
                    // Old user
                    // They have already made the purchase, albeit not as part of the promotion
                    // Thus they can only claim while the promotion lasts
                    madePurchase = true
                    madePromotionalPurchase = false
                }

                promotionAvailable = (promotionActive || madePromotionalPurchase) && !alreadyClaimedAward && madePurchase

                // Only mark the promotion as finished when we know the UserWallet ID and we know it's the old user (no promocode)
                // This is done to prolong the promotion for new users who went through the promotion but did not buy the wallet yet
                // We're going to wait for them to claim the reward
                if cardParameters.status == .finished, userWalletId != nil, promoCode == nil || currentPromotionIsAwarded() {
                    markCurrentPromotionAsFinished(true)
                }

                award = cardParameters.award
            } catch {
                promotionAvailable = false
                award = nil
            }
        }

        awardAmount = award
        self.promotionAvailable = promotionAvailable
    }

    func setQuestionnaireFinished(_ finished: Bool) {
        AppSettings.shared.promotionQuestionnaireFinished = finished
    }

    func setPromoCode(_ promoCode: String?) {
        do {
            let secureStorage = SecureStorage()

            if let promoCode {
                guard let promoCodeData = promoCode.data(using: .utf8) else { return }

                try secureStorage.store(promoCodeData, forKey: promoCodeStorageKey)
            } else {
                try secureStorage.delete(promoCodeStorageKey)
            }
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.error("Failed to update promo code")
        }
    }

    func checkIfCanGetAward(userWalletId: String) async throws {
        do {
            if let promoCode {
                try await tangemApiService.validateNewUserPromotionEligibility(walletId: userWalletId, code: promoCode)
            } else {
                try await tangemApiService.validateOldUserPromotionEligibility(walletId: userWalletId, programName: currentProgramName)
            }
        } catch {
            if case .statusCode = error as? MoyaError {
                throw AppError.serverUnavailable
            } else {
                throw error
            }
        }
    }

    func claimReward(userWalletId: String, userTokensManager: UserTokensManager) async throws -> Blockchain? {
        guard let awardDetails = try await awardDetails(userTokensManager: userTokensManager) else { return nil }

        let address = awardDetails.address

        if let promoCode {
            try await tangemApiService.awardNewUser(walletId: userWalletId, address: address, code: promoCode)
        } else {
            try await tangemApiService.awardOldUser(walletId: userWalletId, address: address, programName: currentProgramName)
        }

        markCurrentPromotionAsFinished(true)
        markCurrentPromotionAsAwarded(true)

        return awardDetails.blockchain
    }

    func awardedPromotionNames() -> Set<String> {
        do {
            let storage = SecureStorage()
            guard let data = try storage.get(awardedPromotionNamesStorageKey) else { return [] }
            return try JSONDecoder().decode(Set<String>.self, from: data)
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.debug("Failed to get awarded promotions")
            return []
        }
    }

    func resetAward(cardId: String) async throws {
        saveAwardedPromotions([])
        try await tangemApiService.resetAwardForCurrentWallet(cardId: cardId)
    }

    func finishedPromotionNames() -> Set<String> {
        do {
            let storage = SecureStorage()
            guard let data = try storage.get(finishedPromotionNamesStorageKey) else { return [] }
            return try JSONDecoder().decode(Set<String>.self, from: data)
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.debug("Failed to get finished promotions")
            return []
        }
    }

    func resetFinishedPromotions() {
        if AppEnvironment.current.isProduction {
            AppLog.shared.debug("Trying to reset finished promotions in production. Not allowed")
            fatalError("Trying to reset finished promotions in production. Not allowed")
        }

        saveFinishedPromotions([])
    }
}

extension PromotionService {
    private struct AwardDetails {
        let blockchain: Blockchain
        let address: String
    }

    private func awardDetails(userTokensManager: UserTokensManager) async throws -> AwardDetails? {
        let promotion = try await tangemApiService.promotion(programName: currentProgramName, timeout: nil)

        guard
            let awardBlockchain = supportedBlockchains[promotion.awardPaymentToken.networkId],
            let awardToken = promotion.awardPaymentToken.storageToken
        else {
            throw TangemAPIError(code: .decode)
        }

        do {
            let address = try await userTokensManager.add(.token(awardToken, awardBlockchain), derivationPath: nil)
            return AwardDetails(blockchain: awardBlockchain, address: address)
        } catch {
            if error.toTangemSdkError().isUserCancelled {
                return nil
            } else {
                throw error
            }
        }
    }

    private func alreadyClaimedAward(userWalletId: String?) async -> Bool {
        if awardedPromotionNames().contains(currentProgramName) {
            return true
        }

        guard let userWalletId else {
            return false
        }

        do {
            let canClaim = try await tangemApiService.validateOldUserPromotionEligibility(walletId: userWalletId, programName: currentProgramName).valid
            return !canClaim
        } catch {
            guard let tangemApiError = error as? TangemAPIError else {
                return false
            }

            switch tangemApiError.code {
            case .promotionCardAlreadyAwarded, .promotionWalletAlreadyAwarded:
                markCurrentPromotionAsAwarded(true)
                return true
            default:
                return false
            }
        }
    }

    private func hasPurchaseForPromoCode(_ promoCode: String, userWalletId: String) async -> Bool {
        do {
            let result = try await tangemApiService.validateNewUserPromotionEligibility(walletId: userWalletId, code: promoCode)
            let canGetAward = result.valid
            return canGetAward
        } catch {
            // We only care about promotionCodeNotApplied error but it does not make sense to treat other errors differently
            return false
        }
    }

    private func currentPromotionIsAwarded() -> Bool {
        awardedPromotionNames().contains(currentProgramName)
    }

    private func currentPromotionIsFinished() -> Bool {
        finishedPromotionNames().contains(currentProgramName)
    }

    private func markCurrentPromotionAsFinished(_ finished: Bool) {
        let finishedPromotionNames = finishedPromotionNames()

        var newFinishedPromotionNames = finishedPromotionNames
        if finished {
            newFinishedPromotionNames.insert(currentProgramName)
        } else {
            newFinishedPromotionNames.remove(currentProgramName)
        }

        guard finishedPromotionNames != newFinishedPromotionNames else { return }

        saveFinishedPromotions(newFinishedPromotionNames)
    }

    private func saveFinishedPromotions(_ programNames: Set<String>) {
        do {
            let data = try JSONEncoder().encode(programNames)

            let storage = SecureStorage()
            try storage.store(data, forKey: finishedPromotionNamesStorageKey)
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.debug("Failed to set finished programs")
        }
    }

    private func markCurrentPromotionAsAwarded(_ awarded: Bool) {
        let awardedPromotionNames = awardedPromotionNames()

        var newAwardedPromotionNames = awardedPromotionNames
        if awarded {
            newAwardedPromotionNames.insert(currentProgramName)
        } else {
            newAwardedPromotionNames.remove(currentProgramName)
        }

        guard awardedPromotionNames != newAwardedPromotionNames else { return }

        saveAwardedPromotions(newAwardedPromotionNames)
    }

    private func saveAwardedPromotions(_ promotionNames: Set<String>) {
        do {
            let data = try JSONEncoder().encode(promotionNames)

            let storage = SecureStorage()
            try storage.store(data, forKey: awardedPromotionNamesStorageKey)
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.debug("Failed to set awarded promotions")
        }
    }
}
