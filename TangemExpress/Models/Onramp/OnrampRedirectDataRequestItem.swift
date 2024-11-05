//
//  OnrampRedirectDataRequestItem.swift
//  TangemApp
//
//  Created by Sergey Balashov on 24.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampRedirectDataRequestItem {
    public let quotesItem: OnrampQuotesRequestItem
    public let redirectSettings: OnrampRedirectSettings

    public init(
        quotesItem: OnrampQuotesRequestItem,
        redirectSettings: OnrampRedirectSettings
    ) {
        self.quotesItem = quotesItem
        self.redirectSettings = redirectSettings
    }
}
