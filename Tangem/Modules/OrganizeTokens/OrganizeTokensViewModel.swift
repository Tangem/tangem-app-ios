//
//  OrganizeTokensViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import SwiftUI

final class OrganizeTokensViewModel: ObservableObject, Identifiable {
    /// Sentinel value for `item` of `IndexPath` representing a section.
    var sectionHeaderItemIndex: Int { .min }

    private(set) lazy var headerViewModel = OrganizeTokensHeaderViewModel(
        optionsProviding: optionsProviding,
        optionsEditing: optionsEditing
    )

    @Published private(set) var sections: [OrganizeTokensListSection] = []

    let id = UUID()

    private weak var coordinator: OrganizeTokensRoutable?

    private let userWalletModel: UserWalletModel
    private let tokenSectionsAdapter: TokenSectionsAdapter
    private let optionsProviding: OrganizeTokensOptionsProviding
    private let optionsEditing: OrganizeTokensOptionsEditing

    private let dragAndDropActionsCache = OrganizeTokensDragAndDropActionsCache()
    private var currentlyDraggedSectionIdentifier: AnyHashable?
    private var currentlyDraggedSectionItems: [OrganizeTokensListItemViewModel] = []

    private let onSave = PassthroughSubject<Void, Never>()

    private let mappingQueue = DispatchQueue(
        label: "com.tangem.OrganizeTokensViewModel.mappingQueue",
        qos: .userInitiated
    )

    private var bag: Set<AnyCancellable> = []
    private var didBind = false

    init(
        coordinator: OrganizeTokensRoutable,
        userWalletModel: UserWalletModel,
        tokenSectionsAdapter: TokenSectionsAdapter,
        optionsProviding: OrganizeTokensOptionsProviding,
        optionsEditing: OrganizeTokensOptionsEditing
    ) {
        self.coordinator = coordinator
        self.userWalletModel = userWalletModel
        self.tokenSectionsAdapter = tokenSectionsAdapter
        self.optionsProviding = optionsProviding
        self.optionsEditing = optionsEditing
    }

    func onViewWillAppear() {
        bind()
    }

    func onViewAppear() {
        reportScreenOpened()
    }

    func onCancelButtonTap() {
        Analytics.log(.organizeTokensButtonCancel)
        coordinator?.didTapCancelButton()
    }

    func onApplyButtonTap() {
        onSave.send()
    }

    private func bind() {
        if didBind { return }

        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let tokenSectionsSourcePublisher = sourcePublisherFactory.makeSourcePublisherForMainScreen(for: userWalletModel)

        let organizedTokensSectionsPublisher = tokenSectionsAdapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: mappingQueue)
            .share(replay: 1)

        let cache = dragAndDropActionsCache

        // Resetting drag-and-drop actions cache for grouped sections
        // when the structure of the underlying model has changed
        organizedTokensSectionsPublisher
            .withLatestFrom(optionsProviding.groupingOption) { ($0, $1) }
            .filter { $0.1.isGrouped }
            .map(\.0)
            .pairwise()
            .sink { cache.resetIfNeeded(sectionsChange: $0, isGroupingEnabled: true) }
            .store(in: &bag)

        // Resetting drag-and-drop actions cache for plain (non-grouped) sections
        // when the structure of the underlying model has changed
        organizedTokensSectionsPublisher
            .withLatestFrom(optionsProviding.groupingOption) { ($0, $1) }
            .filter { !$0.1.isGrouped }
            .map(\.0)
            .pairwise()
            .sink { cache.resetIfNeeded(sectionsChange: $0, isGroupingEnabled: false) }
            .store(in: &bag)

        // Resetting drag-and-drop actions cache unconditionally when sort option is changed
        optionsProviding
            .sortingOption
            .removeDuplicates()
            .sink { _ in cache.reset() }
            .store(in: &bag)

        organizedTokensSectionsPublisher
            .withLatestFrom(
                optionsProviding.sortingOption,
                optionsProviding.groupingOption
            ) { ($0, $1.0, $1.1, cache) }
            .map(Self.map)
            .receive(on: DispatchQueue.main)
            .assign(to: \.sections, on: self, ownership: .weak)
            .store(in: &bag)

