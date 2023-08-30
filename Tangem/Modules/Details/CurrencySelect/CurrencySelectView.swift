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
    @Environment(\.presentationMode) var presentationMode

    @State private var searchText: String = ""

    var body: some View {
        VStack {
            if viewModel.loading {
                ActivityIndicatorView(isAnimating: true, style: .medium, color: .tangemGrayDark)
            } else {
                VStack {
                    SearchBar(text: $searchText, placeholder: Localization.commonSearch)
                    List {
                        ForEach(
                            viewModel.currencies.filter {
                                searchText.isEmpty ||
                                    $0.description.localizedStandardContains(searchText)
                            }) { currency in
                                HStack {
                                    Text(currency.description)
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                        .foregroundColor(.tangemGrayDark6)
                                    Spacer()
                                    if viewModel.isSelected(currency) {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 18, weight: .regular, design: .default))
                                            .foregroundColor(Colors.Icon.accent)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.onSelect(currency)
                                    if viewModel.dismissAfterSelection {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                                .id(currency.id)
                            }
                    }
                }
                .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
            }
        }
        .navigationBarTitle(Text(Localization.detailsRowTitleCurrency), displayMode: .inline)
        .onAppear {
            viewModel.onAppear()
        }
        .alert(item: $viewModel.error) { $0.alert }
    }
}
