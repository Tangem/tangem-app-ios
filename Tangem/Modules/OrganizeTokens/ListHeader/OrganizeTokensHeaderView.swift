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

    @Environment(\.colorScheme) private var colorScheme

    private var buttonShadowOpacity: CGFloat {
        return colorScheme == .light ? Constants.lightModeButtonShadowOpacity : Constants.darkModeButtonShadowOpacity
    }

    var body: some View {
        HStack(spacing: 8.0) {
            Group {
                FlexySizeButtonWithLeadingIcon(
                    title: viewModel.sortByBalanceButtonTitle,
                    icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                    isToggled: viewModel.isSortByBalanceEnabled,
                    action: viewModel.toggleSortState
                )
                .shadow(color: Colors.Icon.inactive.opacity(sortByBalanceButtonShadowOpacity), radius: 4.0)

                FlexySizeButtonWithLeadingIcon(
                    title: viewModel.groupingButtonTitle,
                    icon: Assets.OrganizeTokens.makeGroupIcon.image,
                    action: viewModel.toggleGroupState
                )
                .shadow(color: Colors.Icon.inactive.opacity(groupingButtonShadowOpacity), radius: 4.0)
            }
            .background(
                Colors.Background
                    .primary
                    .cornerRadiusContinuous(10.0)
            )
            .onAppear(perform: viewModel.onViewAppear)
        }
    }

    private var sortByBalanceButtonShadowOpacity: CGFloat {
        return buttonShadowOpacity / (viewModel.isSortByBalanceEnabled ? 3.0 : 1.0)
    }

    private var groupingButtonShadowOpacity: CGFloat {
        return buttonShadowOpacity
    }
}

// MARK: - Constants

private extension OrganizeTokensHeaderView {
    enum Constants {
        static let lightModeButtonShadowOpacity = 0.37
        static let darkModeButtonShadowOpacity = 0.57
    }
}

// MARK: - Previews

struct OrganizeTokensHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let optionsManager = OrganizeTokensOptionsManagerStub()
        let viewModel = OrganizeTokensHeaderViewModel(
            optionsProviding: optionsManager,
            optionsEditing: optionsManager
        )
        return OrganizeTokensHeaderView(viewModel: viewModel)
    }
}
