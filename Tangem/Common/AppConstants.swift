//
//  Constants.swift
//  Tangem
//
//  Created by Andrew Son on 13/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import FirebaseAnalytics
import Foundation
import UIKit

enum AppConstants {
    static let webShopUrl: URL = {
        var urlComponents = URLComponents(string: "https://buy.tangem.com")!
        urlComponents.queryItems = [
            URLQueryItem(name: "utm_source", value: "tangem"),
            URLQueryItem(name: "utm_medium", value: "app"),
            URLQueryItem(name: "app_instance_id", value: FirebaseAnalytics.Analytics.appInstanceID()),
        ]
        return urlComponents.url!
    }()

    static var isSmallScreen: Bool {
        UIScreen.main.bounds.width < 375 || UIScreen.main.bounds.height < 650
    }

    static let platformName = "iOS"

    static let messageForTokensKey = "TokensSymmetricKey"
    static let maximumFractionDigitsForBalance = 8

    static let defaultScrollViewKeyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag

    static let minusSign = "−" // shorter stick
    static let dashSign = "—" // longer stick (em-dash)
    static let unbreakableSpace = "\u{00a0}"
    static let dotSign = "•"
    static let rubCurrencyCode = "RUB"
    static let rubSign = "₽"
    static let usdCurrencyCode = "USD"
    static let usdSign = "$"

    static let sessionId = UUID().uuidString

    #warning("TODO: use TangemBlogUrlBuilder")
    static let feeExplanationTangemBlogURL = URL(string: "https://tangem.com/en/blog/post/what-is-a-transaction-fee-and-why-do-we-need-it/")!

    static let tosURL = URL(string: "https://tangem.com/tangem_tos.html")!

    static let howToBuyURL = URL(string: "https://tangem.com/howtobuy.html")!
}
