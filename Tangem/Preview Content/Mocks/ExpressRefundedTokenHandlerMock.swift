//
//  ExpressRefundedTokenHandlerMock.swift
//  Tangem
//
//  Created by Alexander Osokin on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct ExpressRefundedTokenHandlerMock: ExpressRefundedTokenHandler {
    func handle(expressCurrency: ExpressCurrency) async throws -> TokenItem {
        return .blockchain(.init(.polygon(testnet: false), derivationPath: nil))
    }
}
