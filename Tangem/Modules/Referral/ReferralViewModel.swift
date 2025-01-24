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
import SwiftUI
import BlockchainSdk

class ReferralViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var isProcessingRequest: Bool = false
    @Published private(set) var referralProgramInfo: ReferralProgramInfo?
    @Published var errorAlert: AlertBinder?

    @Published var expectedAwardsExpanded = false

    private weak var coordinator: ReferralRoutable?
    private let userTokensManager: UserTokensManager
    private let userWalletId: Data
    private let supportedBlockchains: Set<Blockchain>

    private let expectedAwardsFetchLimit = 30
    private let expectedAwardsShortListLimit = 3

    private var shareLink: String {
        guard let referralInfo = referralProgramInfo?.referral else {
            return ""
        }

        return Localization.referralShareLink(referralInfo.shareLink)
    }

    init(
        input: ReferralInputModel,
        coordinator: ReferralRoutable
    ) {
        userTokensManager = input.userTokensManager
        userWalletId = input.userWalletId
        supportedBlockchains = input.supportedBlockchains
        self.coordinator = coordinator

        runTask(in: self) { root in
            await root.loadReferralInfo()
        }
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
            let blockchain = supportedBlockchains[award.token.networkId],
            let token = award.token.storageToken
        else {
            Analytics.error(Localization.referralErrorFailedToLoadInfo)
            errorAlert = AlertBuilder.makeOkErrorAlert(
                message: Localization.referralErrorFailedToLoadInfo,
                okAction: coordinator?.dismiss ?? {}
            )
            isProcessingRequest = false
            return
        }

        do {
            let address = try await userTokensManager.add(.token(token, .init(blockchain, derivationPath: nil)))
            isProcessingRequest = false

            let referralProgramInfo: ReferralProgramInfo? = try await runInTask { [weak self] in
                guard let self else { return nil }

                return try await tangemApiService.participateInReferralProgram(using: award.token, for: address, with: userWalletId.hexString)
            }
            self.referralProgramInfo = referralProgramInfo
        } catch {
            if !error.toTangemSdkError().isUserCancelled {
                let referralError = ReferralError(error)
                let message = Localization.referralErrorFailedToParticipate(referralError.code)
                errorAlert = AlertBuilder.makeOkErrorAlert(message: message)
                Analytics.error(referralError)
            }
        }

        isProcessingRequest = false
    }

    func copyPromoCode() {
        Analytics.log(.referralButtonCopyCode)
        UIPasteboard.general.string = referralProgramInfo?.referral?.promoCode

        Toast(view: SuccessToast(text: Localization.referralPromoCodeCopied))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }

    func sharePromoCode() {
        Analytics.log(.referralButtonShareCode)
        let shareActivityVC = UIActivityViewController(activityItems: [shareLink], applicationActivities: nil)
        AppPresenter.shared.show(shareActivityVC)
    }

    @MainActor
    private func loadReferralInfo() async {
        do {
            let referralProgramInfo: ReferralProgramInfo? = try await runInTask { [weak self] in
                guard let self else { return nil }

                return try await tangemApiService.loadReferralProgramInfo(for: userWalletId.hexString, expectedAwardsLimit: expectedAwardsFetchLimit)
            }
            self.referralProgramInfo = referralProgramInfo
        } catch {
            let referralError = ReferralError(error)
            let message = Localization.referralErrorFailedToLoadInfoWithReason(referralError.code)
            Analytics.error(referralError)
            errorAlert = AlertBuilder.makeOkErrorAlert(message: message, okAction: coordinator?.dismiss ?? {})
        }
    }
}

// MARK: UI stuff

extension ReferralViewModel {
    func awardDescription(highlightColor: Color) -> NSAttributedString {
        var formattedAward = ""
        var addressContent = ""
        var tokenName = ""

        if let info = referralProgramInfo,
           let award = info.conditions.awards.first {
            formattedAward = "\(award.amount) \(award.token.symbol)"
        }

        if let address = referralProgramInfo?.referral?.address {
            let addressFormatter = AddressFormatter(address: address)
            addressContent = addressFormatter.truncated()
        }

        if let token = referralProgramInfo?.conditions.awards.first?.token,
           let blockchain = supportedBlockchains[token.networkId] {
            tokenName = blockchain.displayName
        }

        let rawText = Localization.referralPointCurrenciesDescription(formattedAward, tokenName, addressContent)
        return TangemRichTextFormatter(highlightColor: UIColor(highlightColor)).format(rawText)
    }

