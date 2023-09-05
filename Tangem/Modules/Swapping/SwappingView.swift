//
//  SwappingView.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingView: View {
    @ObservedObject private var viewModel: SwappingViewModel

    init(viewModel: SwappingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

            logo1inch

            GroupedScrollView(spacing: 14) {
                swappingViews

                permissionInfoSection

                warningSections

                informationSection

                mainButton
            }
            .scrollDismissesKeyboardCompat(true)
            // For animate button below informationSection
            .animation(.easeInOut, value: viewModel.informationSectionViewModels.count)
        }
        .navigationBarTitle(Text(Localization.commonSwap), displayMode: .inline)
        .alert(item: $viewModel.errorAlert, content: { $0.alert })
    }

    @ViewBuilder
    private var swappingViews: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 14) {
                if let sendCurrencyViewModel = viewModel.sendCurrencyViewModel {
                    SendCurrencyView(
                        viewModel: sendCurrencyViewModel,
                        decimalValue: $viewModel.sendDecimalValue
                    )
                    .didTapMaxAmount(viewModel.userDidTapMaxAmount)
                    .didTapChangeCurrency {
                        viewModel.userDidTapChangeCurrencyButton()
                    }
                }

                if let receiveCurrencyViewModel = viewModel.receiveCurrencyViewModel {
                    ReceiveCurrencyView(viewModel: receiveCurrencyViewModel)
                        .didTapChangeCurrency {
                            viewModel.userDidTapChangeDestinationButton()
                        }
                }
            }

            swappingButton
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var swappingButton: some View {
        Group {
            if viewModel.swapButtonIsLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
            } else {
                Button(action: viewModel.userDidTapSwapSwappingItemsButton) {
                    Assets.swappingIcon.image
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Colors.Icon.primary1)
                }
            }
        }
        .frame(width: 44, height: 44)
        .background(Colors.Background.primary)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Colors.Stroke.primary, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var permissionInfoSection: some View {
        GroupedSection(viewModel.permissionInfoRowViewModel) {
            DefaultWarningRow(viewModel: $0)
        }
        .verticalPadding(0)
    }

    @ViewBuilder
    private var warningSections: some View {
        GroupedSection(viewModel.highPriceImpactWarningRowViewModel) {
            DefaultWarningRow(viewModel: $0)
        }
        .verticalPadding(0)

        GroupedSection(viewModel.refreshWarningRowViewModel) {
            DefaultWarningRow(viewModel: $0)
        }
        .verticalPadding(0)
    }

    @ViewBuilder
    private var informationSection: some View {
        GroupedSection(viewModel.informationSectionViewModels) { item in
            switch item {
            case .fee(let viewModel):
                SwappingFeeRowView(viewModel: viewModel)
            case .warning(let viewModel):
                DefaultWarningRow(viewModel: viewModel)
            case .feePolicy(let viewModel):
                SelectableSwappingFeeRowView(viewModel: viewModel)
            }
        }
        .verticalPadding(0)
    }

    @ViewBuilder
    private var mainButton: some View {
        MainButton(
            title: viewModel.mainButtonState.title,
            icon: viewModel.mainButtonState.icon,
            isDisabled: !viewModel.mainButtonIsEnabled,
            action: viewModel.didTapMainButton
        )
    }

    @ViewBuilder
    private var logo1inch: some View {
        VStack(spacing: 0) {
            Spacer()

            Assets.logo1inch.image
        }
        .padding(.bottom, UIApplication.safeAreaInsets.bottom + 10)
        .edgesIgnoringSafeArea(.bottom)
        .ignoresSafeArea(.keyboard)
    }
}

struct SwappingView_Preview: PreviewProvider {
    static let viewModel = SwappingViewModel(
        initialSourceCurrency: .mock,
        swappingInteractor: .init(
            swappingManager: SwappingManagerMock(),
            userTokensManager: UserTokensManagerMock(),
            currencyMapper: CurrencyMapper(),
            blockchainNetwork: PreviewCard.ethereum.blockchainNetwork!
        ),
        swappingDestinationService: SwappingDestinationServiceMock(),
        tokenIconURLBuilder: TokenIconURLBuilder(),
        transactionSender: TransactionSenderMock(),
        fiatRatesProvider: FiatRatesProviderMock(),
        swappingFeeFormatter: SwappingFeeFormatterMock(),
        coordinator: SwappingCoordinator()
    )

    static var previews: some View {
        NavigationView {
            SwappingView(viewModel: viewModel)
        }
    }
}
