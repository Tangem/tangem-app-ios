//
//  LitecoinTests.swift
//  BlockchainSdkTests
//
//  Created by Andrew Son on 03/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import XCTest
import BitcoinCore
import TangemSdk
@testable import BlockchainSdk

class LitecoinTests: XCTestCase {
    private let blockchain = Blockchain.litecoin
    private let networkParams = LitecoinNetworkParams()
    private var addressService: BitcoinAddressService {
        BitcoinAddressService(networkParams: LitecoinNetworkParams())
    }

    private let sizeTester = TransactionSizeTesterUtility()

    func testAddress() throws {
        let walletPublicKey = Data(hex: "041C1E7B3253E5C1E3519FB22894AD95285CE244D1D426A58D3178296A488FDC56699C85990B3EC09505253CB3C3FC7B712F1C6E953675922534B61D17408EAB39")
        let expectedAddress = "LWjJD6H1QrMmCQ5QhBKMqvPqMzwYpJPv2M"

        let address = try addressService.makeAddress(from: walletPublicKey, type: .legacy)
        XCTAssertEqual(address.value, expectedAddress)
    }

    func testValidateCorrectAddress() {
        XCTAssertTrue(addressService.validate("LWjJD6H1QrMmCQ5QhBKMqvPqMzwYpJPv2M"))
    }

    func testBuildTransaction() throws {
        let walletPubkey = Data(hex: "04AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EA")
        let compressedPubkey = try! Secp256k1Key(with: walletPubkey).compress()
        XCTAssertNotNil(compressedPubkey)

        let signature1 = Data(hex: "F4E41BBE57B306529EBE797ABCE8CBA399F391B0804B8CD52C329F398E815FB4E7C314437399CB915AA9580458DDC2440EA3E6121CC2D6B5F5C67232B5B60C54")
        let signature2 = Data(hex: "B6DC3A0163FADB5B4FF70F1BD8165C03CC7D474C45942B81B841BE2E747CE30105AF501D55D1BA6E433745F3AD04243EEF53435AD32AA2E523DC413F1F5D7BCC")

        let sendValue = Decimal(0.00015)
        let feeValue = Decimal(0.00001752)
        let destinationAddress = "LWjJD6H1QrMmCQ5QhBKMqvPqMzwYpJPv2M"

        let feeRate = 4
        let addresses = [
            try addressService.makeAddress(from: walletPubkey, type: .default),
            try addressService.makeAddress(from: walletPubkey, type: .legacy),
        ]
        let address = addresses[1].value
        XCTAssertNotNil(address)

        let bitcoinCoreManager = BitcoinManager(networkParams: networkParams, walletPublicKey: walletPubkey, compressedWalletPublicKey: compressedPubkey, bip: .bip44)
        let txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinCoreManager, addresses: addresses)
        txBuilder.unspentOutputs =
            [
                BitcoinUnspentOutput(transactionHash: "bcacfe1bc1323e8e421486e4b334b91163925d7edd87133673c3efbd4e3fedae", outputIndex: 0, amount: 10000, outputScript: "76a914ccd4649cdb4c9f8fdb54869cff112a4e75fda2bb88ac"),
                BitcoinUnspentOutput(transactionHash: "fa16fbd7f8a150dc723091fd2305eaa07189e869f9133bf3d429efc5ef3f86ff", outputIndex: 0, amount: 10000, outputScript: "76a914ccd4649cdb4c9f8fdb54869cff112a4e75fda2bb88ac"),
            ]

        let amountToSend = Amount(with: blockchain, type: .coin, value: sendValue)
        let feeAmount = Amount(with: blockchain, type: .coin, value: feeValue)
        let fee = Fee(feeAmount, parameters: BitcoinFeeParameters(rate: feeRate))
        let tx = Transaction(amount: amountToSend, fee: fee, sourceAddress: address, destinationAddress: destinationAddress, changeAddress: address)

