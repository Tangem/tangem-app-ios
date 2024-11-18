//
//  MarketsTokenDetailsSecurityScoreDetailsRoutable.swift
//  Tangem
//
//  Created by Andrey Fedorov on 09.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokenDetailsSecurityScoreDetailsRoutable: AnyObject {
    func openSecurityAudit(at url: URL, providerName: String)
}
