//
//  OnrampPaymentMethodsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampPaymentMethodsView: View {
    @ObservedObject var viewModel: OnrampPaymentMethodsViewModel

    var body: some View {
        GroupedScrollView(spacing: 0) {
            ForEach(viewModel.paymentMethods) { paymentMethod in
                OnrampPaymentMethodRowView(data: paymentMethod)

                if paymentMethod.id != viewModel.paymentMethods.last?.id {
                    Separator(height: .minimal, color: Colors.Stroke.primary)
                        .padding(.leading, 62)
                }
            }
        }
        .background(Colors.Background.primary)
        .navigationTitle(Text(Localization.onrampPayWith))
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear(perform: viewModel.onAppear)
    }
}
