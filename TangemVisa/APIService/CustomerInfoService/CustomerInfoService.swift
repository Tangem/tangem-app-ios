//
//  CustomerInfoService.swift
//  TangemVisa
//
//  Created by Andrew Son on 22.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CustomerInfoService {}

class CommonCustomerInfoService {
    private let authorizationTokenHandler: AuthorizationTokenHandler

    init(authorizationTokenHandler: AuthorizationTokenHandler) {
        self.authorizationTokenHandler = authorizationTokenHandler
    }
}

extension CommonCustomerInfoService: CustomerInfoService {}
