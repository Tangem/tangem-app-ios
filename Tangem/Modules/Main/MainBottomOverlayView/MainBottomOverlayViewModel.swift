//
//  MainBottomOverlayViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct MainBottomOverlayViewModel {
    let isButtonDisabled: Bool
    let buttonTitle: String
    let buttonAction: () -> Void
}
