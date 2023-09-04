//
//  FetchMore.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct FetchMore: Identifiable {
    public let id: String
    public let start: () -> Void

    public init(id: String = UUID().uuidString, start: @escaping () -> Void) {
        self.id = id
        self.start = start
    }
}
