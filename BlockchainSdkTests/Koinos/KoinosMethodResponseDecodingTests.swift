//
//  KoinosMethodResponseDecodingTests.swift
//  BlockchainSdkTests
//
//  Created by Aleksei Muraveinik on 28.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

final class KoinosMethodResponseDecodingTests: XCTestCase {
    private let decoder = JSONDecoder.withSnakeCaseStrategy
    
    func testGetAccountNonceResponseDecoding1() throws {
        let jsonData = """
        {
            "nonce": "KAA="
        }
        """
        .data(using: .utf8)
        
        let response = try decoder.decode(KoinosMethod.GetAccountNonce.Response.self, from: XCTUnwrap(jsonData))
        let nonce = try KoinosDTOMapper.convertNonce(response)
        
        XCTAssertEqual(nonce.nonce, 0)
    }
    
    func testGetAccountNonceResponseDecoding2() throws {
        let jsonData = """
        {
            "nonce": "KAE="
        }
        """
        .data(using: .utf8)
        
        let response = try decoder.decode(KoinosMethod.GetAccountNonce.Response.self, from: XCTUnwrap(jsonData))
        let nonce = try KoinosDTOMapper.convertNonce(response)
        
        XCTAssertEqual(nonce.nonce, 1)
    }
    
    func testNonceEncoding1() throws {
        let encodedNonce = try Koinos_Chain_value_type.with {
            $0.uint64Value = 0
        }
        .serializedData()
        .base64URLEncodedString()
        
        XCTAssertEqual(encodedNonce, "KAA=")
    }
    
    func testNonceEncoding2() throws {
        let encodedNonce = try Koinos_Chain_value_type.with {
            $0.uint64Value = 1
        }
        .serializedData()
        .base64URLEncodedString()
        
        XCTAssertEqual(encodedNonce, "KAE=")
    }
    
    func testDecodeSubmitTransaction() throws {
        let jsonData = """
        {
          "jsonrpc": "2.0",
          "result": {
            "receipt": {
              "compute_bandwidth_used": "567032",
              "events": [
                {
                  "data": "ChkA8mJA6tglu_8tyGCqJg4SHWI0-5vRA7HNEhkAUy8yqjA1wCRKcu3O-rjKtpusA3tLjzCzGICt4gQ=",
                  "source": "15DJN4a8SgrbGhhGksSBASiSYjGnMU8dGL",
                  "name": "koinos.contracts.token.transfer_event",
                  "impacted": [
                    "18aqdHq6UqinPwpnw3fRGhw9DEDLd2nxGz",
                    "1P6cEChFZqiuyEMJiooRSouSavwy6hTjFA"
                  ]
                }
              ],
              "id": "0x1220dcea440a0176cdea7ec2a2985bc9c2f31f05ecc653fbd91c4357c97e008feae1",
              "max_payer_rc": "145039218",
              "state_delta_entries": [
                {
                  "object_space": {
                    "system": true,
                    "id": 4
                  },
                  "key": "APJiQOrYJbv_LchgqiYOEh1iNPub0QOxzQ==",
                  "value": "KAk="
                },
                {
                  "object_space": {
                    "system": true,
                    "id": 1,
                    "zone": "AC4z_RqpB7IkzpzmyUIokB0oOgLalW2nkQ=="
                  },
                  "key": "AFMvMqowNcAkSnLtzvq4yrabrAN7S48wsw==",
                  "value": "CMCyzTsQt7_zKRiCouiGgzI="
                },
                {
                  "object_space": {
                    "system": true,
                    "id": 1,
                    "zone": "AC4z_RqpB7IkzpzmyUIokB0oOgLalW2nkQ=="
                  },
                  "key": "APJiQOrYJbv_LchgqiYOEh1iNPub0QOxzQ==",
                  "value": "CMDVkIMBEOLj1zcYgqLohoMy"
                }
              ],
              "rc_limit": "35926586",
              "rc_used": "18257680",
              "payer": "1P6cEChFZqiuyEMJiooRSouSavwy6hTjFA",
              "network_bandwidth_used": "311"
            }
          },
          "id": 1
        }
        """
        .data(using: .utf8)
        
        let response = try decoder
            .decode(
                JSONRPC.Response<
                    KoinosMethod.SubmitTransaction.Response,
                    JSONRPC.APIError
                >.self,
                from: XCTUnwrap(jsonData)
            )
        
        XCTAssertEqual(response.id, 1)
    }
    
    func testDecodeEmptyResult() throws {
        let jsonData = """
        {
            "jsonrpc": "2.0",
            "result": {
        
            },
            "id": 1
        }
        """
        .data(using: .utf8)
        
        let result = try decoder
            .decode(
                JSONRPC.Response<
                    KoinosMethod.ReadContract.Response,
                    JSONRPC.APIError
                >.self,
                from: XCTUnwrap(jsonData)
            )
        
        XCTAssertEqual(result.jsonrpc, "2.0")
        XCTAssertEqual(result.id, 1)
        
        if case let .success(value) = result.result {
            XCTAssertEqual(value.result, nil)
        } else {
            XCTFail("Expected result to be .success")
        }
    }
}
