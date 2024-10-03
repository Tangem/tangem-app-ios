//
//  KeysDerivingProvider.swift
//  Tangem
//
//  Created by Alexander Osokin on 04.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol KeysDerivingProvider: AnyObject {
    var keysDerivingInteractor: KeysDeriving { get }
}
