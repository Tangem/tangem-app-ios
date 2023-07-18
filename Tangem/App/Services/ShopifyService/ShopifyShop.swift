//
//  ShopifyShop.swift
//  TangemShopify
//
//  Created by Andy on 20.12.2021.
//

import Foundation

struct ShopifyShop: Decodable {
    let domain: String
    let storefrontApiKey: String
    let merchantID: String?
}
