//
//  SafariConfiguration.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SafariConfiguration {
    var dismissButtonStyle: DismissButtonStyle = .close
}

extension SafariConfiguration {
    enum DismissButtonStyle {
        case done
        case close
        case cancel
    }
}
