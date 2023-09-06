//
//  AppSettingsRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol AppSettingsRoutable: AnyObject {
    func openTokenSynchronization()
    func openResetSavedCards()
    func openAppSettings()
    func openCurrencySelection()
}
