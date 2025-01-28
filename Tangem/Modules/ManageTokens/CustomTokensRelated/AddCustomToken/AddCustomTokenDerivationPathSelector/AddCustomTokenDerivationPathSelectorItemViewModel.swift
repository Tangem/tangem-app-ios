//
//  AddCustomTokenDerivationPathSelectorItemViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class AddCustomTokenDerivationPathSelectorItemViewModel: ObservableObject {
    var id: String {
        option.id
    }

    var name: String {
        option.name
    }

    var derivationPath: String? {
        option.rawDerivationDath
    }

    @Published var isSelected: Bool
    @Published private(set) var option: AddCustomTokenDerivationOption

    private let didTapOption: (AddCustomTokenDerivationOption) -> Void

    init(option: AddCustomTokenDerivationOption, isSelected: Bool, didTapOption: @escaping (AddCustomTokenDerivationOption) -> Void) {
        self.isSelected = isSelected
        self.option = option
        self.didTapOption = didTapOption
    }

    func setCustomDerivationPath(_ enteredText: String) {
        do {
            option = .custom(derivationPath: try DerivationPath(rawPath: enteredText))
        } catch {
            AppLog.error(error: error)
            assertionFailure("You should validate entered derivation path")
        }
    }

    func didTap() {
        didTapOption(option)
    }
}
