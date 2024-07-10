//
//  SendFeeInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendFeeInteractor {
    var selectedFee: SendFee? { get }
    var selectedFeePublisher: AnyPublisher<SendFee, Never> { get }

    var feesPublisher: AnyPublisher<[SendFee], Never> { get }
    var customFeeInputFieldModels: [SendCustomFeeInputFieldModel] { get }

    func update(selectedFee: SendFee)
    func updateFees()
}
