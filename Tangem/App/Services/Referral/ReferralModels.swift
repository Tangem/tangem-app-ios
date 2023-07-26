//
//  ReferralModels.swift
//  Tangem
//
//  Created by Andrew Son on 08/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct ReferralProgramInfo: Decodable {
    let conditions: Conditions
    let referral: Referral?
    let expectedAwards: ExpectedAwards?
}

extension ReferralProgramInfo {
    struct Conditions: Decodable {
        let discount: Discount
        let tosLink: String
        let awards: [Award]
    }

    struct Referral: Decodable {
        let shareLink: String
        let address: String
        let promoCode: String
        let walletsPurchased: Int
    }

    struct Award: Decodable {
        let amount: Decimal
        let token: AwardToken
    }

    struct Discount: Decodable {
        let amount: Int
        let type: DiscountType
    }

    enum DiscountType: String, Decodable {
        case percentage
        case value

        var symbol: String {
            "%"
        }
    }

    struct ExpectedAwards: Decodable {
        let numberOfWallets: Int
        let list: [ExpectedAward]
    }

    struct ExpectedAward: Decodable {
        let currency: String
        let paymentDate: String
        let amount: Int
    }
}
