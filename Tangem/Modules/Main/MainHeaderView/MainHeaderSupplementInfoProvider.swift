//
//  MainHeaderInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 22/05/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol MainHeaderSupplementInfoProvider: AnyObject {
    var cardHeaderImagePublisher: AnyPublisher<ImageType?, Never> { get }
    var userWalletNamePublisher: AnyPublisher<String, Never> { get }
}
