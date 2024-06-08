//
//  ActionButtonsProvider.swift
//  Tangem
//
//  Created by Andrew Son on 08/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol ActionButtonsProvider: AnyObject {
    var buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never> { get }
}
