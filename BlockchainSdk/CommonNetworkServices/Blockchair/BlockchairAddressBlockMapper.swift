//
//  BlockchairAddressBlockMapper.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 05/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol BlockchairAddressBlockMapper {
    func mapAddressBlock(_ address: String, json: JSON) -> JSON
}

extension BlockchairAddressBlockMapper {
    func mapAddressBlock(_ address: String, json: JSON) -> JSON {
        let data = json["data"]
        let dictionary = data.dictionaryValue
        if dictionary.keys.contains(address) {
            return data["\(address)"]
        }
        
        let lowercasedAddress = address.lowercased()
        if dictionary.keys.contains(lowercasedAddress) {
            return data["\(lowercasedAddress)"]
        }

        return json
    }
}
