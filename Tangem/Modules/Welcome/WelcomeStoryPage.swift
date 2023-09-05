//
//  WelcomeStoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 18.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum WelcomeStoryPage: CaseIterable {
    case learn
    case meetTangem
    case awe
    case backup
    case currencies
    // case web3
    case finish

    var colorScheme: ColorScheme {
        .dark
    }

    var duration: Double {
        switch self {
        case .learn, .meetTangem:
            return 8
        default:
            return 6
        }
    }
}
