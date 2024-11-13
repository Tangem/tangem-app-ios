//
//  OnrampInputOutput.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol OnrampInput: AnyObject {
    var isValidToRedirectPublisher: AnyPublisher<Bool, Never> { get }
}

protocol OnrampOutput: AnyObject {}
