//
//  CardOperationView.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CardOperationView: View {
    @ObservedObject var viewModel: CardOperationViewModel

    var body: some View {
        VStack(spacing: .zero) {
            Spacer()

            content

            Spacer()

            MainButton(
                title: viewModel.buttonTitle,
                isLoading: viewModel.isLoading,
                action: viewModel.onTap
            )
        }
        .padding([.horizontal, .bottom], 16)
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationBarTitle(viewModel.title)
        .alert(item: $viewModel.error) { $0.alert }
    }

    private var content: some View {
        VStack(spacing: 28) {
            Image(systemName: "exclamationmark.circle")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(Colors.Icon.attention)

            Text(Localization.commonWarning.uppercased())
                .style(Fonts.Regular.largeTitle, color: Colors.Icon.attention)

            Text(viewModel.alert)
                .style(Fonts.Regular.title2, color: Colors.Text.primary1)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 30)
    }
}

struct CardOperationVIew_Previews: PreviewProvider {
    static var previews: some View {
        CardOperationView(viewModel: .init(
            title: "Manage",
            alert: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Et quis vitae dictumst consequat.",
            actionButtonPressed: { _ in },
            coordinator: SecurityModeCoordinator()
        ))
    }
}
