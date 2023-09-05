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

    private unowned let coordinator: OrganizeTokensRoutable

    private let walletModelsManager: WalletModelsManager
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
        walletModelsManager: WalletModelsManager,
        tokenSectionsAdapter: TokenSectionsAdapter,
        optionsProviding: OrganizeTokensOptionsProviding,
        optionsEditing: OrganizeTokensOptionsEditing
    ) {
        self.coordinator = coordinator
        self.walletModelsManager = walletModelsManager
        self.tokenSectionsAdapter = tokenSectionsAdapter
        self.optionsProviding = optionsProviding
        self.optionsEditing = optionsEditing
    }

    func onViewAppear() {
        bind()
    }

    func onCancelButtonTap() {
        coordinator.didTapCancelButton()
    }

    func onApplyButtonTap() {
        onSave.send()
    }

    private func bind() {
        if didBind { return }

        let walletModelsPublisher = walletModelsManager
            .walletModelsPublisher
            .share(replay: 1)
            .eraseToAnyPublisher()

        let walletModelsDidChangePublisher = walletModelsPublisher
            .receive(on: mappingQueue)
            .flatMap { walletModels in
                return walletModels
                    .map(\.walletDidChangePublisher)
                    .merge()
            }
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .withLatestFrom(walletModelsPublisher)
            .eraseToAnyPublisher()

        let aggregatedWalletModelsPublisher = [
            walletModelsPublisher,
            walletModelsDidChangePublisher,
        ].merge()

        let organizedTokensSectionsPublisher = tokenSectionsAdapter
            .organizedSections(from: aggregatedWalletModelsPublisher, on: mappingQueue)
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

        onSave
            .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: false)
            .receive(on: mappingQueue)
            .withWeakCaptureOf(self)
            .flatMapLatest { viewModel, _ in
                let walletModelIds = viewModel
                    .sections
                    .flatMap(\.items)
                    .map(\.id.walletModelId)

                return viewModel.optionsEditing.save(reorderedWalletModelIds: walletModelIds)
            }
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, _ in
                viewModel.coordinator.didTapSaveButton()
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
}

// MARK: - Drag and drop support

extension OrganizeTokensViewModel {
    func itemViewModel(for identifier: AnyHashable) -> OrganizeTokensListItemViewModel? {
        return sections
            .flatMap { $0.items }
            .first { $0.id.asAnyHashable == identifier }
    }

    func section(for identifier: AnyHashable) -> OrganizeTokensListSection? {
        return sections
            .first { $0.id == identifier }
    }

    func viewModelIdentifier(at indexPath: IndexPath) -> AnyHashable {
        return section(at: indexPath)?.id ?? itemViewModel(at: indexPath).id.asAnyHashable
    }

    func move(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let isGroupingEnabled = headerViewModel.isGroupingEnabled

        if sourceIndexPath.item == sectionHeaderItemIndex {
            guard sourceIndexPath.item == destinationIndexPath.item else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            sections.swapAt(sourceIndexPath.section, destinationIndexPath.section)
            dragAndDropActionsCache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                sectionsToMutate.swapAt(sourceIndexPath.section, destinationIndexPath.section)
            }
        } else {
            guard sourceIndexPath.section == destinationIndexPath.section else {
                assertionFailure("Can't perform move operation between section and item or vice versa")
                return
            }

            sections[sourceIndexPath.section].items.swapAt(sourceIndexPath.item, destinationIndexPath.item)
            dragAndDropActionsCache.addDragAndDropAction(isGroupingEnabled: isGroupingEnabled) { sectionsToMutate in
                sectionsToMutate[sourceIndexPath.section].items.swapAt(sourceIndexPath.item, destinationIndexPath.item)
            }
        }
    }

    func canStartDragAndDropSession(at indexPath: IndexPath) -> Bool {
        return section(at: indexPath)?.isDraggable ?? itemViewModel(at: indexPath).isDraggable
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
            self.beginDragAndDropSession(forSectionWithIdentifier: self.sections[indexPath.section].id)
        }
    }

    func onDragAnimationCompletion() {
        endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded()
    }

    private func beginDragAndDropSession(forSectionWithIdentifier identifier: AnyHashable) {
        guard let index = index(forSectionWithIdentifier: identifier) else { return }

        assert(
            currentlyDraggedSectionIdentifier == nil,
            "Attempting to start a new drag and drop session without finishing the previous one"
        )

        currentlyDraggedSectionIdentifier = identifier
        currentlyDraggedSectionItems = sections[index].items
        sections[index].items.removeAll()
    }

    private func endDragAndDropSession(forSectionWithIdentifier identifier: AnyHashable) {
        guard let index = index(forSectionWithIdentifier: identifier) else { return }

        sections[index].items = currentlyDraggedSectionItems
        currentlyDraggedSectionItems.removeAll()
    }

    private func endDragAndDropSessionForCurrentlyDraggedSectionIfNeeded() {
        currentlyDraggedSectionIdentifier.map(endDragAndDropSession(forSectionWithIdentifier:))
        currentlyDraggedSectionIdentifier = nil
    }

    private func index(forSectionWithIdentifier identifier: AnyHashable) -> Int? {
        return sections.firstIndex { $0.id == identifier }
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
        return viewModelIdentifier(at: indexPath)
    }
}
