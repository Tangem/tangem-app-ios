//
//  StakingValidatorViewMapper.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct StakingValidatorViewMapper {
    private let percentFormatter = PercentFormatter()

    func mapToValidatorViewData(info: ValidatorInfo, detailsType: ValidatorViewData.DetailsType?) -> ValidatorViewData {
        ValidatorViewData(
            id: info.address,
            name: info.name,
            imageURL: info.iconURL,
            aprFormatted: info.apr.map { percentFormatter.format($0, option: .staking) },
            detailsType: detailsType
        )
    }
}
