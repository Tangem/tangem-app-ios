//
//  CardsInfoPagerScrollState.swift
//  Tangem
//
//  Created by Andrey Fedorov on 01.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class CardsInfoPagerScrollState: ObservableObject {
    private(set) var proposedHeaderState: ProposedHeaderState = .expanded

    /// Raw content offset without throttling or filtering duplicates. A non-published plain property.
    var rawContentOffset: CGPoint { _contentOffsetSubject.value }
    @Published private(set) var contentOffset: CGPoint = .zero
    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)

    /// A property specifically that subscribes to content offset changes offsets without throttle. It was required specifically to understand the overscroll
    @Published private(set) var contentOffsetExceedingContentSize: CGPoint = .zero

    @Published private(set) var contentSize: CGSize = .zero
    var contentSizeSubject: some Subject<CGSize, Never> { _contentSizeSubject }
    private let _contentSizeSubject = CurrentValueSubject<CGSize, Never>(.zero)

    @Published private(set) var viewportSize: CGSize = .zero
    var viewportSizeSubject: some Subject<CGSize, Never> { _viewportSizeSubject }
    private let _viewportSizeSubject = CurrentValueSubject<CGSize, Never>(.zero)

    @Published private(set) var didScrollToBottom = false
    var bottomContentInsetSubject: some Subject<CGFloat, Never> { _bottomContentInsetSubject }
    private let _bottomContentInsetSubject = CurrentValueSubject<CGFloat, Never>(.zero)

    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    func onViewAppear() {
        bind()
    }

    private func bind() {
        if didBind { return }

        let contentOffsetSubject = _contentOffsetSubject
            .removeDuplicates()
            .share(replay: 1)

        let contentSizeSubject = _contentSizeSubject
            .removeDuplicates()
            .share(replay: 1)

        contentOffsetSubject
            .throttle(for: Constants.throttleInterval, scheduler: DispatchQueue.main, latest: true)
            .assign(to: \.contentOffset, on: self, ownership: .weak)
            .store(in: &bag)

        contentOffsetSubject
            .pairwise()
            .map { oldValue, newValue -> ProposedHeaderState in
                return oldValue.y > newValue.y ? .expanded : .collapsed
            }
            .removeDuplicates()
            .assign(to: \.proposedHeaderState, on: self, ownership: .weak)
            .store(in: &bag)

        contentOffsetSubject
            .combineLatest(
                contentSizeSubject,
                _viewportSizeSubject,
                _bottomContentInsetSubject
            ) { contentOffset, contentSize, viewportSize, bottomContentInset in
                return (contentOffset, contentSize.height - viewportSize.height + bottomContentInset)
            }
            .map { contentOffset, contentSizeHeight in
                return contentOffset.y >= contentSizeHeight
            }
            .removeDuplicates()
            .assign(to: \.didScrollToBottom, on: self, ownership: .weak)
            .store(in: &bag)

        contentSizeSubject
            .debounce(for: Constants.debounceInterval, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.contentSize, on: self, ownership: .weak)
            .store(in: &bag)

        _viewportSizeSubject
            .debounce(for: Constants.debounceInterval, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.viewportSize, on: self, ownership: .weak)
            .store(in: &bag)

        contentOffsetSubject
            .combineLatest(
                $didScrollToBottom
            ) { contentOffset, didScrollToBottom in
                guard didScrollToBottom else {
                    return CGPoint.zero
                }

                return contentOffset
            }
            .removeDuplicates()
            .assign(to: \.contentOffsetExceedingContentSize, on: self, ownership: .weak)
            .store(in: &bag)

        didBind = true
    }
}

// MARK: - Auxiliary types

extension CardsInfoPagerScrollState {
    enum ProposedHeaderState {
        case collapsed
        case expanded
    }
}

// MARK: - Constants

private extension CardsInfoPagerScrollState {
    enum Constants {
        static let throttleInterval: DispatchQueue.SchedulerTimeType.Stride = 1.0
        static let debounceInterval: DispatchQueue.SchedulerTimeType.Stride = 0.5
    }
}
