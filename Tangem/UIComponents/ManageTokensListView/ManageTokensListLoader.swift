//
//  ManageTokensListLoader.swift
//  Tangem
//
//  Created by Andrew Son on 22/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ManageTokensListLoader: AnyObject {
    var hasNextPage: Bool { get }
    func fetch()
}
