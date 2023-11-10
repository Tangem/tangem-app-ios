//
//  ExpressProvider.swift
//  TangemSwapping
//
//  Created by Sergey Balashov on 02.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressProvider: Hashable {
    public let id: Int
    public let name: String
    public let url: URL?
    public let type: ExpressProviderType

    public init(id: Int, name: String, url: URL?, type: ExpressProviderType) {
        self.id = id
        self.name = name
        self.url = url
        self.type = type
    }
}
