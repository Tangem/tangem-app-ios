//
//  StakeKitDTO+SubmitHash.swift
//  TangemStaking
//
//  Created by Alexander Osokin on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum SubmitHash {
        struct Request: Encodable {
            let hash: String
        }
    }
}
