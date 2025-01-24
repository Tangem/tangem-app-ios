//
//  ScrollViewOffsetHandler.swift
//  TangemApp
//
//  Created by Dmitry Fedorov on 05.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

final class ScrollViewOffsetHandler<T: Equatable>: ObservableObject {
    @Published private(set) var state: T

    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)

    private let map: (CGPoint) -> T
    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    init(initialState: T, map: @escaping (CGPoint) -> T) {
        state = initialState
        self.map = map
    }

    func onViewAppear() {
        bind()
    }

    func bind() {
        guard !didBind else { return }

        _contentOffsetSubject
            .map { contentOffset in
                // `CGPoint` doesn't conform to `Comparable`, so we're applying `max(_:_:)` manually here
                return CGPoint(
                    x: max(contentOffset.x, .zero),
                    y: max(contentOffset.y, .zero)
                )
            }
            .withWeakCaptureOf(self)
            .map { handler, contentOffset in
                handler.map(contentOffset)
            }
            .removeDuplicates()
            .assign(to: \.state, on: self, ownership: .weak)
            .store(in: &bag)

        didBind = true
    }
}
