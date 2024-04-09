//
//  SendAmountSummaryViewData.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendAmountSummaryViewData: Identifiable {
    let id = UUID()

    let title: String
    let amount: String
    let amountAlternative: String
    let tokenIconInfo: TokenIconInfo
}
