//
//  MultipleRewardsView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MultipleRewardsView: View {
    @ObservedObject var viewModel: MultipleRewardsViewModel

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: 14) {
            GroupedSection(viewModel.validators) { data in
                ValidatorView(data: data)
            }
            .interItemSpacing(0)
            .innerContentPadding(0)
        }
    }
}
