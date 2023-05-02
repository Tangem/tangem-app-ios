//
//  TangemSdkFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 07.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol TangemSdkFactory {
    func makeTangemSdk() -> TangemSdk
}
