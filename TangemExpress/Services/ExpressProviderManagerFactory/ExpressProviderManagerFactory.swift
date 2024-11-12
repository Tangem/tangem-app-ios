//
//  ExpressProviderManagerFactory.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 11.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressProviderManagerFactory {
    func makeExpressProviderManager(provider: ExpressProvider) -> ExpressProviderManager?
}
