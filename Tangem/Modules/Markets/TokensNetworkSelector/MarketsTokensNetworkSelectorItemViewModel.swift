//
//  MarketsTokensNetworkSelectorItemViewModel.swift
//  Tangem
//
//  Created by Skibin Alexander on 13.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class MarketsTokensNetworkSelectorItemViewModel: Identifiable, ObservableObject {
    @Published var isSelected: Bool = false

    let id: UUID = .init()

    let tokenItem: TokenItem
    let position: ItemPosition
    let isMain: Bool
    let networkName: String
    let contractName: String?

    var isReadonly: Bool

    var networkNameForegroundColor: Color {
        guard !isReadonly else {
            return Colors.Text.disabled
        }

        return isSelected ? Colors.Text.primary1 : Colors.Text.secondary
    }

    var contractNameForegroundColor: Color {
        guard !isReadonly else {
            return Colors.Text.disabled
        }

        return tokenItem.isBlockchain ? Colors.Text.accent : Colors.Text.tertiary
    }

    var checkedImage: Image {
        guard !isReadonly else {
            return Assets.Checked.disabled.image
        }

        return isSelected ? Assets.Checked.on.image : Assets.Checked.off.image
    }

    var iconImageName: String {
        guard !isReadonly else {
            return imageName
        }

        return isSelected ? imageNameSelected : imageName
    }

    private var isSelectedBinding: Binding<Bool>
    private var bag = Set<AnyCancellable>()

    private let imageName: String
    private let imageNameSelected: String

    // MARK: - Init

    init(tokenItem: TokenItem, isReadonly: Bool, isSelected: Binding<Bool>, position: ItemPosition = .middle) {
        self.tokenItem = tokenItem
        self.isReadonly = isReadonly
        isSelectedBinding = isSelected
        self.position = position
        isMain = tokenItem.isBlockchain
        imageName = tokenItem.blockchain.iconName
        imageNameSelected = tokenItem.blockchain.iconNameFilled
        networkName = tokenItem.blockchain.displayName
        contractName = tokenItem.contractName

        self.isSelected = isSelected.wrappedValue

        $isSelected
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, value in
                viewModel.isSelectedBinding.wrappedValue = value
            })
            .store(in: &bag)
    }

    func updateSelection(with isSelected: Binding<Bool>, isReadonly: Bool) {
        isSelectedBinding = isSelected
        self.isReadonly = isReadonly
        self.isSelected = isSelected.wrappedValue
    }
}
