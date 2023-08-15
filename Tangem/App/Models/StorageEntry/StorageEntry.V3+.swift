//
//  StorageEntry.V3+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 15.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension StorageEntry.V3.Entry {
    var isCustom: Bool { id == nil }
}
