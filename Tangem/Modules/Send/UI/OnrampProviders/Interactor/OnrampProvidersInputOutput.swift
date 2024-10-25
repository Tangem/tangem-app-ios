//
//  OnrampProvidersInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampProvidersInput: AnyObject {
    var selectedOnrampProvider: OnrampAvailableProvider? { get }
    var selectedOnrampProviderPublisher: AnyPublisher<OnrampAvailableProvider?, Never> { get }

    var onrampProvidersPublisher: AnyPublisher<[OnrampAvailableProvider], Never> { get }
}

protocol OnrampProvidersOutput: AnyObject {
    func userDidSelect(provider: OnrampAvailableProvider)
}
