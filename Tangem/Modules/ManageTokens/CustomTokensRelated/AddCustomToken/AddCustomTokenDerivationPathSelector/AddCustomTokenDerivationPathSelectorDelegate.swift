//
//  AddCustomTokenDerivationPathSelectorDelegate.swift
//  Tangem
//
//  Created by Andrey Chukavin on 19.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol AddCustomTokenDerivationPathSelectorDelegate: AnyObject {
    func didSelectOption(_ derivationOption: AddCustomTokenDerivationOption)
}
