//
//  MarketsTokenDetailsSecurityData.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Andrey Fedorov - Map using mapper with additional checks
// TODO: Andrey Fedorov - Naming: data or score?
struct MarketsTokenDetailsSecurityData: Equatable, Decodable {
    struct ProviderData: Equatable, Decodable {
        let providerId: String
        let providerName: String
        let securityScore: Double
        let link: URL?
        let lastAuditDate: Date?
    }

    let totalSecurityScore: Double // FIXME: Andrey Fedorov - An optional field?
    let providerData: [ProviderData]
}
