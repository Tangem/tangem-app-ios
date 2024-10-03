//
//  ScanCardSettingsRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ScanCardSettingsRoutable: AnyObject {
    func openCardSettings(with input: CardSettingsViewModel.Input)
}
