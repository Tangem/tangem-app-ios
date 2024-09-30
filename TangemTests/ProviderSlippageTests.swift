//
//  ProviderSlippageTests.swift
//  TangemExpressTests
//
//  Created by GuitarKitty on 30.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem
@testable import TangemExpress

final class ProviderSlippageTests: XCTestCase {
    func testProviderInitialization() {
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "ChangeNow"), .changenow)
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "Changelly"), .changelly)
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "SimpleSwap"), .simpleswap)
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "ChangeHero"), .changehero)
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "1Inch"), .oneInch)
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "OKX onchain"), .okxOnchain)
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "OKX crosschain"), .okxCrossChain)
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "unknown"), .unknown)
        XCTAssertEqual(ExpressViewModel.Provider(rawValue: "nonexistent"), .unknown)
    }

    func testProviderMaxSlippage() {
        XCTAssertEqual(ExpressViewModel.Provider.changenow.maxSlippage, 3)
        XCTAssertEqual(ExpressViewModel.Provider.changelly.maxSlippage, 5)
        XCTAssertEqual(ExpressViewModel.Provider.simpleswap.maxSlippage, 5)
        XCTAssertEqual(ExpressViewModel.Provider.changehero.maxSlippage, 5)
        XCTAssertEqual(ExpressViewModel.Provider.oneInch.maxSlippage, 2)
        XCTAssertEqual(ExpressViewModel.Provider.okxOnchain.maxSlippage, 2)
        XCTAssertEqual(ExpressViewModel.Provider.okxCrossChain.maxSlippage, 3.5)
        XCTAssertEqual(ExpressViewModel.Provider.unknown.maxSlippage, 0)
    }

    func testSlippageSubtraction() {
        XCTAssertEqual(fetchAmountAfterSlippage(for: "ChangeNow", expectAmount: 100), 97)
        XCTAssertEqual(fetchAmountAfterSlippage(for: "Changelly", expectAmount: 100), 95)
        XCTAssertEqual(fetchAmountAfterSlippage(for: "SimpleSwap", expectAmount: 100), 95)
        XCTAssertEqual(fetchAmountAfterSlippage(for: "ChangeHero", expectAmount: 100), 95)
        XCTAssertEqual(fetchAmountAfterSlippage(for: "1Inch", expectAmount: 100), 98)
        XCTAssertEqual(fetchAmountAfterSlippage(for: "OKX onchain", expectAmount: 100), 98)
        XCTAssertEqual(fetchAmountAfterSlippage(for: "OKX crosschain", expectAmount: 100), 96.5)
    }

    private func fetchAmountAfterSlippage(for providerName: String, expectAmount: Decimal) -> Decimal {
        let providerSlippage = ExpressViewModel.Provider(rawValue: providerName).maxSlippage
        let slippagePercent = (100 - providerSlippage) / 100

        return expectAmount * slippagePercent
    }
}
