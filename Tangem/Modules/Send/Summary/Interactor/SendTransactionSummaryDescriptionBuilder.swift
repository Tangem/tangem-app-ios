//
//  SendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal, fee: Decimal) -> String?
}
