//
//  TokenListRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenListRoutable: AnyObject {
    func closeModule()
    func openAddCustom(settings: ManageTokensSettings, userTokensManager: UserTokensManager)
}
