//
//  ExpressApproveRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 11.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ExpressApproveRoutable: AnyObject {
    func didSendApproveTransaction()
    func userDidCancel()
}
