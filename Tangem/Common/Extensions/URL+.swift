//
//  URL+.swift
//  Tangem
//
//  Created by Alexander Osokin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension URL: Identifiable {
    public var id: String { absoluteString }
}