    var discount: String {
        guard let info = referralProgramInfo else {
            return ""
        }

        return Localization.referralPointDiscountDescriptionValue("\(info.conditions.discount.amount)\(info.conditions.discount.type.symbol)")
    }

    var hasPurchases: Bool {
        let count = referralProgramInfo?.referral?.walletsPurchased ?? 0
        return count > 0
    }

    var numberOfWalletsBought: String {
        let count = referralProgramInfo?.referral?.walletsPurchased ?? 0
        return Localization.referralWalletsPurchasedCount(count)
    }

    var isExpectingAwards: Bool {
        referralProgramInfo?.expectedAwards != nil
    }

    var hasExpectedAwards: Bool {
        let count = referralProgramInfo?.expectedAwards?.numberOfWallets ?? 0
        return count > 0
    }

    var numberOfWalletsForPayments: String {
        let count = referralProgramInfo?.expectedAwards?.numberOfWallets ?? 0
        return Localization.referralNumberOfWallets(count)
    }

    var expectedAwards: [ExpectedAward] {
        guard let list = referralProgramInfo?.expectedAwards?.list else {
            return []
        }

        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyy-MM-dd"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true

        let awards: [ExpectedAward] = list.map {
            let amount = "\($0.amount) \($0.currency)"

            guard
                let date = dateParser.date(from: $0.paymentDate)
            else {
                return ExpectedAward(date: $0.paymentDate, amount: amount)
            }

            let formattedDate = dateFormatter.string(from: date)
            return ExpectedAward(date: formattedDate, amount: amount)
        }

        let awardsToShow = expectedAwardsExpanded ? expectedAwardsFetchLimit : expectedAwardsShortListLimit
        return Array(awards.prefix(awardsToShow))
    }

    var canExpandExpectedAwards: Bool {
        let list = referralProgramInfo?.expectedAwards?.list ?? []
        return list.count > expectedAwardsShortListLimit
    }

    var expandButtonText: String {
        expectedAwardsExpanded ? Localization.referralLess : Localization.referralMore
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

extension ReferralViewModel {
    struct ExpectedAward {
        let date: String
        let amount: String
    }
}

private struct TangemRichTextFormatter {
    // Formatting rich text as NSAttributedString
    // Supported formats: ^^color^^ for the highlight color
    private let highlightColor: UIColor

    init(highlightColor: UIColor) {
        self.highlightColor = highlightColor
    }

    func format(_ string: String) -> NSAttributedString {
        var attributedString = NSMutableAttributedString(string: string)

        attributedString = formatColor(string, attributedString, highlightColor: highlightColor)

        return attributedString
    }

    private func formatColor(_ string: String, _ attributedString: NSMutableAttributedString, highlightColor: UIColor) -> NSMutableAttributedString {
        var originalString = string

        let regex = try! NSRegularExpression(pattern: "\\^{2}.+?\\^{2}")

        let wholeRange = NSRange(location: 0, length: (originalString as NSString).length)
        let matches = regex.matches(in: originalString, range: wholeRange)

        for match in matches.reversed() {
            let formatterTagLength = 2

            let richText = String(originalString[Range(match.range, in: originalString)!])
            let plainText = richText.dropFirst(formatterTagLength).dropLast(formatterTagLength)

            originalString = originalString.replacingOccurrences(of: richText, with: plainText)

            let richTextRange = NSRange(location: match.range.location, length: match.range.length)

            attributedString.replaceCharacters(in: richTextRange, with: String(plainText))

            let plainTextRange = NSRange(location: match.range.location, length: plainText.count)
            attributedString.addAttribute(.foregroundColor, value: highlightColor, range: plainTextRange)
        }

        return attributedString
    }
}
