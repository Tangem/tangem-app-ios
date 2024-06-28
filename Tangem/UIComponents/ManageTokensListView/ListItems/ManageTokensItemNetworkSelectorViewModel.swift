//
//  ManageTokensItemNetworkSelectorViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 21/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class ManageTokensItemNetworkSelectorViewModel: Identifiable, ObservableObject {
    @Published var isSelected: Bool

    let id: UUID = .init()
    let tokenItem: TokenItem
    let isReadonly: Bool
    let position: ItemPosition
    let isCopied: Binding<Bool>
    let isMain: Bool
    let imageName: String
    let imageNameSelected: String
    let networkName: String
    let contractName: String?
    let hasContextMenu: Bool
    let contractNameForegroundColor: Color

    var networkNameForegroundColor: Color { isSelected ? Colors.Text.primary1 : Colors.Text.secondary }

    private var isSelectedBinding: Binding<Bool>
    private var bag = Set<AnyCancellable>()

    init(tokenItem: TokenItem, isReadonly: Bool, isSelected: Binding<Bool>, isCopied: Binding<Bool> = .constant(false), position: ItemPosition = .middle) {
        self.tokenItem = tokenItem
        self.isReadonly = isReadonly
        isSelectedBinding = isSelected
        self.isCopied = isCopied
        self.position = position
        isMain = tokenItem.isBlockchain
        imageName = tokenItem.blockchain.iconName
        imageNameSelected = tokenItem.blockchain.iconNameFilled
        networkName = tokenItem.blockchain.displayName
        contractName = tokenItem.contractName
        hasContextMenu = tokenItem.isToken
        contractNameForegroundColor = tokenItem.isBlockchain ? Colors.Text.accent : Colors.Text.tertiary

        self.isSelected = isSelected.wrappedValue

        $isSelected
            .dropFirst()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { viewModel, value in
                viewModel.isSelectedBinding.wrappedValue = value
            })
            .store(in: &bag)
    }

    func updateSelection(with isSelected: Binding<Bool>) {
        isSelectedBinding = isSelected
        self.isSelected = isSelected.wrappedValue
    }

    func onCopy() {
        if isReadonly { return }

        if let contractAddress = tokenItem.contractAddress {
            UIPasteboard.general.string = contractAddress
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            isCopied.wrappedValue = true
        }
    }
}

extension ManageTokensItemNetworkSelectorViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ManageTokensItemNetworkSelectorViewModel, rhs: ManageTokensItemNetworkSelectorViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
