//
//  StoriesDelegate.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol StoriesDelegate: AnyObject {
    var isScanning: AnyPublisher<Bool, Never> { get }

    func scanCard()
    func orderCard()
    func openPromotion()
    func openTokenList()
}
