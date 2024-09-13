//
//  UserWalletNameIndexationTests.swift
//  TangemTests
//
//  Created by Andrey Chukavin on 17.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

class UserWalletNameIndexationTests: XCTestCase {
    func testUserWalletNameIndexation() throws {
        for testCaseSet in testCaseSets {
            let existingNamesTestCases = testCaseSet.existingNamesTestCases
            let existingNames = existingNamesTestCases.map(\.0)
            let expectedNamesAfterMigration = existingNamesTestCases.map(\.1).sorted()

            let wallets = existingNames.map(WalletMock.init)
            let migratedWallets = try XCTUnwrap(UserWalletNameIndexationHelper.migratedWallets(wallets))
            let migratedNames = migratedWallets.map(\.name).sorted()

            XCTAssertEqual(migratedNames, expectedNamesAfterMigration)

            for newNameTestCase in testCaseSet.newNameTestCases {
                let name = UserWalletNameIndexationHelper.suggestedName(newNameTestCase.0, names: migratedNames)
                XCTAssertEqual(name, newNameTestCase.1)
            }
        }
    }
}

extension UserWalletNameIndexationTests {
    struct TestCasesSet {
        let existingNamesTestCases: [(String, String)]
        let newNameTestCases: [(String, String)]
    }

    struct WalletMock: NameableWallet {
        var name: String
    }
}

extension UserWalletNameIndexationTests {
    var testCaseSets: [TestCasesSet] {
        [
            // 🚀 The original set, neatly organized
            TestCasesSet(
                existingNamesTestCases: [
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Note", /*         -> */ "Note"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Note", /*         -> */ "Note 3"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                ],
                newNameTestCases: [
                    ("Wallet", "Wallet 5"),
                    ("Note", "Note 4"),
                    ("Twin", "Twin 5"),
                    ("Start2Coin", "Start2Coin 2"),
                    ("Wallet 2.0", "Wallet 2.0 4"),
                    ("Tangem Card", "Tangem Card 2"),
                ]
            ),
            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Note", /*         -> */ "Note"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Note", /*         -> */ "Note 3"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                ],
                newNameTestCases: [
                    ("Start2Coin", "Start2Coin 2"),
                    ("Wallet 2.0", "Wallet 2.0 4"),
                    ("Wallet", "Wallet 5"),
                    ("Twin", "Twin 5"),
                    ("Note", "Note 4"),
                    ("Tangem Card", "Tangem Card 2"),
                ]
            ),
            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Note", /*         -> */ "Note 3"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Note", /*         -> */ "Note"),
                ],
                newNameTestCases: [
                    ("Wallet 2.0", "Wallet 2.0 4"),
                    ("Twin", "Twin 5"),
                    ("Tangem Card", "Tangem Card 2"),
                    ("Wallet", "Wallet 5"),
                    ("Note", "Note 4"),
                    ("Start2Coin", "Start2Coin 2"),
                ]
            ),

            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Note", /*         -> */ "Note"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Note", /*         -> */ "Note 3"),
                ],
                newNameTestCases: [
                    ("Twin", "Twin 5"),
                    ("Note", "Note 4"),
                    ("Wallet", "Wallet 5"),
                    ("Start2Coin", "Start2Coin 2"),
                    ("Tangem Card", "Tangem Card 2"),
                    ("Wallet 2.0", "Wallet 2.0 4"),
                ]
            ),
            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Note", /*         -> */ "Note"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Note", /*         -> */ "Note 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                ],
                newNameTestCases: [
                    ("Note", "Note 4"),
                    ("Wallet", "Wallet 5"),
                    ("Wallet 2.0", "Wallet 2.0 4"),
                    ("Tangem Card", "Tangem Card 2"),
                    ("Start2Coin", "Start2Coin 2"),
                    ("Twin", "Twin 5"),
                ]
            ),
            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Note", /*         -> */ "Note"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Note", /*         -> */ "Note 3"),
                ],
                newNameTestCases: [
                    ("Twin", "Twin 5"),
                    ("Note", "Note 4"),
                    ("Wallet", "Wallet 5"),
                    ("Tangem Card", "Tangem Card 2"),
                    ("Start2Coin", "Start2Coin 2"),
                    ("Wallet 2.0", "Wallet 2.0 4"),
                ]
            ),
            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Note", /*         -> */ "Note 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Note", /*         -> */ "Note"),
                ],
                newNameTestCases: [
                    ("Wallet 2.0", "Wallet 2.0 4"),
                    ("Twin", "Twin 5"),
                    ("Note", "Note 4"),
                    ("Tangem Card", "Tangem Card 2"),
                    ("Start2Coin", "Start2Coin 2"),
                    ("Wallet", "Wallet 5"),
                ]
            ),
            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Note", /*         -> */ "Note 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Note", /*         -> */ "Note"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Wallet", /*       -> */ "Wallet"),
                ],
                newNameTestCases: [
                    ("Tangem Card", "Tangem Card 2"),
                    ("Wallet", "Wallet 5"),
                    ("Wallet 2.0", "Wallet 2.0 4"),
                    ("Twin", "Twin 5"),
                    ("Note", "Note 4"),
                    ("Start2Coin", "Start2Coin 2"),
                ]
            ),
            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Note", /*         -> */ "Note"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Note", /*         -> */ "Note 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                ],
                newNameTestCases: [
                    ("Tangem Card", "Tangem Card 2"),
                    ("Wallet", "Wallet 5"),
                    ("Wallet 2.0", "Wallet 2.0 4"),
                    ("Twin", "Twin 5"),
                    ("Note", "Note 4"),
                    ("Start2Coin", "Start2Coin 2"),
                ]
            ),
            // 🔀 Randomized set
            TestCasesSet(
                existingNamesTestCases: [
                    ("Twin 1", /*       -> */ "Twin 1"),
                    ("Tangem Card", /*  -> */ "Tangem Card"),
                    ("Note", /*         -> */ "Note 3"),
                    ("Twin", /*         -> */ "Twin 2"),
                    ("Note", /*         -> */ "Note"),
                    ("Twin", /*         -> */ "Twin 4"),
                    ("Twin 3", /*       -> */ "Twin 3"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0"),
                    ("Wallet", /*       -> */ "Wallet 3"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                    ("Note", /*         -> */ "Note 2"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet", /*       -> */ "Wallet"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 2"),
                    ("Wallet", /*       -> */ "Wallet 4"),
                    ("Start2Coin 1", /* -> */ "Start2Coin 1"),
                    ("Wallet 2.0", /*   -> */ "Wallet 2.0 3"),
                    ("Wallet 2", /*     -> */ "Wallet 2"),
                ],
                newNameTestCases: [
                    ("Wallet 2.0", "Wallet 2.0 4"),
                    ("Wallet", "Wallet 5"),
                    ("Start2Coin", "Start2Coin 2"),
                    ("Twin", "Twin 5"),
                    ("Tangem Card", "Tangem Card 2"),
                    ("Note", "Note 4"),
                ]
            ),
        ]
    }
}
