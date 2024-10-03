//
//  AmountSummaryViewData.swift
//  Tangem
//
//  Created by Andrey Chukavin on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AmountSummaryViewData: Identifiable {
    let id = UUID()

    let title: String
    let amount: String
    let amountFiat: String
    let tokenIconInfo: TokenIconInfo
}
