//
//  OnrampPaymentMethodsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampPaymentMethodsView: View {
    @ObservedObject private var viewModel: OnrampPaymentMethodsViewModel

    init(viewModel: OnrampPaymentMethodsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(spacing: 0) {
            ForEach(viewModel.paymentMethods) {
                OnrampPaymentMethodRowView(data: $0)

                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .padding(.leading, 62)
            }
        }
        .background(Colors.Background.primary)
        .navigationTitle(Text(Localization.onrampPayWith))
    }
}
