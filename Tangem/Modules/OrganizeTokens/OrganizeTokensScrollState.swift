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
    private(set) var contentOffset: CGPoint = .zero {
        willSet {
            // Publish changes to this property manually and only when there is an active drag-and-drop session,
            // because we don't need to redraw our observer (view) when the content offset is changed due to normal,
            // ordinary scrolling (triggered by the user)
            if isDragActive {
                objectWillChange.send()
            }
        }
    }

    @Published private(set) var isTokenListFooterGradientHidden = true

    @Published private(set) var isNavigationBarBackgroundHidden = true

    var tokenListContentFrameMaxYSubject: some Subject<CGFloat, Never> { _tokenListContentFrameMaxYSubject }
    private let _tokenListContentFrameMaxYSubject = CurrentValueSubject<CGFloat, Never>(.zero)

    var tokenListFooterFrameMinYSubject: some Subject<CGFloat, Never> { _tokenListFooterFrameMinYSubject }
    private let _tokenListFooterFrameMinYSubject = CurrentValueSubject<CGFloat, Never>(.zero)

    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)

    private let bottomInset: CGFloat

    private var isDragActive = false {
        didSet {
            // One-time update of the `contentOffset` property to its actual value,
            // which in turn will publish changes to our observer (view)
            if isDragActive != oldValue {
                contentOffset = _contentOffsetSubject.value
            }
        }
    }

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

    func onDragStart() {
        isDragActive = true
    }

    func onDragEnd() {
        isDragActive = false
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
                // `CGPoint` doesn't conform to `Comparable`, so we're applying `max(_:_:)` manually here
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
