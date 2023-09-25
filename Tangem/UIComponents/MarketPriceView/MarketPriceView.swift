//
//  MarketPriceView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 20.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketPriceView: View {
    let currencySymbol: String
    let price: String
    let priceChangeState: TokenPriceChangeView.State
    let tapAction: (() -> Void)?

    var body: some View {
        if let tapAction {
            Button(action: tapAction) {
                marketPriceView
            }
        } else {
            marketPriceView
        }
    }

    private var marketPriceView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(Localization.walletMarketplaceBlockTitle(currencySymbol))
                    .lineLimit(1)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                HStack(spacing: 6) {
                    Text(price)
                        .lineLimit(1)
                        .layoutPriority(1)
                        .truncationMode(.middle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                    TokenPriceChangeView(state: priceChangeState)

                    Text(Localization.walletMarketpriceBlockUpdateTime)
                        .lineLimit(1)
                        .layoutPriority(-1)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }

            Spacer()

            if tapAction != nil {
                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
            }
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}

struct MarketPriceView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MarketPriceView(currencySymbol: "XRP", price: "1,33 $", priceChangeState: .loaded(signType: .positive, text: "0,3%"), tapAction: {})

            MarketPriceView(currencySymbol: "ETH", price: "1 500,33 $", priceChangeState: .loaded(signType: .negative, text: "10,3%"), tapAction: nil)

            MarketPriceView(currencySymbol: "XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP XRP", price: "1 000 000 000 000 000 000 000 000 000 000 000,33 $", priceChangeState: .loaded(signType: .positive, text: "100000000000,33%"), tapAction: {})
        }
        .frame(maxHeight: .infinity)
        .padding()
        .background(Colors.Background.secondary)
    }
}
