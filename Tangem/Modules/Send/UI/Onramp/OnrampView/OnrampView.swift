//
//  OnrampView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 15.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampView: View {
    @ObservedObject var viewModel: OnrampViewModel

    var body: some View {
        GroupedScrollView(spacing: 14) {
            OnrampAmountView(viewModel: viewModel.onrampAmountViewModel)
        }
    }
}
