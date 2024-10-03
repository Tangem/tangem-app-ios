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
                    isToggled: viewModel.isSortByBalanceEnabled,
                    action: viewModel.toggleSortState
                )

                FlexySizeButtonWithLeadingIcon(
                    title: viewModel.groupingButtonTitle,
                    icon: Assets.OrganizeTokens.makeGroupIcon.image,
                    action: viewModel.toggleGroupState
                )
            }
            .background(
                Colors.Background
                    .primary
                    .opacity(0.5)
                    .cornerRadiusContinuous(10.0)
            )
            .onAppear(perform: viewModel.onViewAppear)
        }
    }
}

// MARK: - Previews

struct OrganizeTokensHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let optionsManager = FakeOrganizeTokensOptionsManager(
            initialGroupingOption: .none,
            initialSortingOption: .dragAndDrop
        )
        let viewModel = OrganizeTokensHeaderViewModel(
            optionsProviding: optionsManager,
            optionsEditing: optionsManager
        )
        return OrganizeTokensHeaderView(viewModel: viewModel)
    }
}
