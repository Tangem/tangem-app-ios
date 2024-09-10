//
//  MainBottomSheetUIManager.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import class UIKit.UIImage
import TangemFoundation

final class MainBottomSheetUIManager {
    private let isShownSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private let footerSnapshotSubject: PassthroughSubject<UIImage?, Never> = .init()
    private let footerSnapshotUpdateTriggerSubject: PassthroughSubject<Void, Never> = .init()
    private var pendingFooterSnapshotUpdateCompletions: [() -> Void] = []
}

// MARK: - Visibility management

extension MainBottomSheetUIManager {
    var isShown: Bool { isShownSubject.value }
    var isShownPublisher: some Publisher<Bool, Never> { isShownSubject }

    func show() {
        ensureOnMainQueue()

        isShownSubject.send(true)
    }

    func hide() {
        ensureOnMainQueue()

        setFooterSnapshotNeedsUpdate { [weak self] in
            self?.isShownSubject.send(false)
        }
    }
}

// MARK: - Snapshot management

extension MainBottomSheetUIManager {
    /// Provides updated snapshot.
    var footerSnapshotPublisher: some Publisher<UIImage?, Never> { footerSnapshotSubject }

    /// Triggers snapshot update.
    var footerSnapshotUpdateTriggerPublisher: some Publisher<Void, Never> { footerSnapshotUpdateTriggerSubject }

    func setFooterSnapshot(_ snapshotImage: UIImage?) {
        ensureOnMainQueue()

        footerSnapshotSubject.send(snapshotImage)

        let completions = pendingFooterSnapshotUpdateCompletions
        pendingFooterSnapshotUpdateCompletions.removeAll(keepingCapacity: true)
        completions.forEach { $0() }
    }

    private func setFooterSnapshotNeedsUpdate(with completion: @escaping () -> Void) {
        pendingFooterSnapshotUpdateCompletions.append(completion)
        footerSnapshotUpdateTriggerSubject.send()
    }
}

// MARK: - Dependency injection

private struct MainBottomSheetUIManagerKey: InjectionKey {
    static var currentValue = MainBottomSheetUIManager()
}

extension InjectedValues {
    var mainBottomSheetUIManager: MainBottomSheetUIManager {
        get { Self[MainBottomSheetUIManagerKey.self] }
        set { Self[MainBottomSheetUIManagerKey.self] = newValue }
    }
}
