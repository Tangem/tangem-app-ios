//
//  CardInfoPageWarningIconAndTitleCellPreviewViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIImage

final class CardInfoPageWarningIconAndTitleCellPreviewViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let icon: UIImage?
    let title: String

    init(icon: UIImage?, title: String) {
        self.icon = icon
        self.title = title
    }
}
