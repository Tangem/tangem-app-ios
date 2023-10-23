//
//  OrganizeTokensScrollState.swift
//  Tangem
//
//  Created by Andrey Fedorov on 19.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class OrganizeTokensScrollState: ObservableObject {
    @Published private(set) var contentOffset: CGPoint = .zero

    @Published private(set) var isTokenListFooterGradientHidden = true

    @Published private(set) var isNavigationBarBackgroundHidden = true

    var tokenListContentFrameMaxYSubject: some Subject<CGFloat, Never> { _tokenListContentFrameMaxYSubject }
    private let _tokenListContentFrameMaxYSubject = CurrentValueSubject<CGFloat, Never>(.zero)

    var tokenListFooterFrameMinYSubject: some Subject<CGFloat, Never> { _tokenListFooterFrameMinYSubject }
    private let _tokenListFooterFrameMinYSubject = CurrentValueSubject<CGFloat, Never>(.zero)

    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)

    private let bottomInset: CGFloat

    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    init(
        bottomInset: CGFloat
    ) {
        self.bottomInset = bottomInset
    }

    func onViewAppear() {
        bind()
    }

    private func bind() {
        if didBind { return }

        _tokenListContentFrameMaxYSubject
            .combineLatest(_tokenListFooterFrameMinYSubject) { ($0, $1) }
            .map { $0 < $1 }
            .removeDuplicates()
            .assign(to: \.isTokenListFooterGradientHidden, on: self, ownership: .weak)
            .store(in: &bag)

        let contentOffsetSubject = _contentOffsetSubject
            .removeDuplicates()
            .share(replay: 1)

        let bottomInset = bottomInset

        contentOffsetSubject
            .map { $0.y - bottomInset <= .zero }
            .removeDuplicates()
            .assign(to: \.isNavigationBarBackgroundHidden, on: self, ownership: .weak)
            .store(in: &bag)

        contentOffsetSubject
            .map { contentOffset in
                // `CGPoint` doesn't conform to `Comporable`, so we're applying `max(_:_:)` manually here
                return CGPoint(
                    x: max(contentOffset.x, .zero),
                    y: max(contentOffset.y, .zero)
                )
            }
            .removeDuplicates()
            .assign(to: \.contentOffset, on: self, ownership: .weak)
            .store(in: &bag)

        didBind = true
    }
}
