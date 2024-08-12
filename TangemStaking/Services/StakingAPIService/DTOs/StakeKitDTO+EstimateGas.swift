//
//  StakeKitDTO+EstimateGas.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 09.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum EstimateGas {
        struct GenericResponse: Decodable {
            let amount: String?
            let token: Token
            let gasLimit: String
        }

        enum Enter {
            typealias Request = Actions.Enter.Request
            typealias Response = GenericResponse
        }

        enum Exit {
            typealias Request = Actions.Exit.Request
            typealias Response = GenericResponse
        }

        enum Pending {
            typealias Request = Actions.Pending.Request
            typealias Response = GenericResponse
        }
    }
}
