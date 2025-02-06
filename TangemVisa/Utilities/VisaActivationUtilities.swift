//
//  VisaActivationUtility.swift
//  TangemVisa
//
//  Created by Andrew Son on 03/02/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

struct VisaActivationUtility {
    func getEssentialActivationIds(from accessToken: String) throws -> (customerId: String, productInstanceId: String) {
        let jwtToken = try decode(jwt: accessToken)
        return try getEssentialActivationIds(from: jwtToken)
    }

    func getEssentialActivationIds(from accessToken: JWT) throws -> (customerId: String, productInstanceId: String) {
        let jwtHelper = JWTTokenHelper()
        guard
            let customerId = jwtHelper.getCustomerID(from: accessToken),
            let productInstanceId = jwtHelper.getProductInstanceID(from: accessToken)
        else {
            throw VisaActivationError.missingCustomerInformationInAccessToken
        }

        return (customerId, productInstanceId)
    }
}