        let expectedHashToSign1 = Data(hex: "4E17896956F9B8AFCCD0B2BBF5AC50462508C0AC1485EB6580AF7CC9300E837E")
        let expectedHashToSign2 = Data(hex: "E84A90E9E9DAE1EACAA2F12B79FF8824F868EA77C35272ADE0DFF8D2DAA8391E")
        let expectedSignedTx = Data(hex: "0100000002AEED3F4EBDEFC373361387DD7E5D926311B934B3E48614428E3E32C11BFEACBC000000008B483045022100F4E41BBE57B306529EBE797ABCE8CBA399F391B0804B8CD52C329F398E815FB40220183CEBBC8C66346EA556A7FBA7223DBAAC0AF6D49285C985CA0BEC5A1A8034ED014104AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EAFAFFFFFFFF863FEFC5EF29D4F33B13F969E88971A0EA0523FD913072DC50A1F8D7FB16FA000000008B483045022100B6DC3A0163FADB5B4FF70F1BD8165C03CC7D474C45942B81B841BE2E747CE301022005AF501D55D1BA6E433745F3AD04243EEF53435AD32AA2E523DC413F1F5D7BCC014104AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EAFAFFFFFF02983A0000000000001976A9147E3618C4A80997D5F836FA17A10FCC17B4A9245188ACB00C0000000000001976A914CCD4649CDB4C9F8FDB54869CFF112A4E75FDA2BB88AC00000000")

        testTransaction(
            tx,
            signatures: [signature1, signature2],
            txBuilder: txBuilder,
            sortType: .none,
            expectedHashes: [expectedHashToSign1, expectedHashToSign2],
            expectedSignedTransaction: expectedSignedTx
        )

        let expectedHashToSign1Sorted = Data(hex: "0eb63431fbe70eb30d8ef8d788c5a7971d1bbd319b54dd8252578f3f84311e2f")
        let expectedHashToSign2Sorted = Data(hex: "eb7b158f86c6fc825f199d7addcb0003e7c5474abe515f466cbd8c54daf4e123")
        let expectedSignedSortedTransaction = Data(hex: "0100000002AEED3F4EBDEFC373361387DD7E5D926311B934B3E48614428E3E32C11BFEACBC000000008B483045022100F4E41BBE57B306529EBE797ABCE8CBA399F391B0804B8CD52C329F398E815FB40220183CEBBC8C66346EA556A7FBA7223DBAAC0AF6D49285C985CA0BEC5A1A8034ED014104AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EAFAFFFFFFFF863FEFC5EF29D4F33B13F969E88971A0EA0523FD913072DC50A1F8D7FB16FA000000008B483045022100B6DC3A0163FADB5B4FF70F1BD8165C03CC7D474C45942B81B841BE2E747CE301022005AF501D55D1BA6E433745F3AD04243EEF53435AD32AA2E523DC413F1F5D7BCC014104AC17063C443E9DC00C090733A0A76FF18A322D8484495FDF65BE5922EA6C1F5EDC0A802D505BFF664E32E9082DC934D60A4B4E83572A0818F1D73F8FB4D100EAFAFFFFFF02B00C0000000000001976A914CCD4649CDB4C9F8FDB54869CFF112A4E75FDA2BB88AC983A0000000000001976A9147E3618C4A80997D5F836FA17A10FCC17B4A9245188AC00000000")
        testTransaction(
            tx,
            signatures: [signature1, signature2],
            txBuilder: txBuilder,
            sortType: .bip69,
            expectedHashes: [expectedHashToSign1Sorted, expectedHashToSign2Sorted],
            expectedSignedTransaction: expectedSignedSortedTransaction
        )
    }

    private func testTransaction(_ transaction: BlockchainSdk.Transaction, signatures: [Data], txBuilder: BitcoinTransactionBuilder, sortType: TransactionDataSortType, expectedHashes: [Data], expectedSignedTransaction: Data) {
        let buildToSignResult = txBuilder.buildForSign(transaction: transaction, sequence: 4294967290, sortType: sortType)!
        sizeTester.testTxSizes(buildToSignResult)
        let signedTx = txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: 4294967290, sortType: sortType)
        XCTAssertEqual(buildToSignResult.map { $0.hexString }, expectedHashes.map { $0.hexString })
        XCTAssertEqual(signedTx?.hexString, expectedSignedTransaction.hexString)
    }
}
