//
//  CustomFeeService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol CustomFeeService: AnyObject {
    var customFeeDescription: String? { get }

    func inputFieldModels() -> [SendCustomFeeInputFieldModel]
}

protocol EditableCustomFeeService: CustomFeeService {
    func setCustomFee(value: Decimal?)
}
