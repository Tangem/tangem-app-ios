//
//  String+.swift
//  TangemModules
//
//  Created by GuitarKitty on 07.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension String {
    func caseInsensitiveContains(_ other: some StringProtocol) -> Bool {
        return range(of: other, options: .caseInsensitive) != nil
    }
}
