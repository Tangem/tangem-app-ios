//
//  Analytics+BlockchainExceptionHandler.swift
//  Tangem
//
//  Created by skibinalexander on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Analytics {
    struct BlockchainExceptionHandler: ExceptionHandlerOutput {
        func handleAPISwitch(currentHost: String, nextHost: String, message: String) {
            Analytics.log(
                event: .blockchainSdkException,
                params: [.exceptionHost: currentHost, .selectedHost: nextHost, .errorDescription: message]
            )
        }
    }
}
