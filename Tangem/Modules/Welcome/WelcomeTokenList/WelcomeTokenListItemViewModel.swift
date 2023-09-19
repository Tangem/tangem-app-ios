//
//  WelcomeTokenListItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class WelcomeTokenListItemViewModel: Identifiable, ObservableObject {
    let id: UUID = .init()
    let tokenItem: TokenItem
    var isSelected: Binding<Bool>?
    let position: ItemPosition

    @Published var selectedPublisher: Bool

    var isMain: Bool { tokenItem.isBlockchain }
    var imageName: String { tokenItem.blockchain.iconName }
    var imageNameSelected: String { tokenItem.blockchain.iconNameFilled }
    var networkName: String { tokenItem.blockchain.displayName }
    var contractName: String? { tokenItem.contractName }
    var networkNameForegroundColor: Color { selectedPublisher ? .tangemGrayDark6 : Color(name: "manage_tokens_network_name") }
    var contractNameForegroundColor: Color { tokenItem.isBlockchain ? Colors.Text.accent : Color(name: "manage_tokens_contract_name") }

    private var bag = Set<AnyCancellable>()

    init(tokenItem: TokenItem, isSelected: Binding<Bool>?, position: ItemPosition = .middle) {
        self.tokenItem = tokenItem
        self.isSelected = isSelected
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
}

extension WelcomeTokenListItemViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WelcomeTokenListItemViewModel, rhs: WelcomeTokenListItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
