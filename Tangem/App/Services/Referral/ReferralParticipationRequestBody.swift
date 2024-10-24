//
//  ReferralParticipationRequestBody.swift
//  Tangem
//
//  Created by Andrew Son on 16/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct ReferralParticipationRequestBody: Encodable {
    let walletId: String
    let networkId: String
    let tokenId: String
    let address: String
}
