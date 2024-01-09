// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import XCTest
import BlockchainSdk
import TangemSdk
@testable import Tangem

class EIP712TypedDataTests: XCTestCase {
    func jsonData(for fileName: String) throws -> Data {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: fileName, ofType: "json")!
        let string = try String(contentsOfFile: path)
        let jsonData = string.data(using: .utf8)!
        return jsonData
    }

    func typedData(for fileName: String) throws -> EIP712TypedData {
        let jsonData = try jsonData(for: fileName)
        let typedData = try JSONDecoder().decode(EIP712TypedData.self, from: jsonData)
        return typedData
    }

    func testSeaportData() throws {
        let fileName = "seaportTypedData"
        let jsonTypedData = try typedData(for: fileName)
        let hashToTest = jsonTypedData.signHash
        let expectedResult = "54140d99a864932cbc40fd8a2d1d1706c3923a79c183a3b151e929ac468064db"
        XCTAssertEqual(hashToTest.hexString.lowercased(), expectedResult)
    }

    func testDecode() {
        XCTAssertNoThrow(try typedData(for: "simpleDecode"))
    }

    func testDecode2() throws {
        let jsonTypedData = try typedData(for: "simpleDecode2")
        let result = "432c2e85cd4fb1991e30556bafe6d78422c6eeb812929bc1d2d4c7053998a4099c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000280000000000000000000000000000000000000000000000000000000000000001"
        let data = jsonTypedData.encodeData(data: jsonTypedData.message, type: jsonTypedData.primaryType)
        XCTAssertEqual(data.hexString.lowercased(), result)
    }

    func testGenericJSON() throws {
        let data = try jsonData(for: "simpleDecode3")
        let message = try JSONDecoder().decode(JSON.self, from: data)
        XCTAssertNil(try? JSONDecoder().decode(EIP712TypedData.self, from: data))
        XCTAssertNotNil(message["object"]?.objectValue)
        XCTAssertNotNil(message["array"]!.arrayValue)
        XCTAssertNotNil(message["array"]?[0]?.objectValue)

        XCTAssertTrue(message["object"]!["paid"]!.boolValue!)
        XCTAssertTrue(message["null"]!.isNull)
        XCTAssertFalse(message["bytes"]!.isNull)

        XCTAssertNil(message["number"]!.stringValue)
        XCTAssertNil(message["string"]!.intValue)
        XCTAssertNil(message["bytes"]!.boolValue)
        XCTAssertNil(message["object"]!.arrayValue)
        XCTAssertNil(message["array"]!.objectValue)
        XCTAssertNil(message["foo"])
        XCTAssertNil(message["array"]?[2])
    }

    func testEncodeType() throws {
        let typedData = try typedData(for: "simpleDecode")
        let result = "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
        XCTAssertEqual(typedData.makeTypeData(primaryType: "Mail"), result.data(using: .utf8)!)
    }

    func testEncodedTypeHash() throws {
        let typedData = try typedData(for: "simpleDecode")
        let result = "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2"
        XCTAssertEqual(typedData.typeHash.hexString.lowercased(), result)
    }

    func testEncodeData() throws {
        let typedData = try typedData(for: "simpleDecode")
        let result = "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8"
        let data = typedData.encodeData(data: typedData.message, type: typedData.primaryType)
        XCTAssertEqual(data.hexString.lowercased(), result)
    }

    func testStructHash() throws {
        let typedData = try typedData(for: "simpleDecode")
        let result = "c52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e"
        let data = typedData.encodeData(data: typedData.message, type: typedData.primaryType)
        XCTAssertEqual(data.sha3(.keccak256).hexString.lowercased(), result)

        let result2 = "f2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f"
        let data2 = typedData.encodeData(data: typedData.domain, type: "EIP712Domain")
        XCTAssertEqual(data2.sha3(.keccak256).hexString.lowercased(), result2)
    }

    func testAnotherTypedData() throws {
        let jsonTypedData = try typedData(for: "hashEncode")
        XCTAssertEqual(jsonTypedData.signHash.hexString.lowercased(), "be609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2")
    }

    func testAnotherTypedData1() throws {
        let jsonTypedData = try typedData(for: "hashEncode2")
        XCTAssertEqual(jsonTypedData.signHash.hexString.lowercased(), "55eaa6ec02f3224d30873577e9ddd069a288c16d6fb407210eecbc501fa76692")
    }

    func testV4() throws {
        let jsonTypedData = try typedData(for: "hashEncodev4")
        XCTAssertEqual(jsonTypedData.signHash.hexString.lowercased(), "f558d08ad4a7651dbc9ec028cfcb4a8e6878a249073ef4fa694f85ee95f61c0f")
    }

    func testNominex() throws {
        let jsonTypedData = try typedData(for: "Nominex") // fd40e2f0923c84b55aa3017cf9fc77466d49ba136e75f7e3bc0e0257d818b617
        XCTAssertEqual(jsonTypedData.signHash.hexString.lowercased(), "9bfa080e4705a0beacb2ab710480fb1176f6de9c4117ddf50f5933d3be1ab6a1")
    }

    func testRarible() throws {
        let jsonTypedData = try typedData(for: "rarible")
        XCTAssertEqual(jsonTypedData.signHash.hexString.lowercased(), "df0200de55c05eb55af2597012767ea3af653d68000be49580f8e05acd91d366")
    }

    func testCF() throws {
        let jsonTypedData = try typedData(for: "cryptofights")
        XCTAssertEqual(jsonTypedData.signHash.hexString.lowercased(), "db12328a6d193965801548e1174936c3aa7adbe1b54b3535a3c905bd4966467c")
    }

    func testWCExample() throws {
        let jsonTypedData = try typedData(for: "WCExample")
        XCTAssertEqual(jsonTypedData.signHash.hexString.lowercased(), "abc79f527273b9e7bca1b3f1ac6ad1a8431fa6dc34ece900deabcd6969856b5e")
    }
}
