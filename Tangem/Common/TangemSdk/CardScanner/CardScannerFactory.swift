//
//  CardScannerFactory.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CardScannerFactory {
    private var isMocked: Bool {
        if AppEnvironment.current.isProduction {
            return false
        }

        return FeatureStorage.instance.isMockedCardScannerEnabled
    }

    func makeDefaultScanner() -> CardScanner {
        if isMocked {
            return MockedCardScanner()
        } else {
            return CommonCardScanner()
        }
    }

    func makeScanner(with tangemSdk: TangemSdk, parameters: CardScannerParameters) -> CardScanner {
        let scanner = CommonCardScanner(tangemSdk: tangemSdk, parameters: parameters)

        if isMocked {
            return MockedCardScanner(scanner: scanner)
        } else {
            return scanner
        }
    }
}
