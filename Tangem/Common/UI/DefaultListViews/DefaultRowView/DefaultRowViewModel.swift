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
    @Published private(set) var secondaryAction: (() -> Void)?

    init(
        title: String,
        detailsType: DetailsType? = .none,
        action: (() -> Void)? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.detailsType = detailsType
        self.action = action
        self.secondaryAction = secondaryAction
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

    func update(secondaryAction: (() -> Void)? = nil) {
        self.secondaryAction = secondaryAction
    }
}

extension DefaultRowViewModel {
    enum DetailsType: Hashable {
        case loadable(state: LoadableTextView.State)
        case text(_ string: String, sensitive: Bool = false)
        case loader
        case icon(_ image: ImageType)
    }
}