        let onSavePublisher = onSave
            .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: false)
            .share(replay: 1)

        onSavePublisher
            .receive(on: mappingQueue)
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, _ in
                let walletModelIds = viewModel
                    .sections
                    .flatMap(\.items)
                    .map(\.id.walletModelId)

                return viewModel.optionsEditing.save(reorderedWalletModelIds: walletModelIds, source: .organizeTokens)
            }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, _ in
                viewModel.coordinator?.didTapSaveButton()
            }
            .store(in: &bag)

        onSavePublisher
            .withLatestFrom(
                optionsProviding.sortingOption,
                optionsProviding.groupingOption
            )
            .withWeakCaptureOf(self)
            .sink { input in
                let (viewModel, (sortingOption, groupingOption)) = input
                viewModel.reportOnSaveButtonTap(sortingOption: sortingOption, groupingOption: groupingOption)
            }
            .store(in: &bag)

        didBind = true
    }

    private static func map(
        sections: [TokenSectionsAdapter.Section],
        sortingOption: UserTokensReorderingOptions.Sorting,
        groupingOption: UserTokensReorderingOptions.Grouping,
        dragAndDropActionsCache: OrganizeTokensDragAndDropActionsCache
    ) -> [OrganizeTokensListSection] {
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        let listFactory = OrganizeTokensListFactory(tokenIconInfoBuilder: tokenIconInfoBuilder)

        var listItemViewModels = sections.enumerated().map { index, section in
            let isListSectionGrouped = isListSectionGrouped(section)
            let isDraggable = section.items.count > 1
            let items = section.items.map { item in
                listFactory.makeListItemViewModel(
                    sectionItem: item,
                    isDraggable: isDraggable,
                    inGroupedSection: isListSectionGrouped
                )
            }

            return listFactory.makeListSection(from: section.model, with: items, atIndex: index)
        }

        // By design, cached drag-and-drop actions can only be applied when manual sorting is active
        if !sortingOption.isSorted {
            dragAndDropActionsCache.applyDragAndDropActions(
                to: &listItemViewModels,
                isGroupingEnabled: groupingOption.isGrouped
            )
        }

        return listItemViewModels
    }

    private static func isListSectionGrouped(
        _ section: TokenSectionsAdapter.Section
    ) -> Bool {
        switch section.model {
        case .plain:
            return false
        case .group:
            return true
        }
    }

    private func reportScreenOpened() {
        Analytics.log(.organizeTokensScreenOpened)
    }

    private func reportOnSaveButtonTap(
        sortingOption: UserTokensReorderingOptions.Sorting,
        groupingOption: UserTokensReorderingOptions.Grouping
    ) {
        let sortTypeParameterValue: Analytics.ParameterValue
        switch sortingOption {
        case .dragAndDrop:
            sortTypeParameterValue = .sortTypeManual
        case .byBalance:
            sortTypeParameterValue = .sortTypeByBalance
        }

        let groupTypeParameterValue = Analytics.ParameterValue.toggleState(for: groupingOption.isGrouped)

        Analytics.log(
            .organizeTokensButtonApply,
            params: [
                .groupType: groupTypeParameterValue,
                .sortType: sortTypeParameterValue,
            ]
        )
    }
}

// MARK: - Drag and drop support

