//
//  OnrampIdentity.swift
//  TangemApp
//
//  Created by Sergey Balashov on 02.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampIdentity: Hashable, Codable {
    public let name: String
    public let code: String
    public let image: URL?

    public init(name: String, code: String, image: URL?) {
        self.name = name
        self.code = code
        self.image = image
    }
}
