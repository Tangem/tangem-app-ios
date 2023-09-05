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

    var contentOffset: CGPoint { _contentOffsetSubject.value }
    var contentOffsetSubject: some Subject<CGPoint, Never> { _contentOffsetSubject }
    private let _contentOffsetSubject = CurrentValueSubject<CGPoint, Never>(.zero)

    @Published private(set) var contentSize: CGSize = .zero
    var contentSizeSubject: some Subject<CGSize, Never> { _contentSizeSubject }
    private let _contentSizeSubject = CurrentValueSubject<CGSize, Never>(.zero)

    @Published private(set) var viewportSize: CGSize = .zero
    var viewportSizeSubject: some Subject<CGSize, Never> { _viewportSizeSubject }
    private let _viewportSizeSubject = CurrentValueSubject<CGSize, Never>(.zero)

    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    func onViewAppear() {
        bind()
    }

    private func bind() {
        if didBind { return }

        _contentOffsetSubject
            .removeDuplicates()
            .pairwise()
            .map { oldValue, newValue -> ProposedHeaderState in
                return oldValue.y > newValue.y ? .expanded : .collapsed
            }
            .removeDuplicates()
            .assign(to: \.proposedHeaderState, on: self, ownership: .weak)
            .store(in: &bag)

        _contentSizeSubject
            .debounce(for: Constants.debounceInterval, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.contentSize, on: self, ownership: .weak)
            .store(in: &bag)

        _viewportSizeSubject
            .debounce(for: Constants.debounceInterval, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.viewportSize, on: self, ownership: .weak)
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
        static let debounceInterval: DispatchQueue.SchedulerTimeType.Stride = 0.5
    }
}