extension OrganizeTokensViewModel {
    func indexPath(for identifier: AnyHashable) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            if section.id == identifier {
                return IndexPath(item: sectionHeaderItemIndex, section: sectionIndex)
            }
            for (itemIndex, item) in section.items.enumerated() {
                if item.id.asAnyHashable == identifier {
                    return IndexPath(item: itemIndex, section: sectionIndex)
                }
            }
        }

        return nil
    }

    func itemViewModel(for identifier: AnyHashable) -> OrganizeTokensListItemViewModel? {
        return sections
            .flatMap { $0.items }
            .first { $0.id.asAnyHashable == identifier }
    }

    func section(for identifier: AnyHashable) -> OrganizeTokensListSection? {
        return sections
            .first { $0.id == identifier }
    }

    func move(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let isGroupingEnabled = headerViewModel.isGroupingEnabled

        if sourceIndexPath.item == sectionHeaderItemIndex {
            guard sourceIndexPath.item == destinationIndexPath.item else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            let diff = sourceIndexPath.section > destinationIndexPath.section ? 0 : 1
            sections.move(
                fromOffsets: IndexSet(integer: sourceIndexPath.section),
                toOffset: destinationIndexPath.section + diff
            )

            dragAndDropActionsCache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                try sectionsToMutate.tryMove(
                    fromOffsets: IndexSet(integer: sourceIndexPath.section),
                    toOffset: destinationIndexPath.section + diff
                )
            }
        } else {
            guard sourceIndexPath.section == destinationIndexPath.section else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            let diff = sourceIndexPath.item > destinationIndexPath.item ? 0 : 1
            sections[sourceIndexPath.section].items.move(
                fromOffsets: IndexSet(integer: sourceIndexPath.item),
                toOffset: destinationIndexPath.item + diff
            )

            dragAndDropActionsCache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                guard sectionsToMutate.indices.contains(sourceIndexPath.section) else {
                    throw Error.sectionOffsetOutOfBound(offset: sourceIndexPath.section, count: sectionsToMutate.count)
                }

                try sectionsToMutate[sourceIndexPath.section].items.tryMove(
                    fromOffsets: IndexSet(integer: sourceIndexPath.item),
                    toOffset: destinationIndexPath.item + diff
                )
            }
        }
    }

    func onDragStart(at indexPath: IndexPath) {
        // A started drag-and-drop session always disables sorting by balance
        optionsEditing.sort(by: .dragAndDrop)

        // Process further only if a section is currently being dragged
        guard indexPath.item == sectionHeaderItemIndex else { return }

        // Setting the sort option to `dragAndDrop` will cause an update of SwiftUI view identifiers for all
        // cells and sections in `OrganizeTokensView`. This update may take a couple render passes, therefore
        // we must wait for this update to finish before collapsing the dragged section
        // (by calling `beginDragAndDropSession(forSectionWithIdentifier:)`), otherwise UI glitches may appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.beginDragAndDropSession(forSectionAtIndex: indexPath.section)
        }
    }

    func onDragAnimationCompletion() {
        endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded()
    }

    private func beginDragAndDropSession(forSectionAtIndex sectionIndex: Int) {
        assert(
            currentlyDraggedSectionIdentifier == nil,
            "Attempting to start a new drag and drop session without finishing the previous one"
        )

        currentlyDraggedSectionIdentifier = sections[sectionIndex].id
        currentlyDraggedSectionItems = sections[sectionIndex].items
        sections[sectionIndex].items.removeAll()
    }

    private func endDragAndDropSession(forSectionWithIdentifier identifier: AnyHashable) {
        guard let index = indexPath(for: identifier)?.section else { return }

        sections[index].items = currentlyDraggedSectionItems
        currentlyDraggedSectionItems.removeAll()
    }

    private func endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded() {
        currentlyDraggedSectionIdentifier.map(endDragAndDropSession(forSectionWithIdentifier:))
        currentlyDraggedSectionIdentifier = nil
    }

    private func itemViewModel(at indexPath: IndexPath) -> OrganizeTokensListItemViewModel {
        return sections[indexPath.section].items[indexPath.item]
    }

    private func section(at indexPath: IndexPath) -> OrganizeTokensListSection? {
        guard indexPath.item == sectionHeaderItemIndex else { return nil }

        return sections[indexPath.section]
    }
}

// MARK: - OrganizeTokensDragAndDropControllerDataSource protocol conformance

extension OrganizeTokensViewModel: OrganizeTokensDragAndDropControllerDataSource {
    func numberOfSections(
        for controller: OrganizeTokensDragAndDropController
    ) -> Int {
        return sections.count
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        numberOfRowsInSection section: Int
    ) -> Int {
        return sections[section].items.count
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewKindForItemAt indexPath: IndexPath
    ) -> OrganizeTokensDragAndDropControllerListViewKind {
        return indexPath.item == sectionHeaderItemIndex ? .sectionHeader : .cell
    }

    func controller(
        _ controller: OrganizeTokensDragAndDropController,
        listViewIdentifierForItemAt indexPath: IndexPath
    ) -> AnyHashable {
        return section(at: indexPath)?.id ?? itemViewModel(at: indexPath).id.asAnyHashable
    }
}

// MARK: - Auxiliary types

extension OrganizeTokensViewModel {
    enum Error: Swift.Error {
        case sectionOffsetOutOfBound(offset: Int, count: Int)
    }
}
