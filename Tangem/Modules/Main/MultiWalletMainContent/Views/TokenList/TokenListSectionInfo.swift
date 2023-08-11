//
//  TokenListSectionInfo.swift
//  Tangem
//
//  Created by Andrew Son on 03/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// TODO: Temp solution. Will be updated after merging IOS-3461
struct TokenListSectionInfo {
    let id: Int
    let sectionType: SectionType
    let infoProviders: [TokenItemInfoProvider]
}

extension TokenListSectionInfo {
    enum SectionType {
        case titled(title: String)
        case untitled

        var title: String? {
            switch self {
            case .titled(let title):
                return title
            case .untitled:
                return nil
            }
        }
    }
}
