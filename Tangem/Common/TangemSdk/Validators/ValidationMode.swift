//
//  ValidationMode.swift
//  Tangem
//
//  Created by Alexander Osokin on 13.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Card validation mode. In light mode, optional curves are not validated. This is an exception for Wallet 1 and the BLS curve. Since the curve `bls12381_G2_AUG` was added later into first generation of wallets,, we cannot determine whether this curve is missing due to an error or because the user did not want to recreate the wallet.
enum ValidationMode {
    case full
    case light
}
