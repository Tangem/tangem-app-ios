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
    private(set) var hasPendingSnapshotUpdate = false

    private let isShownSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private let footerSnapshotSubject: PassthroughSubject<FooterSnapshot, Never> = .init()
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

    func hide(shouldUpdateFooterSnapshot: Bool = true) {
        ensureOnMainQueue()

        guard isShown else {
            return
        }

        let isShown = false

        guard shouldUpdateFooterSnapshot else {
            isShownSubject.send(isShown)
            return
        }

        hasPendingSnapshotUpdate = true
        setFooterSnapshotNeedsUpdate { [weak self] in
            // Workaround: delaying hiding main bottom sheet roughly for the duration of one frame so that the UI
            // has a chance to actually render an updated view snapshot.
            // Dispatching to the next runloop tick (via `DispatchQueue.main.async`) doesn't work reliably enough
            // because not every runloop tick is used for rendering.
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.mainBottomSheetHidingDelay) {
                guard let self else {
                    return
                }

                self.isShownSubject.send(isShown)
                self.hasPendingSnapshotUpdate = false
            }
        }
    }
}

// MARK: - Snapshot management

extension MainBottomSheetUIManager {
    /// Provides updated snapshot.
    var footerSnapshotPublisher: some Publisher<FooterSnapshot, Never> { footerSnapshotSubject }

    /// Triggers snapshot update.
    var footerSnapshotUpdateTriggerPublisher: some Publisher<Void, Never> { footerSnapshotUpdateTriggerSubject }

    func setFooterSnapshots(lightAppearanceSnapshotImage: UIImage?, darkAppearanceSnapshotImage: UIImage?) {
        ensureOnMainQueue()

        let footerSnapshot = FooterSnapshot(
            lightAppearance: lightAppearanceSnapshotImage,
            darkAppearance: darkAppearanceSnapshotImage
        )

        footerSnapshotSubject.send(footerSnapshot)

        let completions = pendingFooterSnapshotUpdateCompletions
        pendingFooterSnapshotUpdateCompletions.removeAll(keepingCapacity: true)
        completions.forEach { $0() }
    }

    private func setFooterSnapshotNeedsUpdate(with completion: @escaping () -> Void) {
        pendingFooterSnapshotUpdateCompletions.append(completion)
        footerSnapshotUpdateTriggerSubject.send()
    }
}

// MARK: - Auxiliary types

extension MainBottomSheetUIManager {
    struct FooterSnapshot {
        let lightAppearance: UIImage?
        let darkAppearance: UIImage?
    }
}

// MARK: - Constants

private extension MainBottomSheetUIManager {
    enum Constants {
        static let mainBottomSheetHidingDelay: TimeInterval = 1.0 / 60.0
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
