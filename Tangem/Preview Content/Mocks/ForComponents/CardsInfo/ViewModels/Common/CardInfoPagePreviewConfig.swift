//
//  CardInfoPagePreviewConfig.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CardInfoPagePreviewConfig: Identifiable {
    let id = UUID()
    let initiallySelectedIndex: Int
    let hasPullToRefresh: Bool
}
