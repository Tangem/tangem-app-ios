//
//  VisaTransactionDetailsViewModelMock.swift
//  Tangem
//
//  Created by Andrew Son on 26/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

extension VisaTransactionDetailsViewModel {
    static var uiMock: VisaTransactionDetailsViewModel {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let decoder = JSONDecoder()
        do {
            let url = Bundle.main.url(forResource: "visaSingleTransaction", withExtension: "json")!
            let jsonContent = try String(contentsOf: url)
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .formatted(formatter)

            let transaction = try decoder.decode(VisaTransactionRecord.self, from: jsonContent.data(using: .utf8)!)
            let utils = VisaUtilities()
            let tokenItem = TokenItem.token(utils.visaToken, utils.visaBlockchain)
            return .init(tokenItem: tokenItem, transaction: transaction)
        } catch {
            print("\n\n\nFailed to create UI mock. Error: \(error)\n\n\n")
            fatalError("Failed to create UI mock. Error: \(error)")
        }
    }
}
