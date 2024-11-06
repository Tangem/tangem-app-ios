//
//  ActionButtonsBuyInteractor.swift
//  TangemApp
//
//  Created by GuitarKitty on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsBuyInteractor {
    func makeBuyUrl(from token: ActionButtonsTokenSelectorItem) -> URL?
}
