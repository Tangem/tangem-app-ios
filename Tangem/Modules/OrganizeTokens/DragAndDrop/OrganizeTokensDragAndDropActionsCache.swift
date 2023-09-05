//
//  OrganizeTokensDragAndDropActionsCache.swift
//  Tangem
//
//  Created by Andrey Fedorov on 22.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class OrganizeTokensDragAndDropActionsCache {
    typealias DragAndDropAction = (_ sectionsToMutate: inout [OrganizeTokensListSection]) -> Void
    typealias SectionsChange = (oldValue: [TokenSectionsAdapter.Section], newValue: [TokenSectionsAdapter.Section])

    private var cachedPlainListActions: [DragAndDropAction] = []
    private var cachedGroupedListActions: [DragAndDropAction] = []

    func addDragAndDropAction(isGroupingEnabled: Bool, _ action: @escaping DragAndDropAction) {
        if isGroupingEnabled {
            cachedGroupedListActions.append(action)
        } else {
            cachedPlainListActions.append(action)
        }
    }

    func applyDragAndDropActions(to sections: inout [OrganizeTokensListSection], isGroupingEnabled: Bool) {
        let actions = isGroupingEnabled ? cachedGroupedListActions : cachedPlainListActions
        actions.forEach { $0(&sections) }
    }

    func resetIfNeeded(sectionsChange: SectionsChange, isGroupingEnabled: Bool) {
        guard sectionsChange.oldValue.count == sectionsChange.newValue.count else {
            // Number of sections has changed, cache reset is needed
            reset(isGroupingEnabled: isGroupingEnabled)
            return
        }

        for (oldSection, newSection) in zip(sectionsChange.oldValue, sectionsChange.newValue) {
            guard oldSection.items.count == newSection.items.count else {
                // Number of items in a particular section has changed, cache reset is needed
                reset(isGroupingEnabled: isGroupingEnabled)
                break
            }
        }
    }

    func reset() {
        reset(isGroupingEnabled: true)
        reset(isGroupingEnabled: false)
    }

    private func reset(isGroupingEnabled: Bool) {
        if isGroupingEnabled {
            cachedGroupedListActions.removeAll()
        } else {
            cachedPlainListActions.removeAll()
        }
    }
}
