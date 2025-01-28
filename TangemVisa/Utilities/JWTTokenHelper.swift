//
//  JWTTokenHelper.swift
//  TangemVisa
//
//  Created by Andrew Son on 02.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import JWTDecode

struct JWTTokenHelper {
    private let customerIDClaim = "customer-id"
    private let productInstanceIDClaim = "product-instance-id"

    func getCustomerID(fromStringToken token: String) throws -> String? {
        let jwt = try decode(jwt: token)
        return getCustomerID(from: jwt)
    }

    func getCustomerID(from token: JWT) -> String? {
        return token.claim(name: customerIDClaim).string
    }

    func getProductInstanceID(fromStringToken token: String) throws -> String? {
        let jwt = try decode(jwt: token)
        return getProductInstanceID(from: jwt)
    }

    func getProductInstanceID(from token: JWT) -> String? {
        return token.claim(name: productInstanceIDClaim).string
    }
}
