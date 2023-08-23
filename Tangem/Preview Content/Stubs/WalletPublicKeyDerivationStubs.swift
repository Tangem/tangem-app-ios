//
//  WalletPublicKeyDerivationStubs.swift
//  Tangem
//
//  Created by Andrew Son on 28/07/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

extension Wallet.PublicKey.HDKey {
    static let ethDerivationStub = Wallet.PublicKey.HDKey(
        path: try! .init(rawPath: "m/44'/60'/0'/0/0"),
        extendedPublicKey: .init(
            publicKey: Data(hexString: "032A08567430A46A47CFFBF3FFD7FBB17A7850E75E7AC8E3E034BB1D8D5625A30D"),
            chainCode: Data(hexString: "01A5E27742465E0C7D2A7E3F7485717950095B1761DF8AD96944EED0140022E4")
        )
    )

    static let btcLegacyDerivationStub = Wallet.PublicKey.HDKey(
        path: try! .init(rawPath: "m/44'/0'/0'/0/0"),
        extendedPublicKey: .init(
            publicKey: Data(hexString: "032A08567430A46A47CFFBF3FFD7FBB17A7850E75E7AC8E3E034BB1D8D5625A30D"),
            chainCode: Data(hexString: "58CF6DAD43FE8C174D7DADA07A1BA6266B8E934E6D4BBB9F903418BF63CF9B72")
        )
    )

    static let btcSegwitDerivationStub = Wallet.PublicKey.HDKey(
        path: try! .init(rawPath: "m/84'/0'/0'/0/0"),
        extendedPublicKey: .init(
            publicKey: Data(hexString: "02616104143281B4679AFEB669392B073D63564606F431D13DF3EBEDE75D269509"),
            chainCode: Data(hexString: "EE4696FCB6920DBCBCF33423885C53CB5A16B5AD124715A26DF43299A087FB7D")
        )
    )

    static let xrpDerivationStub = Wallet.PublicKey.HDKey(
        path: try! .init(rawPath: "m/44'/144'/0'/0/0"),
        extendedPublicKey: .init(
            publicKey: Data(hexString: "02616104143281B4679AFEB669392B073D63564606F431D13DF3EBEDE75D269509"),
            chainCode: Data(hexString: "EE4696FCB6920DBCBCF33423885C53CB5A16B5AD124715A26DF43299A087FB7D")
        )
    )
}
