//
// KaspaNetworkModelsKRC20.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 17.10.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaBalanceResponseKRC20: Codable {
    struct Result: Codable {
        let tick: String
        let balance: String
        let locked: String
        let dec: String
        let opScoreMod: String
    }
    let message: String
    let result: [Result]
}

