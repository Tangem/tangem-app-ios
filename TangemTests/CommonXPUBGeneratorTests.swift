//
//  CommonXPUBGeneratorTests.swift
//  TangemTests
//
//  Created by Alexander Osokin on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemSdk
@testable import Tangem

class CommonXPUBGeneratorTests: XCTestCase {
    /// Test seed compare with https://iancoleman.io/bip39/
    func testXPUBGeneratorBTC() async throws {
        let generator = CommonXPUBGenerator(
            isTestnet: false,
            seedKey: Data(),
            parentKey: CommonXPUBGenerator.Key(
                derivationPath: try DerivationPath(rawPath: "m/44'/0'/0'"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "02FB16DF58DF3C8FDB128CEE3159EF552ED0DDF77451D401C74CD8B1F768246E4C"),
                    chainCode: Data(hexString: "F2FAA12902156F4F3054384CFE11DBB3DA57DCB8F0DACB39DD5632F871F20A83")
                )
            ),
            childKey: CommonXPUBGenerator.Key(
                derivationPath: try DerivationPath(rawPath: "m/44'/0'/0'/0"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "03E4528B3940E1BF7502A045067D1822F859FE2ED336B39F0BFD46A8CB38BD3E4B"),
                    chainCode: Data(hexString: "2C2DB3FC7AD8427443550F1F1003C0BA754D364D84998067D0B04202FDE3AD38")
                )
            ),
            cardInteractor: KeysDerivingMock()
        )

        let xpub = try await generator.generateXPUB()
        XCTAssertEqual(xpub, "xpub6E8jCqdYZcAaj9ZovPA1xiTRSu7brzzamw4yD8PsQjxYZS1sj4GfiGvhXyzBbqXiyh9MX2UhzY8X3M2CWPMmENccMbVvbrySE6EbE9ieHWJ")
    }

    /// Test seed compare with https://iancoleman.io/bip39/
    func testXPUBGeneratorHardenedIndex() async throws {
        let generator = CommonXPUBGenerator(
            isTestnet: false,
            seedKey: Data(),
            parentKey: CommonXPUBGenerator.Key(
                derivationPath: try DerivationPath(rawPath: "m/44'/0'/1'"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "02265527CC18902C44496979E9C7B758DAB947E0987262B65F14C9C077873E9630"),
                    chainCode: Data(hexString: "CD5F9816192A61FD3C5AB7439B20D4DA90CA9818ACFE170A11BB0F7BA4DEC21E")
                )
            ),
            childKey: CommonXPUBGenerator.Key(
                derivationPath: try DerivationPath(rawPath: "m/44'/0'/1'/10'"),
                extendedPublicKey: ExtendedPublicKey(
                    publicKey: Data(hexString: "038B35FD52B5318B7C44712810636040D7BD703CF93F843871754A35F78D777135"),
                    chainCode: Data(hexString: "B1EC31F392C0A09F566111656AFE1BB61C120514D776E257CDED55850153E5EE")
                )
            ),
            cardInteractor: KeysDerivingMock()
        )

        let xpub = try await generator.generateXPUB()
        XCTAssertEqual(xpub, "xpub6FAqNyRZorqRKQyQCJqsCd264fh1Wiv4d42Myic4Tu5HfgGyhn4CH1MxjTZUQFoUv5UKAAkRdrWHGZWyaYDrjjycN1jxsycC7J7cBe7G2tx")
    }
}
