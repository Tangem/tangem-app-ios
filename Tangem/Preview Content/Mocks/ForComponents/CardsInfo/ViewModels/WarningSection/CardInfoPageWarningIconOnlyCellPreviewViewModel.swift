//
//  CardInfoPageWarningIconOnlyCellPreviewViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIImage

final class CardInfoPageWarningIconOnlyCellPreviewViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let icon: UIImage?

    init(icon: UIImage?) {
        self.icon = icon
    }
}
