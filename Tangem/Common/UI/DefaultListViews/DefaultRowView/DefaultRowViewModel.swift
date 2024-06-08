//
//  DefaultRowViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class DefaultRowViewModel: ObservableObject, Identifiable {
    @Published private(set) var title: String
    @Published private(set) var detailsType: DetailsType?
    @Published private(set) var action: (() -> Void)?

    init(
        title: String,
        detailsType: DetailsType? = .none,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.detailsType = detailsType
        self.action = action
    }

    func update(title: String) {
        self.title = title
    }

    func update(detailsType: DetailsType?) {
        self.detailsType = detailsType
    }

    func update(action: (() -> Void)? = nil) {
        self.action = action
    }
}

extension DefaultRowViewModel {
    enum DetailsType: Hashable {
        case text(_ string: String)
        case loader
        case icon(_ image: ImageType)
    }
}
