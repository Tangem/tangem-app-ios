//
//  ReceiveBottomSheetViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 19/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import CombineExt

class ReceiveBottomSheetViewModel: ObservableObject, Identifiable {
    let addressInfos: [ReceiveAddressInfo]
    let networkWarningMessage: String

    let id = UUID()
    let addressIndexUpdateNotifier = PassthroughSubject<Int, Never>()

    let iconURL: URL?

    var customTokenColor: Color? {
        tokenItem.token?.customTokenColor
    }

    private let tokenItem: TokenItem

    private var currentIndex = 0
    private var indexUpdateSubscription: AnyCancellable?

    var warningMessageFull: String {
        Localization.receiveBottomSheetWarningMessageFull(tokenItem.currencySymbol)
    }

    init(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) {
        self.tokenItem = tokenItem
        iconURL = tokenItem.id != nil ? IconURLBuilder().tokenIconURL(id: tokenItem.id!) : nil
        self.addressInfos = addressInfos

        networkWarningMessage = Localization.receiveBottomSheetWarningMessage(
            tokenItem.name,
            tokenItem.currencySymbol,
            tokenItem.networkName
        )

        bind()
    }

    func onViewAppear() {
        Analytics.log(event: .receiveScreenOpened, params: [.token: tokenItem.currencySymbol])
    }

    func headerForAddress(with info: ReceiveAddressInfo) -> String {
        let name: String
        if addressInfos.count > 1 {
            name = "\(info.localizedName.capitalizingFirstLetter()) \(tokenItem.name)"
        } else {
            name = tokenItem.name
        }
        return Localization.receiveBottomSheetWarningMessage(name, tokenItem.currencySymbol, tokenItem.networkName)
    }

    func copyToClipboard() {
        Analytics.log(event: .buttonCopyAddress, params: [
            .token: tokenItem.currencySymbol,
            .source: Analytics.ParameterValue.receive.rawValue,
        ])
        UIPasteboard.general.string = addressInfos[currentIndex].address

        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }

    func share() {
        Analytics.log(event: .buttonShareAddress, params: [.token: tokenItem.currencySymbol])
        let address = addressInfos[currentIndex].address
        // TODO: Replace with ShareLinks https://developer.apple.com/documentation/swiftui/sharelink for iOS 16+
        let av = UIActivityViewController(activityItems: [address], applicationActivities: nil)
        UIApplication.modalFromTop(av)
    }

    private func bind() {
        indexUpdateSubscription = addressIndexUpdateNotifier
            .assign(to: \.currentIndex, on: self, ownership: .weak)
    }
}
