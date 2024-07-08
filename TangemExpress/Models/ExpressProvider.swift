//
//  ExpressProvider.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 02.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressProvider: Hashable {
    public typealias Id = String

    public let id: Id
    public let name: String
    public let type: ExpressProviderType
    public let imageURL: URL?
    public let termsOfUse: URL?
    public let privacyPolicy: URL?
    public let recommended: Bool?

    public init(
        id: Id,
        name: String,
        type: ExpressProviderType,
        imageURL: URL?,
        termsOfUse: URL?,
        privacyPolicy: URL?,
        recommended: Bool?
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.imageURL = imageURL
        self.termsOfUse = termsOfUse
        self.privacyPolicy = privacyPolicy
        self.recommended = recommended
    }
}
