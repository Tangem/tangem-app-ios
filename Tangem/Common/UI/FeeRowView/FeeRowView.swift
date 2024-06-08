//
//  ExpressFeeRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeeRowView: View {
    let viewModel: FeeRowViewModel

    private var namespace: Namespace.ID?
    private var optionNamespaceId: String?
    private var amountNamespaceId: String?

    private let regularFont = Fonts.Regular.subheadline
    private let boldFont = Fonts.Bold.subheadline

    init(viewModel: FeeRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.isSelected.toggle) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    viewModel.option.icon.image
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .foregroundColor(iconColor)

                    Text(viewModel.option.title)
                        .style(font, color: Colors.Text.primary1)
                }
                .matchedGeometryEffectOptional(id: optionNamespaceId, in: namespace)

                Spacer()

                if let cryptoAmount = viewModel.cryptoAmount {
                    feeAmount(cryptoAmount: cryptoAmount, fiatAmount: viewModel.fiatAmount)
                        .frame(minWidth: viewModel.isLoading ? 70 : 0)
                        .skeletonable(isShown: viewModel.isLoading)
                        .matchedGeometryEffectOptional(id: amountNamespaceId, in: namespace)
                }
            }
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func feeAmount(cryptoAmount: String, fiatAmount: String?) -> some View {
        HStack(spacing: 4) {
            Text(cryptoAmount)
                .style(font, color: Colors.Text.primary1)
                .lineLimit(1)
                .layoutPriority(1)

            if let fiatAmount {
                Text("•")
                    .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                    .layoutPriority(3)

                Text(fiatAmount)
                    .style(regularFont, color: Colors.Text.tertiary)
                    .lineLimit(1)
                    .layoutPriority(2)
            }
        }
    }

    private var iconColor: Color {
        viewModel.isSelected.value ? Colors.Icon.accent : Colors.Icon.informative
    }

    private var font: Font {
        viewModel.isSelected.value ? boldFont : regularFont
    }
}

extension FeeRowView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }

    func setOptionNamespaceId(_ optionNamespaceId: String?) -> Self {
        map { $0.optionNamespaceId = optionNamespaceId }
    }

    func setAmountNamespaceId(_ amountNamespaceId: String?) -> Self {
        map { $0.amountNamespaceId = amountNamespaceId }
    }
}

struct ExpressFeeRowView_Preview: PreviewProvider {
    struct ContentView: View {
        @State private var option: FeeOption = .market

        private var viewModels: [FeeRowViewModel] {
            [
                FeeRowViewModel(
                    option: .slow,
                    formattedFeeComponents: .loaded(.init(cryptoFee: "0.359817123123123123123 MATIC", fiatFee: "123123123123120.22 $")),
                    isSelected: .init(get: { option == .slow }, set: { _ in option = .slow })
                ),
                FeeRowViewModel(
                    option: .market,
                    formattedFeeComponents: .loaded(.init(cryptoFee: "0.159817 MATIC", fiatFee: "0.22 $")),
                    isSelected: .init(get: { option == .market }, set: { _ in option = .market })
                ),
                FeeRowViewModel(
                    option: .fast,
                    formattedFeeComponents: .loaded(.init(cryptoFee: "0.159817 MATIC", fiatFee: "0.22 $")),
                    isSelected: .init(get: { option == .fast }, set: { _ in option = .fast })
                ),
            ]
        }

        private var viewModels2: [FeeRowViewModel] {
            [
                FeeRowViewModel(
                    option: .slow,
                    formattedFeeComponents: .loaded(.init(cryptoFee: "0.359817123123123123123 MATIC", fiatFee: "123123123123120.22 $")),
                    isSelected: .init(get: { option == .slow }, set: { _ in option = .slow })
                ),
                FeeRowViewModel(
                    option: .market,
                    formattedFeeComponents: .loaded(.init(cryptoFee: "0.159812312312312317 MATIC", fiatFee: "0.22 $")),
                    isSelected: .init(get: { option == .market }, set: { _ in option = .market })
                ),
                FeeRowViewModel(
                    option: .fast,
                    formattedFeeComponents: .loaded(.init(cryptoFee: "0.159817 MATIC", fiatFee: "123123123123120.22 $")),
                    isSelected: .init(get: { option == .fast }, set: { _ in option = .fast })
                ),
            ]
        }

        private var viewModels3: [FeeRowViewModel] {
            [
                FeeRowViewModel(
                    option: .slow,
                    formattedFeeComponents: .loaded(.init(cryptoFee: "0.35981712312312312313 MATIC", fiatFee: "123123123123120.22 $")),
                    isSelected: .init(get: { option == .slow }, set: { _ in option = .slow })
                ),
                FeeRowViewModel(
                    option: .market,
                    formattedFeeComponents: .loading,
                    isSelected: .init(get: { option == .market }, set: { _ in option = .market })
                ),
                FeeRowViewModel(
                    option: .fast,
                    formattedFeeComponents: .failedToLoad(error: ExpressFeeProviderError.feeNotFound),
                    isSelected: .init(get: { option == .fast }, set: { _ in option = .fast })
                ),
            ]
        }

        var body: some View {
            GroupedScrollView(spacing: 14) {
                GroupedSection(viewModels) {
                    FeeRowView(viewModel: $0)
                }

                GroupedSection(viewModels2) {
                    FeeRowView(viewModel: $0)
                }

                GroupedSection(viewModels3) {
                    FeeRowView(viewModel: $0)
                }
            }
            .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        }
    }

    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)

        ContentView()
            .preferredColorScheme(.dark)
    }
}
