//
//  TokenListInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 03/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TokenListInfoProvider: AnyObject {
    var sectionsPublisher: AnyPublisher<[TokenListSectionInfo], Never> { get }
}

class EmptyTokenListInfoProvider: TokenListInfoProvider {
    var sectionsPublisher: AnyPublisher<[TokenListSectionInfo], Never> {
        .just(output: [])
    }
}
