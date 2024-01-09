//
//  TokenDetailsScrollState.swift
//  Tangem
//
//  Created by Andrey Fedorov on 30.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class TokenDetailsScrollState: ObservableObject {
    @Published private(set) var toolbarIconOpacity: Double = .zero

    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)

    private let tokenIconSizeSettings: IconViewSizeSettings
    private let headerTopPadding: CGFloat

    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    init(
        tokenIconSizeSettings: IconViewSizeSettings,
        headerTopPadding: CGFloat
    ) {
        self.tokenIconSizeSettings = tokenIconSizeSettings
        self.headerTopPadding = headerTopPadding
    }

    func onViewAppear() {
        bind()
    }

    private func bind() {
        if didBind { return }

        _contentOffsetSubject
            .map { contentOffset in
                // `CGPoint` doesn't conform to `Comparable`, so we're applying `max(_:_:)` manually here
                return CGPoint(
                    x: max(contentOffset.x, .zero),
                    y: max(contentOffset.y, .zero)
                )
            }
            .withWeakCaptureOf(self)
            .map { scrollState, contentOffset in
                let iconHeight = scrollState.tokenIconSizeSettings.iconSize.height
                let startAppearingOffset = scrollState.headerTopPadding + iconHeight

                let fullAppearanceDistance = iconHeight / 2.0
                let fullAppearanceOffset = startAppearingOffset + fullAppearanceDistance

                return clamp(
                    (contentOffset.y - startAppearingOffset) / (fullAppearanceOffset - startAppearingOffset),
                    min: 0.0,
                    max: 1.0
                )
            }
            .removeDuplicates()
            .assign(to: \.toolbarIconOpacity, on: self, ownership: .weak)
            .store(in: &bag)

        didBind = true
    }
}
