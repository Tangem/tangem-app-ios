//
//  OrganizeTokensOptions.swift
//  Tangem
//
//  Created by Andrey Fedorov on 04.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum OrganizeTokensOptions {
    enum Grouping {
        case none
        case byBlockchainNetwork
    }

    enum Sorting {
        case dragAndDrop
        case byBalance
    }
}
