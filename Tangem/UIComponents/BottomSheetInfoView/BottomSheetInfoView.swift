//
//  BottomSheetInfoView.swift
//  Tangem
//
//  Created by skibinalexander on 04.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

public struct BottomSheetInfoView: View {
    // MARK: - Properties

    public let viewModel: BottomSheetInfoViewModel

    // MARK: - SetupUI

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 44)

            viewModel.icon.image
                .frame(width: 40, height: 40)

            Spacer(minLength: 28)

            VStack(spacing: 10) {
                Text(viewModel.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                if let description = viewModel.description {
                    Text(description)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 40)

            if let buttonTitle = viewModel.buttonTitle {
                MainButton(
                    title: buttonTitle,
                    style: .secondary,
                    action: viewModel.buttonTapAction ?? {}
                )
                .disabled(viewModel.buttonTapAction == nil)
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Previews

struct BottomSheetInfoView_Previews: PreviewProvider {
    struct StatableContainer: View {
        @State private var item: BottomSheetInfoViewModel?

        var body: some View {
            ZStack {
                Button("Bottom sheet isShowing \((item != nil).description)") {
                    toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $item, backgroundColor: Colors.Background.tertiary) {
                        BottomSheetInfoView(viewModel: $0)
                    }
            }
        }

        func toggleItem() {
            let isShowing = item != nil

            if !isShowing {
                item = BottomSheetInfoViewModel(
                    input: .init(
                        icon: Assets.attention,
                        title: "Backup your card",
                        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                        buttonTitle: "test"
                    ),
                    buttonTapAction: nil
                )
            } else {
                item = nil
            }
        }
    }

    static var previews: some View {
        StatableContainer()
    }
}
