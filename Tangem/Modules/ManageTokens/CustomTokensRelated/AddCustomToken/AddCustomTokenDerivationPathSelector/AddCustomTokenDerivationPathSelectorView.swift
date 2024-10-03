//
//  AddCustomTokenDerivationPathSelectorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct AddCustomTokenDerivationPathSelectorView: View {
    @ObservedObject private var viewModel: AddCustomTokenDerivationPathSelectorViewModel

    init(viewModel: AddCustomTokenDerivationPathSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                section(for: [viewModel.customDerivationModel])

                section(for: viewModel.blockchainDerivationModels)
            }
            .padding(.horizontal, 16)
        }
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Text(Localization.customTokenDerivationPath))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(for viewModels: [AddCustomTokenDerivationPathSelectorItemViewModel]) -> some View {
        VStack(spacing: 0) {
            ForEach(viewModels, id: \.id) { viewModel in
                AddCustomTokenDerivationPathSelectorItemView(viewModel: viewModel)

                if viewModels.last?.id != viewModel.id {
                    Separator(height: .minimal, color: Colors.Stroke.primary)
                        .padding(.leading, 16)
                }
            }
        }
        .background(Colors.Background.action)
        .cornerRadiusContinuous(14)
    }
}

struct AddCustomTokenDerivationPathSelectorView_Preview: PreviewProvider {
    static let viewModel = AddCustomTokenDerivationPathSelectorViewModel(
        selectedDerivationOption: .custom(derivationPath: nil),
        defaultDerivationPath: try! DerivationPath(rawPath: "m/44’/0’/0’/0’/0’"),
        blockchainDerivationOptions: SupportedBlockchains.all.map {
            AddCustomTokenDerivationOption.blockchain(
                name: $0.displayName,
                derivationPath: $0.derivationPath(for: .v1) ?? (try! DerivationPath(rawPath: "m/44’/0’/0’/0’/0’"))
            )
        }
    )

    static var previews: some View {
        AddCustomTokenDerivationPathSelectorView(viewModel: viewModel)
    }
}
