//
//  SendSummaryStepsRoutable.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol SendSummaryStepsRoutable: AnyObject {
    func summaryStepRequestEditDestination()
    func summaryStepRequestEditAmount()
    func summaryStepRequestEditFee()
    func summaryStepRequestEditValidators()
}
