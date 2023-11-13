//
//  InformationHiddenBalancesRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol InformationHiddenBalancesRoutable: AnyObject {
    func hiddenBalancesSheetDidRequestClose()
    func hiddenBalancesSheetDidRequestDoNotShowAgain()
}
