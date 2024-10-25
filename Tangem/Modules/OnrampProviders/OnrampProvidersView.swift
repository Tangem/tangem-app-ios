//
//  OnrampProvidersView.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProvidersView: View {
    @ObservedObject private var viewModel: OnrampProvidersViewModel

    init(viewModel: OnrampProvidersViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            headerView

            GroupedScrollView(spacing: 0) {
                providersSection
            }
        }
        .background(Colors.Background.primary)
    }

    private var headerView: some View {
        BottomSheetHeaderView(
            title: Localization.expressChooseProvidersTitle,
            subtitle: Localization.expressChooseProvidersSubtitle
        )
        .padding(.top, 20)
        .padding(.horizontal, 16)
    }

    private var providersSection: some View {
        ForEach(viewModel.providers) {
            OnrampProviderRowView(data: $0)

            Separator(height: .minimal, color: Colors.Stroke.primary)
        }
    }
}

struct OnrampProvidersView_Preview: PreviewProvider {
    static let viewModel = OnrampProvidersViewModel(coordinator: OnrampProvidersCoordinator())

    static var previews: some View {
        OnrampProvidersView(viewModel: viewModel)
    }
}
