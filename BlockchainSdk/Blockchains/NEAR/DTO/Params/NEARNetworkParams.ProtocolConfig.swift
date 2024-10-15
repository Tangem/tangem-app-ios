//
//  NEARNetworkParams..swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkParams {
    struct ProtocolConfig: Encodable {
        let finality: Finality
    }
}
