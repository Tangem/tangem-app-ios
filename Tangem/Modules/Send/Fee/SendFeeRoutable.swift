//
//  SendFeeRoutable.swift
//  Tangem
//
//  Created by Andrey Chukavin on 26.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendFeeRoutable: AnyObject {
    func openFeeExplanation(url: URL)
}
