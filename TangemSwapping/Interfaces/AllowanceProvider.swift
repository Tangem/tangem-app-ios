//
//  AllowanceProvider.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol AllowanceProvider {
    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal
    func makeApproveData(spender: String, amount: Decimal) throws -> Data
}
