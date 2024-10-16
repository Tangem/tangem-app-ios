//
//  CurrencySelectView.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct CurrencySelectView: View {
    @ObservedObject var viewModel: CurrencySelectViewModel
    @State private var searchText: String = ""

    var body: some View {
        ZStack {
            Colors.Background.secondary.ignoresSafeArea()

            content
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
        .navigationBarTitle(Localization.detailsRowTitleCurrency, displayMode: .inline)
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .controlSize(.regular)
        case .loaded(let currencies):
            GroupedScrollView(alignment: .leading, spacing: 0) {
                GroupedSection(filter(currencies: currencies)) { currency in
                    currencyView(currency)
                }
                .innerContentPadding(14)
                .interItemSpacing(12)
            }
            .interContentPadding(8)

        case .failedToLoad(let error):
            Text(error.localizedDescription)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .padding(.horizontal, 16)
        }
    }

    private func currencyView(_ currency: CurrenciesResponse.Currency) -> some View {
        Button(action: { viewModel.onSelect(currency) }) {
            HStack {
                Text(currency.description)
                    .style(Fonts.Regular.callout, color: Colors.Text.primary1)

                Spacer()

                Image(systemName: "checkmark.circle")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .foregroundColor(Colors.Icon.accent)
                    .hidden(!viewModel.isSelected(currency))
            }
            .lineLimit(1)
            .contentShape(Rectangle())
        }
    }

    private func filter(currencies: [CurrenciesResponse.Currency]) -> [CurrenciesResponse.Currency] {
        let text = searchText.trimmed()

        let sortindPredicate: (CurrenciesResponse.Currency, CurrenciesResponse.Currency) -> Bool = { first, _ in
            viewModel.isSelected(first)
        }

        if text.isEmpty {
            return currencies.sorted(by: sortindPredicate)
        }

        return currencies
            .filter {
                $0.description.localizedStandardContains(text)
            }
            .sorted(by: sortindPredicate)
    }
}

struct CurrencySelectView_Preview: PreviewProvider {
    class CurrencySelectRoutableMock: CurrencySelectRoutable {
        func dismissCurrencySelect() {}
    }

    static var previews: some View {
        NavigationView {
            CurrencySelectView(
                viewModel: CurrencySelectViewModel(
                    coordinator: CurrencySelectRoutableMock()
                )
            )
        }
    }
}
