//
//  CardDerivableProvider.swift
//  Tangem
//
//  Created by Alexander Osokin on 28.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol CardDerivableProvider: AnyObject {
    var cardDerivableInteractor: CardDerivable { get }
}
