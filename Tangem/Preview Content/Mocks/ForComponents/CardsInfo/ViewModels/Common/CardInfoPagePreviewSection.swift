//
//  CardInfoPagePreviewSection.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CardInfoPagePreviewSection<ID>: Identifiable where ID: Hashable {
    enum SectionItems {
        case warning([CardInfoPageWarningPreviewSectionItem])
        case transaction([CardInfoPageTransactionPreviewSectionItem])
    }

    let id: ID
    let items: SectionItems
}
