//
//  AddCustomTokenNetworkSelectorDelegate.swift
//  Tangem
//
//  Created by Andrey Chukavin on 21.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol AddCustomTokenNetworkSelectorDelegate: AnyObject {
    func didSelectNetwork(networkId: String)
}
