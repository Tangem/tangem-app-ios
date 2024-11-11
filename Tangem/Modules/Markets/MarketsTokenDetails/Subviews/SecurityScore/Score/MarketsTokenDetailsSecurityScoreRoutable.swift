//
//  MarketsTokenDetailsSecurityScoreRoutable.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokenDetailsSecurityScoreRoutable: AnyObject {
    func openSecurityScoreDetails(with providerData: [MarketsTokenDetailsSecurityData.ProviderData])
}
