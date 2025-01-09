//
//  AddressesTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 29.12.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemSdk
import CryptoKit
import BitcoinCore
import class WalletCore.PrivateKey
@testable import BlockchainSdk

class AddressesTests: XCTestCase {
    private let secpPrivKey = Data(hexString: "83686EF30173D2A05FD7E2C8CB30941534376013B903A2122CF4FF3E8668355A")
    private let secpDecompressedKey = Data(hexString: "0441DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45E3D67E8D2947E6FEE8B62D3D3B6A4D5F212DA23E478DD69A2C6CCC851F300D80")
    private let secpCompressedKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private let edKey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")

    let addressesUtility = AddressServiceManagerUtility()

    func testBtc() throws {
        let blockchain = Blockchain.bitcoin(testnet: false)
        let service = BitcoinAddressService(networkParams: BitcoinNetwork.mainnet.networkParams)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        let bech32_dec = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let bech32_comp = try service.makeAddress(from: secpCompressedKey, type: .default)
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "bc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5edc40am")
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), bech32_dec.value)

        let leg_dec = try service.makeAddress(from: secpDecompressedKey, type: .legacy)
        let leg_comp = try service.makeAddress(from: secpCompressedKey, type: .legacy)
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "1HTBz4DRWpDET1QNMqsWKJ39WyWcwPWexK")
        XCTAssertEqual(leg_comp.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ")
    }

    func testBtcTestnet() throws {
        let service = BitcoinAddressService(networkParams: BitcoinNetwork.testnet.networkParams)
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        let bech32_dec = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let bech32_comp = try service.makeAddress(from: secpCompressedKey, type: .default)
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        XCTAssertEqual(bech32_dec.value, "tb1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5e87wuxg") // TODO: validate with android

        let leg_dec = try service.makeAddress(from: secpDecompressedKey, type: .legacy)
        let leg_comp = try service.makeAddress(from: secpCompressedKey, type: .legacy)
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "mwy9H7JQKqeVE7sz5Qqt9DFUNy7KtX7wHj") // TODO: validate with android
        XCTAssertEqual(leg_comp.value, "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ") // TODO: validate with android
    }

    func testBtcTwin() throws {
        // let secpPairPrivKey = Data(hexString: "997D79C06B72E8163D1B9FCE6DA0D2ABAA15B85E52C6032A087342BAD98E5316")
        let secpPairDecompressedKey = Data(hexString: "042A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D8936D318D49FE06E3437E31568B338B340F4E6DF5184E1EC5840F2B7F4596902AE")
        let secpPairCompressedKey = Data(hexString: "022A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D89")
        let service = BitcoinAddressService(networkParams: BitcoinNetwork.mainnet.networkParams)

        let addr_dec = try service.makeAddresses(
            publicKey: .init(seedKey: secpDecompressedKey, derivationType: .none),
            pairPublicKey: secpPairDecompressedKey
        )
        let addr_dec1 = try service.makeAddresses(
            publicKey: .init(seedKey: secpDecompressedKey, derivationType: .none),
            pairPublicKey: secpPairCompressedKey
        )
        let addr_comp = try service.makeAddresses(
            publicKey: .init(seedKey: secpCompressedKey, derivationType: .none),
            pairPublicKey: secpPairCompressedKey
        )
        let addr_comp1 = try service.makeAddresses(
            publicKey: .init(seedKey: secpCompressedKey, derivationType: .none),
            pairPublicKey: secpPairDecompressedKey
        )
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_dec1.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        XCTAssertEqual(addr_comp1.count, 2)

        XCTAssertEqual(addr_dec.first(where: { $0.type == .default })!.value, "bc1q0u3heda6uhq7fulsqmw40heuh3e76nd9skxngv93uzz3z6xtpjmsrh88wh")
        XCTAssertEqual(addr_dec.first(where: { $0.type == .legacy })!.value, "34DmpSKfsvqxgzVVhcEepeX3s67ai4ShPq")

        for index in 0 ..< 2 {
            XCTAssertEqual(addr_dec[index].value, addr_dec1[index].value)
            XCTAssertEqual(addr_dec[index].value, addr_comp[index].value)
            XCTAssertEqual(addr_dec[index].value, addr_comp1[index].value)

            XCTAssertEqual(addr_dec[index].localizedName, addr_dec1[index].localizedName)
            XCTAssertEqual(addr_dec[index].localizedName, addr_comp[index].localizedName)
            XCTAssertEqual(addr_dec[index].localizedName, addr_comp1[index].localizedName)

            XCTAssertEqual(addr_dec[index].type, addr_dec1[index].type)
            XCTAssertEqual(addr_dec[index].type, addr_comp[index].type)
            XCTAssertEqual(addr_dec[index].type, addr_comp1[index].type)
        }
    }

    func testLtc() throws {
        let blockchain = Blockchain.litecoin
        let service = BitcoinAddressService(networkParams: LitecoinNetworkParams())

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        let bech32_dec = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let bech32_comp = try service.makeAddress(from: secpCompressedKey, type: .default)
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "ltc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5efy0t9t") // TODO: validate
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), bech32_dec.value)

        let leg_dec = try service.makeAddress(from: secpDecompressedKey, type: .legacy)
        let leg_comp = try service.makeAddress(from: secpCompressedKey, type: .legacy)
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "Lbg9FGXFbUTHhp6XXyrobK6ujBsu7UE7ww")
        XCTAssertEqual(leg_comp.value, "LcxUXkP9KGqWHtbKyENSS8HQoQ9LK8DQLX")
    }

    func testXlmEd25519() throws {
        try testXlm(blockchain: .stellar(curve: .ed25519, testnet: false))
    }

    func testXlmEd25519Slip0010() throws {
        try testXlm(blockchain: .stellar(curve: .ed25519_slip0010, testnet: false))
    }

    func testXlm(blockchain: Blockchain) throws {
        let service = StellarAddressService()

        let addrs = try service.makeAddress(from: edKey)

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs.value, "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: edKey, for: blockchain), "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")

        let addr = try? AddressServiceManagerUtility().makeTrustWalletAddress(publicKey: edKey, for: blockchain)
        XCTAssertEqual(addrs.value, addr)
    }

    func testXlmTestnet() throws {
        let service = StellarAddressService()

        let addrs = try service.makeAddress(from: edKey)

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs.value, "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
    }

    func testEth() throws {
        let blockchain = Blockchain.ethereum(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_dec.value)
    }

    func testEthTestnet() throws {
        let blockchain = Blockchain.ethereum(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum
    }

    func testRsk() throws {
        let service = RskAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECA00c52afC728CDbf42E817d712E175Bb23C7d")
    }

    func testBch() throws {
        let blockchain = Blockchain.bitcoinCash
        let service = BitcoinCashAddressService(networkParams: BitcoinCashNetworkParams())

        let addr_dec_default = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let addr_dec_legacy = try service.makeAddress(from: secpDecompressedKey, type: .legacy)

        let addr_comp_default = try service.makeAddress(from: secpCompressedKey, type: .default)
        let addr_comp_legacy = try service.makeAddress(from: secpCompressedKey, type: .legacy)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec_default.value, addr_comp_default.value)
        XCTAssertEqual(addr_dec_legacy.value, addr_comp_legacy.value)

        XCTAssertEqual(addr_dec_default.localizedName, addr_comp_default.localizedName)
        XCTAssertEqual(addr_dec_legacy.localizedName, addr_comp_legacy.localizedName)

        XCTAssertEqual(addr_dec_default.type, addr_comp_default.type)
        XCTAssertEqual(addr_dec_legacy.type, addr_comp_legacy.type)

        let testRemovePrefix = String("bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc".removeBchPrefix())
        XCTAssertEqual(testRemovePrefix, "qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc")

        XCTAssertEqual(addr_comp_default.value, "bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc") // we ignore uncompressed addresses
        XCTAssertEqual(addr_comp_legacy.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ") // we ignore uncompressed addresses

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp_default.value)
    }

    func testBchTestnet() throws {
        let service = BitcoinCashAddressService(networkParams: BitcoinCashTestNetworkParams())

        let addr_dec_default = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let addr_dec_legacy = try service.makeAddress(from: secpDecompressedKey, type: .legacy)

        let addr_comp_default = try service.makeAddress(from: secpCompressedKey, type: .default)
        let addr_comp_legacy = try service.makeAddress(from: secpCompressedKey, type: .legacy)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec_default.value, addr_comp_default.value)
        XCTAssertEqual(addr_dec_legacy.value, addr_comp_legacy.value)

        XCTAssertEqual(addr_dec_default.localizedName, addr_comp_default.localizedName)
        XCTAssertEqual(addr_dec_legacy.localizedName, addr_comp_legacy.localizedName)

        XCTAssertEqual(addr_dec_default.type, addr_comp_default.type)
        XCTAssertEqual(addr_dec_legacy.type, addr_comp_legacy.type)

        XCTAssertEqual(addr_comp_default.value, "bchtest:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyzjtuac9y") // we ignore uncompressed addresses
        XCTAssertEqual(addr_comp_legacy.value, "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ") // we ignore uncompressed addresses
    }

    func testBinance() throws {
        let blockchain = Blockchain.binance(testnet: false)
        let service = BinanceAddressService(testnet: false)

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "bnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eex5gcc")

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_dec.value)
    }

    func testBinanceTestnet() throws {
        let service = BinanceAddressService(testnet: true)

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "tbnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5ehnavcf") // TODO: validate
    }

    func testAda() throws {
        let service = CardanoAddressService()
        let addrs = try service.makeAddress(from: edKey, type: .legacy)

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs.localizedName, AddressType.legacy.defaultLocalizedName)
        XCTAssertEqual(addrs.value, "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
    }

    func testAdaShelley() throws {
        let service = CardanoAddressService()

        let addrs_shelley = try service.makeAddress(from: edKey, type: .default) // default is shelley
        let addrs_byron = try service.makeAddress(from: edKey, type: .legacy) // legacy is byron

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs_byron.localizedName, AddressType.legacy.defaultLocalizedName)
        XCTAssertEqual(addrs_byron.value, "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")

        XCTAssertEqual(addrs_shelley.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs_shelley.value, "addr1vyq5f2ntspszzu77guh8kg4gkhzerws5t9jd6gg4d222yfsajkfw5")
    }

    func testXrpSecp() throws {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        let service = XRPAddressService(curve: .secp256k1)

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertTrue(service.validate(addr_dec.value))
        XCTAssertTrue(service.validate(addr_comp.value))

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.value, "rJjXGYnKNcbTsnuwoaP9wfDebB8hDX8jdQ")

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_dec.value)
    }

    func testXrpEd() throws {
        try testXrpEd(curve: .ed25519)
    }

    func testXrpEdSlip0010() throws {
        try testXrpEd(curve: .ed25519_slip0010)
    }

    func testXrpEd(curve: EllipticCurve) throws {
        let service = XRPAddressService(curve: curve)
        let address = try service.makeAddress(from: edKey)

        XCTAssertTrue(service.validate(address.value))

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(address.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(address.value, "rPhmKhkYoMiqC2xqHYhtPLnicWQi85uDf2") // TODO: validate
    }

    func testDuc() throws {
        let blockchain = Blockchain.dogecoin
        let service = BitcoinLegacyAddressService(networkParams: DogecoinNetworkParams())

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, "DMbHXKA4pE7Wz1ay6Rs4s4CkQ7EvKG3DqY")
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_comp.value, "DNscoo1xY2Vja65mXgNhhsPFUKWMa7NLEb")

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp.value)
    }

    func testXTZSecp() throws {
        let service = TezosAddressService(curve: .secp256k1)

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.value, "tz2SdMQ72FP39GB1Cwyvs2BPRRAMv9M6Pc6B")
    }

    func testXTZEd() throws {
        try testXTZ(curve: .ed25519)
    }

    func testXtestXTZEdSlip0010TZEd() throws {
        try testXTZ(curve: .ed25519_slip0010)
    }

    func testXTZ(curve: EllipticCurve) throws {
        let service = TezosAddressService(curve: curve)
        let address = try service.makeAddress(from: edKey)

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(address.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(address.value, "tz1VS42nEFHoTayE44ZKANQWNhZ4QbWFV8qd")
    }

    func testDoge() throws {
        let blockchain = Blockchain.dogecoin
        let service = BitcoinLegacyAddressService(networkParams: DogecoinNetworkParams())

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, "DMbHXKA4pE7Wz1ay6Rs4s4CkQ7EvKG3DqY")
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_comp.value, "DNscoo1xY2Vja65mXgNhhsPFUKWMa7NLEb")

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp.value)
    }

    func testBsc() throws {
        let blockchain = Blockchain.bsc(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp.value)
    }

    func testBscTestnet() throws {
        let blockchain = Blockchain.ethereum(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum
    }

    func testPolygon() throws {
        let blockchain = Blockchain.polygon(testnet: false)
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") // without checksum

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp.value)
    }

    func testSolanaEd25519() throws {
        try testSolana(curve: .ed25519)
    }

    func testSolanaEd25519Slip0010() throws {
        try testSolana(curve: .ed25519_slip0010)
    }

    func testSolana(curve: EllipticCurve) throws {
        let key = Data(hexString: "0300000000000000000000000000000000000000000000000000000000000000")
        let blockchain = Blockchain.solana(curve: curve, testnet: false)
        let service = SolanaAddressService()

        let addrs = try service.makeAddress(from: key)

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs.value, "CiDwVBFgWV9E5MvXWoLgnEgn2hK7rJikbvfWavzAQz3")

        let addrFromTangemKey = try service.makeAddress(from: edKey)
        XCTAssertEqual(addrFromTangemKey.value, "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ")

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: edKey, for: blockchain), addrFromTangemKey.value)

        // From WalletCore
        XCTAssertTrue(service.validate("2gVkYWexTHR5Hb2aLeQN3tnngvWzisFKXDUPrgMHpdST")) // OK
        XCTAssertFalse(service.validate("2gVkYWexTHR5Hb2aLeQN3tnngvWzisFKXDUPrgMHpdSl")) // Contains invalid base-58 character
        XCTAssertFalse(service.validate("2gVkYWexTHR5Hb2aLeQN3tnngvWzisFKXDUPrgMHpd")) // Is invalid length

        XCTAssertFalse(service.validate("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")) // Ethereum address
    }

    func testPolkadot() throws {
        // From trust wallet `PolkadotTests.swift`
        let privateKey = Data(hexString: "0xd65ed4c1a742699b2e20c0c1f1fe780878b1b9f7d387f934fe0a7dc36f1f9008")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        testSubstrateNetwork(
            .polkadot(curve: .ed25519, testnet: false),
            publicKey: publicKey,
            expectedAddress: "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW"
        )

        testSubstrateNetwork(
            .polkadot(curve: .ed25519_slip0010, testnet: false),
            publicKey: publicKey,
            expectedAddress: "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW"
        )

        testSubstrateNetwork(
            .polkadot(curve: .ed25519, testnet: false),
            publicKey: edKey,
            expectedAddress: "14cermZiQ83ihmHKkAucgBT2sqiRVvd4rwqBGqrMnowAKYRp"
        )

        testSubstrateNetwork(
            .polkadot(curve: .ed25519_slip0010, testnet: false),
            publicKey: edKey,
            expectedAddress: "14cermZiQ83ihmHKkAucgBT2sqiRVvd4rwqBGqrMnowAKYRp"
        )
    }

    func testKusama() throws {
        // From trust wallet `KusamaTests.swift`
        let privateKey = Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        testSubstrateNetwork(
            .kusama(curve: .ed25519),
            publicKey: publicKey,
            expectedAddress: "HewiDTQv92L2bVtkziZC8ASxrFUxr6ajQ62RXAnwQ8FDVmg"
        )

        testSubstrateNetwork(
            .kusama(curve: .ed25519_slip0010),
            publicKey: publicKey,
            expectedAddress: "HewiDTQv92L2bVtkziZC8ASxrFUxr6ajQ62RXAnwQ8FDVmg"
        )

        testSubstrateNetwork(
            .kusama(curve: .ed25519),
            publicKey: edKey,
            expectedAddress: "GByNkeXAhoB1t6FZEffRyytAp11cHt7EpwSWD8xiX88tLdQ"
        )

        testSubstrateNetwork(
            .kusama(curve: .ed25519_slip0010),
            publicKey: edKey,
            expectedAddress: "GByNkeXAhoB1t6FZEffRyytAp11cHt7EpwSWD8xiX88tLdQ"
        )
    }

    func testWestend() {
        testSubstrateNetwork(
            .polkadot(curve: .ed25519, testnet: true),
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )

        testSubstrateNetwork(
            .polkadot(curve: .ed25519_slip0010, testnet: true),
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }

    func testAzero() {
        testSubstrateNetwork(
            .azero(curve: .ed25519, testnet: true),
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )

        testSubstrateNetwork(
            .azero(curve: .ed25519_slip0010, testnet: true),
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }

    func testJoystream() {
        testSubstrateNetwork(
            .joystream(curve: .ed25519),
            publicKey: edKey,
            expectedAddress: "j4UwGHUYcR4HH6qiZ4WJJPBKsYboMJWe6WPj8V6uKfo4Gnhbt"
        )

        testSubstrateNetwork(
            .joystream(curve: .ed25519_slip0010),
            publicKey: edKey,
            expectedAddress: "j4UwGHUYcR4HH6qiZ4WJJPBKsYboMJWe6WPj8V6uKfo4Gnhbt"
        )
    }

    func testBittensor() throws {
        testSubstrateNetwork(
            .bittensor(curve: .ed25519),
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )

        testSubstrateNetwork(
            .bittensor(curve: .ed25519_slip0010),
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }

    func testSubstrateNetwork(_ blockchain: Blockchain, publicKey: Data, expectedAddress: String) {
        let network = PolkadotNetwork(blockchain: blockchain)!
        let service = PolkadotAddressService(network: network)

        let address = try! service.makeAddress(from: publicKey)
        let addressFromString = PolkadotAddress(string: expectedAddress, network: network)

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        guard let addressFromString else {
            XCTFail()
            return
        }
        XCTAssertEqual(addressFromString.bytes(raw: true), publicKey)
        XCTAssertEqual(address.value, expectedAddress)
        XCTAssertNotEqual(addressFromString.bytes(raw: false), publicKey)
    }

    func testTron() throws {
        // From https://developers.tron.network/docs/account
        let blockchain = Blockchain.tron(testnet: false)
        let service = TronAddressService()

        let publicKey = Data(hexString: "0404B604296010A55D40000B798EE8454ECCC1F8900E70B1ADF47C9887625D8BAE3866351A6FA0B5370623268410D33D345F63344121455849C9C28F9389ED9731")
        let address = try service.makeAddress(from: publicKey)
        XCTAssertEqual(address.value, "TDpBe64DqirkKWj6HWuR1pWgmnhw2wDacE")

        let compressedKeyAddress = try service.makeAddress(from: secpCompressedKey)
        XCTAssertEqual(compressedKeyAddress.value, "TL51KaL2EPoAnPLgnzdZndaTLEbd1P5UzV")

        let decompressedKeyAddress = try service.makeAddress(from: secpDecompressedKey)
        XCTAssertEqual(decompressedKeyAddress.value, "TL51KaL2EPoAnPLgnzdZndaTLEbd1P5UzV")

        XCTAssertTrue(service.validate("TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"))
        XCTAssertFalse(service.validate("RJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"))

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: publicKey, for: blockchain), address.value)
    }

    // MARK: - Dash addresses

    func testDashCompressedMainnet() throws {
        // given
        let blockchain = Blockchain.dash(testnet: false)
        let service = BitcoinLegacyAddressService(networkParams: DashMainNetworkParams())
        let expectedAddress = "XtRN6njDCKp3C2VkeyhN1duSRXMkHPGLgH"

        // when
        let address = try service.makeAddress(from: secpCompressedKey)

        // then
        XCTAssertEqual(address.value, expectedAddress)
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpCompressedKey, for: blockchain), address.value)
    }

    func testDashDecompressedMainnet() throws {
        // given
        let service = BitcoinLegacyAddressService(networkParams: DashMainNetworkParams())
        let expectedAddress = "Xs92pJsKUXRpbwzxDjBjApiwMK6JysNntG"

        // when
        let address = try service.makeAddress(from: secpDecompressedKey)

        // then
        XCTAssertEqual(address.value, expectedAddress)
    }

    func testDashTestnet() throws {
        // given
        let service = BitcoinLegacyAddressService(networkParams: DashTestNetworkParams())
        let expectedAddress = "yMfdoASh4QEM3zVpZqgXJ8St38X7VWnzp7"
        let compressedKey = Data(
            hexString: "021DCF0C1E183089515DF8C86DACE6DA08DC8E1232EA694388E49C3C66EB79A418"
        )

        // when
        let address = try service.makeAddress(from: compressedKey)

        // then
        XCTAssertEqual(address.value, expectedAddress)
    }

    func testTONEd25519() {
        testTON(curve: .ed25519)
    }

    func testTONEd25519Slip0010() {
        testTON(curve: .ed25519_slip0010)
    }

    func testTON(curve: EllipticCurve) {
        let blockchain = Blockchain.ton(curve: curve, testnet: false)
        let addressService = WalletCoreAddressService(coin: .ton)

        let walletPubkey1 = Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb")
        let expectedAddress1 = "UQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrdpr"
        XCTAssertEqual(try addressService.makeAddress(from: walletPubkey1).value, expectedAddress1)

        let walletPubkey2 = Data(hex: "258A89B60CCE7EB3339BF4DB8A8DA8153AA2B6489D22CC594E50FDF626DA7AF5")
        let expectedAddress2 = "UQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eL1z"
        XCTAssertEqual(try addressService.makeAddress(from: walletPubkey2).value, expectedAddress2)

        let walletPubkey3 = Data(hex: "f42c77f931bea20ec5d0150731276bbb2e2860947661245b2319ef8133ee8d41")
        let expectedAddress3 = "UQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts4DV"
        XCTAssertEqual(try addressService.makeAddress(from: walletPubkey3).value, expectedAddress3)

        let walletPubkey4 = Data(hexString: "0404B604296010A55D40000B798EE8454ECCC1F8900E70B1ADF47C9887625D8BAE3866351A6FA0B5370623268410D33D345F63344121455849C9C28F9389ED9731")
        XCTAssertNil(try? addressService.makeAddress(from: walletPubkey4))

        let walletPubkey5 = Data(hexString: "042A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D8936D318D49FE06E3437E31568B338B340F4E6DF5184E1EC5840F2B7F4596902AE")
        XCTAssertNil(try? addressService.makeAddress(from: walletPubkey5))

        XCTAssertNil(try? addressService.makeAddress(from: secpCompressedKey))

        XCTAssertNil(try? addressService.makeAddress(from: secpDecompressedKey))

        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: walletPubkey1, for: blockchain), expectedAddress1)
    }

    func testTONValidateCorrectAddress() {
        let addressService = WalletCoreAddressService(coin: .ton)

        XCTAssertTrue(addressService.validate("UQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrdpr"))
        XCTAssertTrue(addressService.validate("UQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eL1z"))
        XCTAssertTrue(addressService.validate("UQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts4DV"))
        XCTAssertTrue(addressService.validate("0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"))
        XCTAssertTrue(addressService.validate("0:66fbe3c5c03bf5c82792f904c9f8bf28894a6aa3d213d41c20569b654aadedb3"))
        XCTAssertFalse(addressService.validate("8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"))
    }

    func testKaspaAddressGeneration() throws {
        let addressService = KaspaAddressService(isTestnet: false)

        let expectedAddress = "kaspa:qypyrhxkfd055qulcvu6zccq4qe63qajrzgf7t4u4uusveguw6zzc3grrceeuex"
        XCTAssertEqual(try addressService.makeAddress(from: secpCompressedKey).value, expectedAddress)
        XCTAssertEqual(try addressService.makeAddress(from: secpDecompressedKey).value, expectedAddress)

        // https://github.com/kaspanet/kaspad/pull/2202/files
        // https://github.com/kaspanet/kaspad/blob/dev/util/address_test.go
        let kaspaTestPublicKey = Data([
            0x02, 0xf1, 0xd3, 0x78, 0x05, 0x46, 0xda, 0x20, 0x72, 0x8e, 0xa8, 0xa1, 0xf5, 0xe5, 0xe5, 0x1b, 0x84, 0x38, 0x00, 0x2c, 0xd7, 0xc8, 0x38, 0x2a, 0xaf, 0xa7, 0xdd, 0xf6, 0x80, 0xe1, 0x25, 0x57, 0xe4,
        ])
        let kaspaTestAddress = "kaspa:qyp0r5mcq4rd5grj3652ra09u5dcgwqq9ntuswp247nama5quyj40eq03sc2dkx"
        XCTAssertEqual(try addressService.makeAddress(from: kaspaTestPublicKey).value, kaspaTestAddress)

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }

    func testKaspaAddressComponentsAndValidation() throws {
        let addressService = KaspaAddressService(isTestnet: false)

        XCTAssertFalse(addressService.validate("kaspb:qyp5ez9p4q6xnh0jp5xq0ewy58nmsde5uus7vrty9w222v3zc37xwrgeqhkq7v3"))
        XCTAssertFalse(addressService.validate("kaspa:qyp5ez9p4q6xnh0jp5xq0ewy58nmsde5uus7vrty9w222v3zc37xwrgeqhkq7v4"))

        let ecdsaAddress = "kaspa:qyp4scvsxvkrjxyq98gd4xedhgrqtmf78l7wl8p8p4j0mjuvpwjg5cqhy97n472"
        let ecdsaAddressComponents = addressService.parse(ecdsaAddress)!
        XCTAssertTrue(addressService.validate(ecdsaAddress))
        XCTAssertEqual(ecdsaAddressComponents.hash, Data(hex: "03586190332c39188029d0da9b2dba0605ed3e3ffcef9c270d64fdcb8c0ba48a60"))
        XCTAssertEqual(ecdsaAddressComponents.type, .P2PK_ECDSA)

        let schnorrAddress = "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv"
        let schnorrAddressComponents = addressService.parse(schnorrAddress)!
        XCTAssertTrue(addressService.validate(schnorrAddress))
        XCTAssertEqual(schnorrAddressComponents.hash, Data(hex: "60072BBDDB7A7D1DBF40302CE04D51DB49E223F8E5159FCCE14143FD4BE20328"))
        XCTAssertEqual(schnorrAddressComponents.type, .P2PK_Schnorr)

        let p2shAddress = "kaspa:pqurku73qluhxrmvyj799yeyptpmsflpnc8pha80z6zjh6efwg3v2rrepjm5r"
        let p2shAddressComponents = addressService.parse(p2shAddress)!
        XCTAssertTrue(addressService.validate(p2shAddress))
        XCTAssertEqual(p2shAddressComponents.hash, Data(hex: "383b73d107f9730f6c24bc5293240ac3b827e19e0e1bf4ef16852beb297222c5"))
        XCTAssertEqual(p2shAddressComponents.type, .P2SH)
    }

    func testRavencoinAddress() throws {
        let addressService = BitcoinLegacyAddressService(networkParams: RavencoinMainNetworkParams())

        let compAddress = try addressService.makeAddress(from: secpCompressedKey)
        let expectedCompAddress = "RT1iM3xbqSQ276GNGGNGFdYrMTEeq4hXRH"
        XCTAssertEqual(compAddress.value, expectedCompAddress)

        let decompAddress = try addressService.makeAddress(from: secpDecompressedKey)
        let expectedDecompAddress = "RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi"
        XCTAssertEqual(decompAddress.value, expectedDecompAddress)

        XCTAssertTrue(addressService.validate(compAddress.value))
        XCTAssertTrue(addressService.validate(decompAddress.value))
    }

    func testCosmosAddress() throws {
        let addressService = WalletCoreAddressService(coin: .cosmos)

        let expectedAddress = "cosmos1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5emztyek"
        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpCompressedKey).value)
        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpDecompressedKey).value)

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))

        let validAddresses = [
            "cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02",
            "cosmospub1addwnpepqftjsmkr7d7nx4tmhw4qqze8w39vjq364xt8etn45xqarlu3l2wu2n7pgrq",
            "cosmosvaloper1sxx9mszve0gaedz5ld7qdkjkfv8z992ax69k08",
            "cosmosvalconspub1zcjduepqjnnwe2jsywv0kfc97pz04zkm7tc9k2437cde2my3y5js9t7cw9mstfg3sa",
        ]

        for validAddress in validAddresses {
            XCTAssertTrue(addressService.validate(validAddress))
        }

        let invalidAddresses = [
            "cosmoz1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02",
            "osmo1mky69cn8ektwy0845vec9upsdphktxt0en97f5",
            "cosmosvaloper1sxx9mszve0gaedz5ld7qdkjkfv8z992ax69k03",
            "cosmosvalconspub1zcjduepqjnnwe2jsywv0kfc97pz04zkm7tc9k2437cde2my3y5js9t7cw9mstfg3sb",
        ]
        for invalidAddress in invalidAddresses {
            XCTAssertFalse(addressService.validate(invalidAddress))
        }
    }

    func testTerraAddress() throws {
        let blockchains: [Blockchain] = [
            .terraV1,
            .terraV2,
        ]

        for blockchain in blockchains {
            try testTerraAddress(blockchain: blockchain)
        }
    }

    func testTerraAddress(blockchain: Blockchain) throws {
        let addressService = WalletCoreAddressService(blockchain: blockchain)
        let expectedAddress = "terra1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eax3ymk"

        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpCompressedKey).value)
        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpDecompressedKey).value)

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))

        XCTAssertTrue(addressService.validate("terra1hdp298kaz0eezpgl6scsykxljrje3667d233ms"))
        XCTAssertTrue(addressService.validate("terravaloper1pdx498r0hrc2fj36sjhs8vuhrz9hd2cw0yhqtk"))
        XCTAssertFalse(addressService.validate("cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02"))
    }

    func testChiaAddressService() throws {
        let blockchain = Blockchain.chia(testnet: true)
        let addressService = ChiaAddressService(isTestnet: blockchain.isTestnet)

        let address = try addressService.makeAddress(
            from: Data(hex: "b8f7dd239557ff8c49d338f89ac1a258a863fa52cd0a502e3aaae4b6738ba39ac8d982215aa3fa16bc5f8cb7e44b954d")
        ).value

        let expectedAddress = "txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f6jvdgkmf5gtq8g3aw3"

        XCTAssertEqual(expectedAddress, address)

        XCTAssertTrue(addressService.validate("txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f6jvdgkmf5gtq8g3aw3"))
        XCTAssertTrue(addressService.validate("txch1rpu5dtkfkn48dv5dmpl00hd86t8jqvskswv8vlqz2nlucrrysxfscxm96k"))
        XCTAssertTrue(addressService.validate("txch1lhfzlt7tz8whecqnnrha4kcxgfk9ct77j0aq0a844766fpjfv2rsp9wgas"))

        XCTAssertFalse(addressService.validate("txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f"))
        XCTAssertFalse(addressService.validate("txch1rpu5dtkfkn48dv5dmpl00hd86t8jqvskswv8vlqz2nlucrrysxfscxm96667d233ms"))
        XCTAssertFalse(addressService.validate("xch1lhfzlt7tz8whecqnnrha4kcxgfk9ct77j0aq0a844766fpjfv2rsp9wgas"))
    }

    func testNEAREd25519() throws {
        let blockchain: Blockchain = .near(curve: .ed25519, testnet: false)
        try testNEARAddressGeneration(blockchain: blockchain)
        try testNEARAddressValidation(blockchain: blockchain)
    }

    func testNEAREd25519Slip0010() throws {
        let blockchain: Blockchain = .near(curve: .ed25519_slip0010, testnet: false)
        try testNEARAddressGeneration(blockchain: blockchain)
        try testNEARAddressValidation(blockchain: blockchain)
    }

    private func testNEARAddressGeneration(blockchain: Blockchain) throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        // Generated by Trust Wallet / official NEAR web wallet (https://wallet.near.org/) / Wallet 2.0
        // for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury" mnemonic
        let expectedAddress = "b5cf12d432ee87dbc664e2700eeef72b3e814879b978bb9491e5796a63e85ee4"

        // Private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury" mnemonic
        let privateKey = "4z9uzXnZHE6huxMbnV7egjpvQk6ov7eji3FM12buV8DDtkARhiDqiCoDxSa3VpBMKYzzjmJcVXXyw8qhYgTs6MfH"
            .base58DecodedData[0 ..< 32]

        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
            .publicKey
            .rawRepresentation

        XCTAssertNoThrow(try addressService.makeAddress(from: publicKey))
        XCTAssertThrowsError(try addressService.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try addressService.makeAddress(from: secpDecompressedKey))

        let address = try addressService.makeAddress(from: publicKey)

        XCTAssertEqual(AddressType.default.defaultLocalizedName, address.localizedName)
        XCTAssertEqual(expectedAddress, address.value)
    }

    private func testNEARAddressValidation(blockchain: Blockchain) throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        XCTAssertTrue(addressService.validate("f69cd39f654845e2059899a888681187f2cda95f29256329aea1700f50f8ae86"))
        XCTAssertTrue(addressService.validate("75149e81ac9ea0bcb6f00faee922f71a11271f6cbc55bac97753603504d7bf27"))
        XCTAssertTrue(addressService.validate("64acf5e86c840024032d7e75ec569a4d304443e250b197d5a0246d2d49afc8e1"))
        XCTAssertTrue(addressService.validate("84a3fe2fc0e585d802cfa160807d1bf8ca5f949cf8d04d128bf984c50aabab7b"))
        XCTAssertTrue(addressService.validate("d85d322043d87cc475d3523d6fb0c3df903d3830e5d4d5027ffe565e7b8652bb"))
        XCTAssertTrue(addressService.validate("f69cd39f654845e2059899a88868.1187f2cda95f29256329aea1700f50f8ae8"))
        XCTAssertTrue(addressService.validate("something.near"))
        XCTAssertTrue(addressService.validate("6f8a1e9b0c2d3f4a5b7e8d9a1c32ed5f67b8cd0e1f23b4c5d6e7f88023a"))
        XCTAssertTrue(addressService.validate("ctiud11caxsb2tw7dmfcrhfw9ah15ltkydrjfblst32986pekmb3dsvyrmyym6qn"))
        XCTAssertTrue(addressService.validate("ok"))
        XCTAssertTrue(addressService.validate("bowen"))
        XCTAssertTrue(addressService.validate("ek-2"))
        XCTAssertTrue(addressService.validate("ek.near"))
        XCTAssertTrue(addressService.validate("com"))
        XCTAssertTrue(addressService.validate("google.com"))
        XCTAssertTrue(addressService.validate("bowen.google.com"))
        XCTAssertTrue(addressService.validate("near"))
        XCTAssertTrue(addressService.validate("illia.cheap-accounts.near"))
        XCTAssertTrue(addressService.validate("max_99.near"))
        XCTAssertTrue(addressService.validate("100"))
        XCTAssertTrue(addressService.validate("near2019"))
        XCTAssertTrue(addressService.validate("over.9000"))
        XCTAssertTrue(addressService.validate("a.bro"))
        XCTAssertTrue(addressService.validate("bro.a"))

        XCTAssertFalse(addressService.validate(""))
        XCTAssertFalse(addressService.validate("9a4b6c1e2d8f3a5b7e8d9a1c3b2e4d5f6a7b8c9d0e1f2a3b4c5d6e7f8a4b6c1e2d8f3"))
        XCTAssertFalse(addressService.validate("not ok"))
        XCTAssertFalse(addressService.validate("a"))
        XCTAssertFalse(addressService.validate("100-"))
        XCTAssertFalse(addressService.validate("bo__wen"))
        XCTAssertFalse(addressService.validate("_illia"))
        XCTAssertFalse(addressService.validate(".near"))
        XCTAssertFalse(addressService.validate("near."))
        XCTAssertFalse(addressService.validate("a..near"))
        XCTAssertFalse(addressService.validate("$$$"))
        XCTAssertFalse(addressService.validate("WAT"))
        XCTAssertFalse(addressService.validate("me@google.com"))
        XCTAssertFalse(addressService.validate("system"))
        XCTAssertFalse(addressService.validate("abcdefghijklmnopqrstuvwxyz.abcdefghijklmnopqrstuvwxyz.abcdefghijklmnopqrstuvwxyz"))
        XCTAssertFalse(addressService.validate(""))
        XCTAssertFalse(addressService.validate("9a4b6c1e2d8f3a5b7e8d9a1c3b2e4d5f6a7b8c9d0e1f2a3b4c5d6e7f8a4b6c1e2d8f3"))
    }

    func testDecimalAddressService() throws {
        let walletPublicKey = Data(hexString: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820"
        )

        let addressService = DecimalAddressService()
        let plainAddress = try addressService.makeAddress(from: walletPublicKey)

        let expectedAddress = "d01ccmkx4edg5t3unp9egyp3dzwthtlts2m320gh9"

        XCTAssertEqual(plainAddress.value, expectedAddress)
    }

    func testDecimalValidateCorrectAddressWithChecksum() throws {
        XCTAssertTrue(DecimalAddressService().validate("0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B"))
        XCTAssertTrue(DecimalAddressService().validate("d01ccmkx4edg5t3unp9egyp3dzwthtlts2m320gh9"))

        XCTAssertFalse(DecimalAddressService().validate("0xc63763572D45171e4C25cA0818b4"))
        XCTAssertFalse(DecimalAddressService().validate("d01ccmkx4edg5t3unp9egyp3dzwtht"))
        XCTAssertFalse(DecimalAddressService().validate(""))
    }

    func testDecimalValidateConverterAddressUtils() throws {
        let converter = DecimalAddressConverter()

        let ercAddress = try converter.convertToDecimalAddress("0xc63763572d45171e4c25ca0818b44e5dd7f5c15b")
        XCTAssertEqual(ercAddress, "d01ccmkx4edg5t3unp9egyp3dzwthtlts2m320gh9")

        let dscAddress = try converter.convertToETHAddress("d01ccmkx4edg5t3unp9egyp3dzwthtlts2m320gh9")
        XCTAssertEqual(dscAddress, "0xc63763572d45171e4c25ca0818b44e5dd7f5c15b")
    }

    func testVeChainAddressGeneration() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .veChain(testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        // Private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury" mnemonic
        let privateKeyRaw = Data(hexString: "0x11573efc409f42822eb39ca248d5e39edcf3377f0d4049b633d4dac3a54d5e71")
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))

        let publicKeyRaw = privateKey.getPublicKeySecp256k1(compressed: false).data
        let publicKey = Wallet.PublicKey(seedKey: publicKeyRaw, derivationType: nil)

        XCTAssertNoThrow(try addressService.makeAddress(for: publicKey, with: .default))
        XCTAssertNoThrow(try addressService.makeAddress(from: secpCompressedKey))
        XCTAssertNoThrow(try addressService.makeAddress(from: secpDecompressedKey))
        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))

        // Generated by Trust Wallet / official VeChain wallet (https://www.veworld.net/) / Wallet 2.0
        // for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury" mnemonic
        let expectedAddress = "0xce270ba263dbB31FEb49Ec769A2C50FeCE7a6130"
        let address = try addressService.makeAddress(for: publicKey, with: .default)

        XCTAssertEqual(AddressType.default.defaultLocalizedName, address.localizedName)
        XCTAssertEqual(expectedAddress, address.value)
    }

    func testVeChainAddressValidation() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .veChain(testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        XCTAssertTrue(addressService.validate("0x154D3D331CAAd4c8A14a3CbFd36Fd0640ADB76ad"))
        XCTAssertTrue(addressService.validate("0xFF5ba88a17b2E16D23FF6647E9052E937AcB1406"))
        XCTAssertTrue(addressService.validate("0x8E2b322FB0d0b7dC83783678c4d10ED64Af92dB4"))
        XCTAssertTrue(addressService.validate("0xe01f4CeC65D6F0BA0eC92e96012339eDbAc634bb"))
        XCTAssertTrue(addressService.validate("0xFF5ba88a17b2E16D23FF6647E9052E937AcB1406"))

        XCTAssertFalse(addressService.validate("0x11e1B586dd370471D0B52046EE3D4309a6c29C6"))
        XCTAssertFalse(addressService.validate("0xddde7ddd4111A54eFF5679CDE026913692e0B71cC"))
        XCTAssertFalse(addressService.validate("c8177346deb2bab5390f472c338351e15e05063a"))
        XCTAssertFalse(addressService.validate("me@google.com"))
        XCTAssertFalse(addressService.validate(""))
    }

    func testXDCAddressConversion() throws {
        let ethAddr = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"
        let xdcAddr = "xdc6ECa00c52AFC728CDbF42E817d712e175bb23C7d"
        let converter = XDCAddressConverter()
        XCTAssertEqual(try converter.convertToETHAddress(ethAddr), ethAddr)
        XCTAssertEqual(try converter.convertToETHAddress(xdcAddr), ethAddr)
        XCTAssertEqual(converter.convertToXDCAddress(ethAddr), xdcAddr)
        XCTAssertEqual(converter.convertToXDCAddress(xdcAddr), xdcAddr)
    }

    func testXDCAddressValidation() throws {
        let ethAddr = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"
        let xdcAddr = "xdc6ECa00c52AFC728CDbF42E817d712e175bb23C7d"
        let validator = XDCAddressService()
        XCTAssertTrue(validator.validate(ethAddr))
        XCTAssertTrue(validator.validate(xdcAddr))
    }

    func testAlgorandAddressGeneration() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .algorand(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        let privateKey = Data(hexString: "a6c4394041e64fe93d889386d7922af1b9a87f12e433762759608e61434d6cf7")

        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
            .publicKey
            .rawRepresentation

        let address = try addressService.makeAddress(from: publicKey).value
        let expectedAddress = "ADIYK65L3XR5ODNNCUIQVEET455L56MRKJHRBX5GU4TZI2752QIWK4UL5A"

        XCTAssertNoThrow(try addressService.makeAddress(from: publicKey))
        XCTAssertThrowsError(try addressService.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try addressService.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(address, expectedAddress)
    }

    func testAlgorandAddressValidation() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .algorand(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        XCTAssertTrue(addressService.validate("ZW3ISEHZUHPO7OZGMKLKIIMKVICOUDRCERI454I3DB2BH52HGLSO67W754"))
        XCTAssertTrue(addressService.validate("Q7AUUQCAO3O6CLPHMPTWN3VTCWLLWZJSI6QDO5XEC4ZZR5JZWXWZL5YWOM"))
        XCTAssertTrue(addressService.validate("ZMORINNT75RZ67ZWV2EGZYW6MKZ2LOSSB5VTKJON6NSPO5MW6TVCMXMVTU"))
        XCTAssertTrue(addressService.validate("ZW3ISEHZUHPO7OZGMKLKIIMKVICOUDRCERI454I3DB2BH52HGLSO67W754"))

        XCTAssertFalse(addressService.validate("ZW3ISEHZUHPO7OZGMKLKIIMKVICOUDRCERI454I3DB2BH52HGL"))
        XCTAssertFalse(addressService.validate("EEQKMHD64P5FN25Y6W63ZHEPVCQZKM4PCMF6ZIIJW4IPFX4WJALA"))
        XCTAssertFalse(addressService.validate("44bc93A8d3cEfA5a6721723a2f8d2e4F7d480BA0"))
        XCTAssertFalse(addressService.validate("0xf3d468DBb386aaD46E92FF222adDdf872C8CC06"))
        XCTAssertFalse(addressService.validate("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d1"))
        XCTAssertFalse(addressService.validate("me@google.com"))
        XCTAssertFalse(addressService.validate(""))
    }

    func testAptosAddressGeneration() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .aptos(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        let privateKey = Data(hexString: "a6c4394041e64fe93d889386d7922af1b9a87f12e433762759608e61434d6cf7")

        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
            .publicKey
            .rawRepresentation

        let address = try addressService.makeAddress(from: publicKey).value
        let expectedAddress = "0x31f64c99e5a0e954271404bf5841e9cb8dbba0b1c25d79f6751e46762c446cc3"

        XCTAssertNoThrow(try addressService.makeAddress(from: publicKey))
        XCTAssertThrowsError(try addressService.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try addressService.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(address, expectedAddress)
    }

    func testAptosAddressValidation() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .aptos(curve: .ed25519_slip0010, testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        XCTAssertTrue(addressService.validate("0x77b6ecc77530f2b7cad89abcdd8dfece24a9cba20acc608cee424f30d3721ea1"))
        XCTAssertTrue(addressService.validate("0x7d7e436f0b2aafde60774efb26ccc432cf881b677aca7faaf2a01879bd19fb8"))
        XCTAssertTrue(addressService.validate("0x68c709c6614e29f401b6bfdd0b89578381ef0fb719515c03b73cf13e45550e06"))
        XCTAssertTrue(addressService.validate("0x8d2d7bcde13b2513617df3f98cdd5d0e4b9f714c6308b9204fe18ad900d92609"))

        XCTAssertFalse(addressService.validate("0x7d7e436f0askdjaksldb2aafde60774efb26cccll432cf881b677aca7faaf2a01879bd19fb8"))
        XCTAssertFalse(addressService.validate("me@0x1.com"))
        XCTAssertFalse(addressService.validate("me@google.com"))
        XCTAssertFalse(addressService.validate("x7d7e436f0askdjaksldb2aafde60774efb26cccll432cf881b677aca7faaf2a01879bd19fb8"))
        XCTAssertFalse(addressService.validate(""))
    }

    func testHederaEd25519() throws {
        // EdDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x302e020100300506032b657004220420ed05eaccdb9b54387e986166eae8f7032684943d28b2894db1ee0ff047c52451")

        // Hedera EdDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/e0cd39c84ab189d59a6bcedcf16e4102d7bb8beb/packages/cryptography/src/Ed25519PrivateKey.js#L8
        let hederaDerPrefixPrivate = Data(hexString: "0x302e020100300506032b657004220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .ed25519, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    func testHederaEd25519Slip0010() throws {
        // EdDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x302e020100300506032b657004220420ed05eaccdb9b54387e986166eae8f7032684943d28b2894db1ee0ff047c52451")

        // Hedera EdDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/e0cd39c84ab189d59a6bcedcf16e4102d7bb8beb/packages/cryptography/src/Ed25519PrivateKey.js#L8
        let hederaDerPrefixPrivate = Data(hexString: "0x302e020100300506032b657004220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .ed25519, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    func testHederaSecp256k1() throws {
        // ECDSA private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury"
        // mnemonic generated using Hedera JavaScript SDK
        let hederaPrivateKeyRaw = Data(hexString: "0x3030020100300706052b8104000a04220420e507077d8d5bab32debcbbc651fc4ca74660523976502beabee15a1662d77ed1")

        // Hedera ECDSA DER prefix:
        // https://github.com/hashgraph/hedera-sdk-js/blob/f65ab2a4cf5bb026fc47fcf8955e81c2b82a6ff3/packages/cryptography/src/EcdsaPrivateKey.js#L7
        let hederaDerPrefixPrivate = Data(hexString: "0x3030020100300706052b8104000a04220420")

        // Stripping out Hedera DER prefix from the given private key
        let privateKeyRaw = Data(hederaPrivateKeyRaw[hederaDerPrefixPrivate.count...])
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))

        let blockchain: Blockchain = .hedera(curve: .secp256k1, testnet: false)

        try testHederaAddressGeneration(blockchain: blockchain, privateKey: privateKey)
        try testHederaAddressValidation(blockchain: blockchain)
    }

    private func testHederaAddressGeneration(blockchain: Blockchain, privateKey: WalletCore.PrivateKey) throws {
        let publicKeyRaw = privateKey.getPublicKeyByType(pubkeyType: try .init(blockchain)).data
        let publicKey = Wallet.PublicKey(seedKey: publicKeyRaw, derivationType: nil)

        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        // Both ECDSA and EdDSA are supported
        XCTAssertNoThrow(try addressService.makeAddress(for: publicKey, with: .default))
        XCTAssertNoThrow(try addressService.makeAddress(from: secpCompressedKey))
        XCTAssertNoThrow(try addressService.makeAddress(from: secpDecompressedKey))
        XCTAssertNoThrow(try addressService.makeAddress(from: edKey))

        // Actual address (i.e. Account ID) for Hedera is requested asynchronously from the network/local storage,
        // therefore the address service returns an empty string, this is perfectly fine
        let expectedAddress = ""
        let address = try addressService.makeAddress(for: publicKey, with: .default)

        XCTAssertEqual(AddressType.default.defaultLocalizedName, address.localizedName)
        XCTAssertEqual(expectedAddress, address.value)
    }

    // Includes account IDs with checksums from https://hips.hedera.com/hip/hip-15
    private func testHederaAddressValidation(blockchain: Blockchain) throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: blockchain)
        let addressService = addressServiceFactory.makeAddressService()

        XCTAssertTrue(addressService.validate("0.0.123"))
        XCTAssertTrue(addressService.validate("0.0.123-vfmkw"))
        XCTAssertTrue(addressService.validate("0.0.1234567890-zbhlt"))
        XCTAssertTrue(addressService.validate("0.0.18446744073709551615")) // Max length of the account number part is 8 bytes (2^64 - 1)
        XCTAssertTrue(addressService.validate("0xf3DbcEeedDC4BBd1B66492B66EC0B8eC317b511B")) // Hedera supports EVM addresses
        XCTAssertTrue(addressService.validate("0.0.302d300706052b8104000a03220002d588ec1000770949ab77516c77ee729774de1c8fe058cab6d64f1b12ffc8ff07")) // Account Alias

        XCTAssertFalse(addressService.validate("0.0.123-abcde"))
        XCTAssertFalse(addressService.validate("0.0.123-VFMKW"))
        XCTAssertFalse(addressService.validate("0.0.123-vFmKw"))
        XCTAssertFalse(addressService.validate("0.0.123#vfmkw"))
        XCTAssertFalse(addressService.validate("0.0.123vfmkw"))
        XCTAssertFalse(addressService.validate("0.0.123 - vfmkw"))
        XCTAssertFalse(addressService.validate("0.123"))
        XCTAssertFalse(addressService.validate("0.0.123."))
        XCTAssertFalse(addressService.validate("0.0.123-vf"))
        XCTAssertFalse(addressService.validate("0.0.123-vfm-kw"))
        XCTAssertFalse(addressService.validate("0.0.123-vfmkwxxxx"))
        XCTAssertFalse(addressService.validate("0.0.18446744073709551616")) // Max length of the account number part is 8 bytes (2^64 - 1)
        XCTAssertFalse(addressService.validate("0xf64a1db2f124aaa4cd7b58d3d7f66774f9770c6")) // Hedera supports EVM addresses
        XCTAssertFalse(addressService.validate("0xf64a1db2f124aaa4cd7b58d3d7f66774f9770c6ee")) // Hedera supports EVM addresses
        XCTAssertFalse(addressService.validate("0.0.402d300706052b8104000a03220002d588ec1000770949ab77516c77ee729774de1c8fe058cab6d64f1b12ffc8ff07")) // Account Alias
        XCTAssertFalse(addressService.validate(""))
    }

    // MARK: - Radiant

    // Validate by https://github.com/RadiantBlockchain/radiantjs
    func testRadiantAddressGeneration() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .radiant(testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        let addr1 = try addressService.makeAddress(from: secpCompressedKey)
        XCTAssertEqual(addr1.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ")

        let addr2 = try addressService.makeAddress(from: secpDecompressedKey)
        XCTAssertEqual(addr2.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ")

        let anyOnePublicKey = Data(hexString: "039d645d2ce630c2a9a6dbe0cbd0a8fcb7b70241cb8a48424f25593290af2494b9")
        let addr3 = try addressService.makeAddress(from: anyOnePublicKey)

        XCTAssertEqual(addr3.value, "12dNaXQtN5Asn2YFwT1cvciCrJa525fAe4")

        let anyTwoPublicKey = Data(hexString: "03d6fde463a4d0f4decc6ab11be24e83c55a15f68fd5db561eebca021976215ff5")
        let addr4 = try addressService.makeAddress(from: anyTwoPublicKey)

        XCTAssertEqual(addr4.value, "166w5AGDyvMkJqfDAtLbTJeoQh6FqYCfLQ")

        // For ed25519 wrong make address from public key
        let edPublicKey = Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb")
        XCTAssertThrowsError(try addressService.makeAddress(from: edPublicKey))
    }

    // https://github.com/RadiantBlockchain/radiantjs/blob/master/test/address.js
    func testRadiantAddressValidation() throws {
        let addressServiceFactory = AddressServiceFactory(blockchain: .radiant(testnet: false))
        let addressService = addressServiceFactory.makeAddressService()

        XCTAssertTrue(addressService.validate("15vkcKf7gB23wLAnZLmbVuMiiVDc1Nm4a2"))
        XCTAssertTrue(addressService.validate("1A6ut1tWnUq1SEQLMr4ttDh24wcbJ5o9TT"))
        XCTAssertTrue(addressService.validate("1BpbpfLdY7oBS9gK7aDXgvMgr1DPvNhEB2"))
        XCTAssertTrue(addressService.validate("1Jz2yCRd5ST1p2gUqFB5wsSQfdm3jaFfg7"))
        XCTAssertTrue(addressService.validate("166w5AGDyvMkJqfDAtLbTJeoQh6FqYCfLQ"))
        XCTAssertTrue(addressService.validate("12dNaXQtN5Asn2YFwT1cvciCrJa525fAe4"))
        XCTAssertTrue(addressService.validate("1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ"))

        XCTAssertFalse(addressService.validate("342ftSRCvFHfCeFFBuz4xwbeqnDw6BGUey"))
        XCTAssertFalse(addressService.validate("3QjYXhTkvuj8qPaXHTTWb5wjXhdsLAAWVy"))
        XCTAssertFalse(addressService.validate("15vkcKf7gB23wLAnZLmbVuMiiVDc3nq4a2"))
        XCTAssertFalse(addressService.validate("1A6ut1tWnUq1SEQLMr4ttDh24wcbj4w2TT"))
        XCTAssertFalse(addressService.validate("1Jz2yCRd5ST1p2gUqFB5wsSQfdmEJaffg7"))
        XCTAssertFalse(addressService.validate("1BpbpfLdY7oBS9gK7aDXgvMgr1DpvNH3B2"))
    }

    func testICPAddressValidation() throws {
        let addressService = WalletCoreAddressService(blockchain: .internetComputer)
        let expectedAddress = "270b15681e87d9d878ddfcf1aae4c3174295f2182efa0e533e9585c7fb940bdc"

        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpDecompressedKey).value)

        XCTAssertTrue(addressService.validate("f7b1299849420e082bbdd9de92cb36e0645e7870513a6eb833d5449a88799699"))
    }

    func testCasperAddressGeneration() throws {
        let ed25519WalletPublicKey = Data(hexString: "98C07D7E72D89A681D7227A7AF8A6FD5F22FE0105C8741D55A95DF415454B82E")
        let ed25519ExpectedAddress = "0198c07D7e72D89A681d7227a7Af8A6fd5F22fe0105c8741d55A95dF415454b82E"

        let ed25519AddressService = CasperAddressService(curve: .ed25519)

        try XCTAssertEqual(ed25519AddressService.makeAddress(from: ed25519WalletPublicKey).value, ed25519ExpectedAddress)

        let secp256k1WalletPublicKey = Data(hexString: "021F997DFBBFD32817C0E110EAEE26BCBD2BB70B4640C515D9721C9664312EACD8")
        let secp256k1ExpectedAddress = "02021f997DfbbFd32817C0E110EAeE26BCbD2BB70b4640C515D9721c9664312eaCd8"

        let secp256k1AddressService = CasperAddressService(curve: .secp256k1)

        try XCTAssertEqual(secp256k1AddressService.makeAddress(from: secp256k1WalletPublicKey).value, secp256k1ExpectedAddress)

        let compressedKey = try secp256k1AddressService.makeAddress(from: secpCompressedKey)
        let decompressedKey = try secp256k1AddressService.makeAddress(from: secpDecompressedKey)

        XCTAssertEqual(compressedKey.value, decompressedKey.value)
    }

    func testCasperAddressValidation() {
        let ed25519Address = "0198c07D7e72D89A681d7227a7Af8A6fd5F22fe0105c8741d55A95dF415454b82E"
        let ed25519AddressService = CasperAddressService(curve: .ed25519)

        XCTAssertTrue(ed25519AddressService.validate(ed25519Address))

        let secp256k1Address = "02021f997DfbbFd32817C0E110EAeE26BCbD2BB70b4640C515D9721c9664312eaCd8"
        let secp256k1AddressService = CasperAddressService(curve: .secp256k1)

        XCTAssertTrue(secp256k1AddressService.validate(secp256k1Address))
    }

    // MARK: - Fact0rn

    func testFact0rnAddressGeneration() throws {
        let addressService = Fact0rnAddressService()
        let compressedKeyAddress = try addressService.makeAddress(from: secpCompressedKey)
        let decompressedKeyAddress = try addressService.makeAddress(from: secpDecompressedKey)

        XCTAssertEqual(compressedKeyAddress.value, "fact1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5ev0myww")
        XCTAssertEqual(decompressedKeyAddress.value, "fact1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5ev0myww")
        XCTAssertEqual(compressedKeyAddress.value, decompressedKeyAddress.value)

        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }

    func testFact0rnAddressAnyGeneration() throws {
        let walletPublicKey = Data(hexString: "03B6D7E1FB0977A5881A3B1F64F9778B4F56CB2B9EFD6E0D03E60051EAFEBF5831")
        let expectedAddress = "fact1qg2qvzvrgukkp5gct2n8dvuxz99ddxwecmx9sey"

        let addressService = Fact0rnAddressService()
        let address = try addressService.makeAddress(from: walletPublicKey)

        XCTAssertEqual(address.value, expectedAddress)
    }

    func testFact0rnAddressValidation() throws {
        let addressService = Fact0rnAddressService()

        let validAddresses = [
            "fact1qsev9cuanvdqwuh3gnkjaqdtjkeqcw5smex9dyx",
            "fact1qpr0t2aaus7wkerkhpqw4kh6z65pf33zcawx9t0",
            "fact1qsufztqay97de6073cxjd256mu6n9ruylydpzxf",
            "fact1qg2qvzvrgukkp5gct2n8dvuxz99ddxwecmx9sey",
        ]

        for validAddress in validAddresses {
            XCTAssertTrue(addressService.validate(validAddress))
        }

        let unValidAddresses = [
            "",
            "1q3n6x7kgsup6zlmpmndppx6ymtk6hxh4lnttt3y",
            "fact",
        ]

        for unValidAddress in unValidAddresses {
            XCTAssertFalse(addressService.validate(unValidAddress))
        }
    }

    func testMakeScriptHashFromAddress() throws {
        let expectedAddress = "fact1qg2qvzvrgukkp5gct2n8dvuxz99ddxwecmx9sey"
        let expectedScriptHash = "808171256649754B402099695833B95E4507019B3E494A7DBC6F62058F09050E"

        let scriptHash = try Fact0rnAddressService.addressToScriptHash(address: expectedAddress)
        XCTAssertEqual(scriptHash, expectedScriptHash)
    }
}
