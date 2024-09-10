//
//  MainBottomSheetFooterViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import class UIKit.UIImage

final class MainBottomSheetFooterViewModel: ObservableObject {
    @Published private(set) var snapshotImage: UIImage?

    @Injected(\.mainBottomSheetVisibility) private var bottomSheetVisibility: MainBottomSheetVisibility

    private var subscription: AnyCancellable?

    init() {
        bind()
    }

    private func bind() {
        guard subscription == nil else {
            return
        }

        subscription = bottomSheetVisibility
            .footerSnapshotPublisher
            .assign(to: \.snapshotImage, on: self, ownership: .weak)
    }
}
