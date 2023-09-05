//
//  OrganizeTokensListSectionViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensListSectionViewModel: Hashable, Identifiable {
    enum SectionStyle: Hashable {
        case invisible
        case fixed(title: String)
        case draggable(title: String)
    }

    let id: AnyHashable
    let style: SectionStyle
}
