//
//  LegacyCoinItemViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class LegacyCoinItemViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()
    let tokenItem: TokenItem
    let isReadonly: Bool
    var isSelected: Binding<Bool>?
    let position: ItemPosition
    let isCopied: Binding<Bool>

    @Published var selectedPublisher: Bool

    var isMain: Bool { tokenItem.isBlockchain }
    var imageName: String { tokenItem.blockchain.iconName }
    var imageNameSelected: String { tokenItem.blockchain.iconNameFilled }
    var networkName: String { tokenItem.blockchain.displayName }
    var contractName: String? { tokenItem.contractName }
    var networkNameForegroundColor: Color { selectedPublisher ? .tangemGrayDark6 : Color(name: "manage_tokens_network_name") }
    var contractNameForegroundColor: Color { tokenItem.isBlockchain ? Colors.Text.accent : Color(name: "manage_tokens_contract_name") }
    var hasContextMenu: Bool { tokenItem.isToken }

    private var bag = Set<AnyCancellable>()

    init(tokenItem: TokenItem, isReadonly: Bool, isSelected: Binding<Bool>?, isCopied: Binding<Bool> = .constant(false), position: ItemPosition = .middle) {
        self.tokenItem = tokenItem
        self.isReadonly = isReadonly
        self.isSelected = isSelected
        self.isCopied = isCopied
        self.position = position

        selectedPublisher = isSelected?.wrappedValue ?? false

        $selectedPublisher
            .dropFirst()
            .sink(receiveValue: { [unowned self] value in
                self.isSelected?.wrappedValue = value
            })
            .store(in: &bag)
    }

    func updateSelection(with isSelected: Binding<Bool>) {
        self.isSelected = isSelected
        selectedPublisher = isSelected.wrappedValue
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

extension LegacyCoinItemViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LegacyCoinItemViewModel, rhs: LegacyCoinItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
