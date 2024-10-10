//
//  BitcoreResponse.swift
//  TangemKit
//
//  Created by Alexander Osokin on 03.02.2020.
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation

struct BitcoreBalance: Codable {
    var confirmed: Int64?
    var unconfirmed: Int64?
}

struct BitcoreUtxo: Codable {
    var mintTxid: String?
    var mintIndex: Int?
    var value: Int64?
    var script: String?
}

struct BitcoreSendResponse: Codable {
    var txid: String?
}
