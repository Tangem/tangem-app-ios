//
//  OnrampCountryView.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampCountryView: View {
    @ObservedObject private var viewModel: OnrampCountryViewModel

    init(viewModel: OnrampCountryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 24) {
            BottomSheetHeaderView(title: "Your residence has been identified as")

            contentView

            buttons
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
    }

    private var contentView: some View {
        VStack(spacing: 12) {
            IconView(url: viewModel.iconURL, size: CGSize(width: 36, height: 36), forceKingfisher: true)

            VStack(spacing: 6) {
                Text(viewModel.title)
                    .style(Fonts.Bold.callout, color: Colors.Text.primary1)

                switch viewModel.subtitle {
                case .info:
                    Text("Change or confirm it")
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                case .notSupport:
                    Text("Our services are not available in this country")
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            MainButton(
                title: "Change",
                style: .secondary,
                action: viewModel.didTapChangeButton
            )

            MainButton(
                title: viewModel.mainButtonTitle,
                action: viewModel.didTapMainButton
            )
        }
    }
}

struct OnrampCountryView_Preview: PreviewProvider {
    struct StatableContainer: View {
        @ObservedObject private var coordinator = BottomSheetCoordinator()

        var body: some View {
            ZStack {
                Colors.Background.primary
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
                    coordinator.toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $coordinator.item, backgroundColor: Colors.Background.tertiary) {
                        OnrampCountryView(viewModel: $0)
                    }
            }
        }
    }

    class BottomSheetCoordinator: ObservableObject, OnrampCountryRoutable {
        @Published var item: OnrampCountryViewModel?

        func toggleItem() {
            if item == nil {
                item = .init(
                    settings: .init(countryIconURL: nil, countryName: "Portugal", isOnrampSupported: true),
                    coordinator: self
                )
            } else {
                item = nil
            }
        }

        func userDidTapChangeCountry() {
            item = nil
        }

        func userDidTapConfirmCountry() {
            item = nil
        }
    }

    static var previews: some View {
        StatableContainer()
            .preferredColorScheme(.light)

        StatableContainer()
            .preferredColorScheme(.dark)
    }
}
