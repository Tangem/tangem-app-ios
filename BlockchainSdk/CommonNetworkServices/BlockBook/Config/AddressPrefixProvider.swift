//
//  AddressPrefixProvider.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 02.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol AddressPrefixProvider {
    func addPrefixIfNeeded(_ address: String) -> String
}
