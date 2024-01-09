//
//  QRCodeParser.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct QRCodeParser {
    let amountType: Amount.AmountType
    let blockchain: Blockchain

    func parse(_ code: String) -> Result {
        let withoutPrefix = code.remove(contentsOf: blockchain.qrPrefixes)
        let splitted = withoutPrefix.split(separator: "?")
        let destination = splitted.first.map { String($0) } ?? withoutPrefix

        guard splitted.count > 1 else { return Result(destination: destination, amount: nil) }

        let queryItems = splitted[1].lowercased().split(separator: "&")
        for queryItem in queryItems {
            guard queryItem.contains("amount") else { continue }

            let amountText = queryItem.replacingOccurrences(of: "amount=", with: "")

            guard let value = Decimal(string: amountText, locale: Locale(identifier: "en_US")) else {
                break
            }
            let amount = Amount(with: blockchain, type: amountType, value: value)
            return Result(destination: destination, amount: amount)
        }

        return Result(destination: destination, amount: nil)
    }
}

extension QRCodeParser {
    struct Result {
        let destination: String
        let amount: Amount?
    }
}
