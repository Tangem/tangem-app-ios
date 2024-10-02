//
//  OnrampRepository.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol OnrampRepository {
    func updatePairs(wallet: OnrampPair) async throws
    func updatePaymentMethods() async throws

    func getPaymentMethods() -> [OnrampPaymentMethod]
}
