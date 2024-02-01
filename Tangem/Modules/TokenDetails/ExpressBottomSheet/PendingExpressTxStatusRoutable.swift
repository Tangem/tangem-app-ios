//
//  PendingExpressTxStatusRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 29.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PendingExpressTxStatusRoutable: AnyObject {
    func openPendingExpressTxStatus(at url: URL)
}
