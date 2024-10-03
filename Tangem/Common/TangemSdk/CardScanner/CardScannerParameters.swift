//
//  CardScannerParameters.swift
//  Tangem
//
//  Created by Alexander Osokin on 12.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardScannerParameters {
    let shouldAskForAccessCodes: Bool
    let performDerivations: Bool
    let sessionFilter: SessionFilter?
}
