//
//  ExpressApproveRoutableMock.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExpress

class ExpressApproveRoutableMock: ExpressApproveRoutable {
    func didSendApproveTransaction() {}
    func userDidCancel() {}
}
