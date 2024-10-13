//
// SUIUtils.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 28.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SUIUtils {
    static let SuiGasBudgetScaleUpConstant = Decimal(1_000_000)
    static let SuiGasMinimumGasBudgetComputationUnits = Decimal(1000)
    static let SuiGasBudgetMaxValue = Decimal(50_000_000_000)
    
    enum EllipticCurveID: UInt8 {
        case ed25519    = 0x00
        case secp256k1  = 0x01
        case secp256r1  = 0x02
        
        var uint8: UInt8 {
            self.rawValue
        }
    }
    
    struct CoinType: Codable {
        let contract: String
        let lowerID: String
        let upperID: String
        
        var string: String {
            [contract, lowerID, upperID].joined(separator: Self.separator)
        }
        
        static let sui = Self(contract: "0x2", lowerID: "sui", upperID: "SUI")
        private static let separator = "::"
        
        init(contract: String, lowerID: String, upperID: String) {
            self.contract = contract
            self.lowerID = lowerID
            self.upperID = upperID
        }
        
        init(string: String) throws {
            let elements = string.components(separatedBy: Self.separator)
            
            guard elements.count == 3 else {
                throw SuiError.CodingError.failedDecoding
            }
            
            contract = elements[0]
            lowerID  = elements[1]
            upperID  = elements[2]
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            try self.init(string: string)
        }
        
        func encode(to encoder: any Encoder) throws {
            try string.encode(to: encoder)
        }
    }
}
