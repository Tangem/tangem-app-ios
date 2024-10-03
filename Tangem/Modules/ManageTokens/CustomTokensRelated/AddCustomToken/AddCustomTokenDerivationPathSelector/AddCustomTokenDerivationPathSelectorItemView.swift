//
//  AddCustomTokenDerivationPathSelectorItemView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenDerivationPathSelectorItemView: View {
    @ObservedObject var viewModel: AddCustomTokenDerivationPathSelectorItemViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.name)
                    .lineLimit(1)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)

                if let derivationPath = viewModel.derivationPath {
                    Text(derivationPath)
                        .lineLimit(1)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }

            Spacer()

            if viewModel.isSelected {
                Assets.check.image
                    .frame(width: 20, height: 20)
                    .foregroundColor(Colors.Icon.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTap()
        }
    }
}

struct AddCustomTokenDerivationPathSelectorItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 14) {
            Group {
                AddCustomTokenDerivationPathSelectorItemView(viewModel: .init(option: .custom(derivationPath: nil), isSelected: true, didTapOption: { _ in }))

                VStack(spacing: 0) {
                    AddCustomTokenDerivationPathSelectorItemView(viewModel: .init(option: .custom(derivationPath: try! .init(rawPath: "m/44’/0’/0")), isSelected: false, didTapOption: { _ in }))

                    AddCustomTokenDerivationPathSelectorItemView(viewModel: .init(option: .default(derivationPath: try! .init(rawPath: "m/44’/0’/0’/0’/0’")), isSelected: true, didTapOption: { _ in }))

                    AddCustomTokenDerivationPathSelectorItemView(viewModel: .init(option: .blockchain(name: "Ethereum", derivationPath: try! .init(rawPath: "m/44’/643’/0’/0’/0’")), isSelected: false, didTapOption: { _ in }))

                    AddCustomTokenDerivationPathSelectorItemView(viewModel: .init(option: .blockchain(name: "Bitcoin", derivationPath: try! .init(rawPath: "m/44’/643’/0’/0’/0’")), isSelected: false, didTapOption: { _ in }))
                }

                AddCustomTokenDerivationPathSelectorItemView(viewModel: .init(option: .blockchain(name: "Bitcoin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin coin", derivationPath: try! .init(rawPath: "m/44’/643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’643’/0’/0’/0’")), isSelected: true, didTapOption: { _ in }))
            }
            .cornerRadiusContinuous(14)
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .background(Colors.Background.tertiary.ignoresSafeArea())
    }
}
