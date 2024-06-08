//
//  StakeKitDTO+Actions.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    // TODO: Will be updated when the networks start be intergated
    enum Actions {
        enum Get {
            struct Request: Encodable {
                let actionId: String
            }

            struct Response: Decodable {}
        }

        enum Enter {
            struct Request: Encodable {
                let addresses: Address
                let args: Args
                let integrationId: String

                struct Args: Encodable {
                    let amount: String
                    let validatorAddress: String?
                    let validatorAddresses: [Address]
                }
            }

            struct Response: Decodable {}
        }
    }
}
