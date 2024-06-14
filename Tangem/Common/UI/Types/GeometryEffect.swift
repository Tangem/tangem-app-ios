//
//  GeometryEffect.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct GeometryEffect: Hashable {
    let id: String
    let namespace: Namespace.ID
    let isSource: Bool

    init(id: String, namespace: Namespace.ID, isSource: Bool = true) {
        self.id = id
        self.namespace = namespace
        self.isSource = isSource
    }
}
