//
//  OrganizeTokensHeaderView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensHeaderView: View {
    @ObservedObject var viewModel: OrganizeTokensHeaderViewModel

    var body: some View {
        HStack(spacing: 8.0) {
            Group {
                FlexySizeButtonWithLeadingIcon(
                    title: viewModel.sortByBalanceButtonTitle,
                    icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                    isSelected: viewModel.isSortByBalanceEnabled,
                    action: viewModel.toggleSortState
                )

                FlexySizeButtonWithLeadingIcon(
                    title: viewModel.groupingButtonTitle,
                    icon: Assets.OrganizeTokens.makeGroupIcon.image,
                    isSelected: true,
                    action: viewModel.toggleGroupState
                )
            }
            .shadow(color: Colors.Button.primary.opacity(0.1), radius: 5.0) // TODO: Andrey Fedorov - Use correct color
            .background(
                Colors.Background
                    .primary
                    .cornerRadiusContinuous(10.0)
            )
        }
    }
}

// MARK: - Previews

struct OrganizeTokensHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        OrganizeTokensHeaderView(
            viewModel: .init()
        )
    }
}
