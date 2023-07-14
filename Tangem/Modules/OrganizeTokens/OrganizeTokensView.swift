//
//  OrganizeTokensView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensView: View {
    // MARK: - Model

    @ObservedObject private var viewModel: OrganizeTokensViewModel

    // MARK: - Coordinate spaces

    // Semantically, this is the same as `UIScrollView.frameLayoutGuide` from UIKit
    private let scrollViewFrameCoordinateSpaceName = UUID()

    // Semantically, this is the same as `UIScrollView.contentLayoutGuide` from UIKit
    private let scrollViewContentCoordinateSpaceName = UUID()

    // MARK: - Content insets and overlay views

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var scrollViewTopContentInset: CGFloat = 0.0

    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var scrollViewBottomContentInset: CGFloat = 0.0

    @State private var scrollViewTopContentInsetSpacerIdentifier: UUID
    @State private var scrollViewBottomContentInsetSpacerIdentifier: UUID

    @State private var tokenListFooterFrameMinY: CGFloat = 0.0
    @State private var tokenListContentFrameMaxY: CGFloat = 0.0
    @State private var scrollViewContentOffset: CGPoint = .zero

    @State private var isTokenListFooterGradientHidden = true
    @State private var isNavigationBarBackgroundHidden = true

    // MARK: - Drag and drop support

    @StateObject private var dragAndDropController: OrganizeTokensDragAndDropController

    // Viewport with `contentInset` (i.e. with `scrollViewTopContentInset` and `scrollViewBottomContentInset`)
    @State private var visibleViewportFrame: CGRect = .zero

    @State private var draggedItemFrame: CGRect = .zero

    // Index path for a view that received a new touch.
    //
    // Contains meaningful value only until the long press gesture successfully ends,
    // mustn't be used after that (use `dragAndDropSourceIndexPath` property instead)
    @State private var dragAndDropInitialIndexPath: IndexPath?

    @GestureState private var dragAndDropSourceIndexPath: IndexPath?

    @GestureState private var dragAndDropDestinationIndexPath: IndexPath?

    @State private var dragAndDropSourceItemFrame: CGRect?

    // Stable identity, independent of changes in the underlying model (unlike index paths)
    @State private var dragAndDropSourceViewModelIdentifier: UUID?

    @GestureState private var dragGestureTranslation: CGSize = .zero

    // Semantically, this is the same as `UITableView.hasActiveDrag` from UIKit
    private var hasActiveDrag: Bool { dragAndDropSourceIndexPath != nil }

    // MARK: - Body

    var body: some View {
        ZStack {
            Group {
                tokenList

                tokenListHeader

                tokenListFooter
            }
        }
        .background(
            Colors.Background
                .secondary
                .ignoresSafeArea(edges: [.vertical])
        )
        .onAppear { dragAndDropController.dataSource = viewModel }
    }

    // MARK: - Subviews

    private var tokenList: some View {
        GeometryReader { geometryProxy in
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0.0) {
                        Spacer(minLength: scrollViewTopContentInset)
                            .id(scrollViewTopContentInsetSpacerIdentifier)

                        tokenListContent
                    }
                    .animation(.spring(), value: viewModel.sections)
                    .padding(.horizontal, Constants.contentHorizontalInset)
                    .overlay(
                        makeDraggableComponent(width: geometryProxy.size.width - Constants.contentHorizontalInset * 2.0)
                            .animation(.linear(duration: Constants.dragLiftAnimationDuration), value: hasActiveDrag),
                        alignment: .top
                    )
                    .coordinateSpace(name: scrollViewContentCoordinateSpaceName)
                    .onTouchesBegan(onTouchesBegan(atLocation:))
                    .readGeometry(\.frame.maxY, bindTo: $tokenListContentFrameMaxY)
                    .readContentOffset(
                        inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName),
                        bindTo: $scrollViewContentOffset
                    )

                    Spacer(minLength: scrollViewBottomContentInset)
                        .id(scrollViewBottomContentInsetSpacerIdentifier)
                }
                .readGeometry(\.frame) { newValue in
                    dragAndDropController.viewportSizeSubject.send(newValue.size)
                    visibleViewportFrame = newValue
                        .divided(atDistance: scrollViewTopContentInset, from: .minYEdge)
                        .remainder
                        .divided(atDistance: scrollViewBottomContentInset, from: .maxYEdge)
                        .remainder
                }
                .onChange(of: draggedItemFrame) { draggedItemFrame in
                    changeAutoScrollStatusIfNeeded(draggedItemFrame: draggedItemFrame)
                }
                .onReceive(dragAndDropController.autoScrollTargetPublisher) { newValue in
                    withAnimation(.linear(duration: Constants.autoScrollFrequency)) {
                        scrollProxy.scrollTo(newValue, anchor: scrollAnchor())
                    }
                }
            }
        }
        .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        .onTapGesture {} // allows scroll to work, see https://developer.apple.com/forums/thread/127277 for details
        .gesture(makeDragAndDropGesture())
        .onChange(of: tokenListContentFrameMaxY) { newValue in
            withAnimation(.easeOut(duration: 0.1)) {
                isTokenListFooterGradientHidden = newValue < tokenListFooterFrameMinY
            }
        }
        .onChange(of: scrollViewContentOffset) { newValue in
            dragAndDropController.contentOffsetSubject.send(newValue)
            isNavigationBarBackgroundHidden = newValue.y <= 0.0
        }
        .onChange(of: dragAndDropDestinationIndexPath) { [oldValue = dragAndDropDestinationIndexPath] newValue in
            guard let oldValue = oldValue, let newValue = newValue else { return }

            dragAndDropController.onItemsMove()
            viewModel.move(from: oldValue, to: newValue)
        }
        .onChange(of: dragAndDropSourceIndexPath) { [oldValue = dragAndDropSourceIndexPath] newValue in
            guard oldValue != nil, newValue == nil else { return }

            dragAndDropSourceItemFrame = nil
        }
        .onChange(of: dragAndDropSourceViewModelIdentifier) { [oldValue = dragAndDropSourceViewModelIdentifier] newValue in
            guard oldValue != nil, newValue == nil else { return }

            dragAndDropController.stopAutoScrolling()
            viewModel.onDragAnimationCompletion()
        }
    }

    @ViewBuilder private var tokenListContent: some View {
        let parametersProvider = OrganizeTokensListCornerRadiusParametersProvider(
            sections: viewModel.sections,
            cornerRadius: Constants.cornerRadius
        )

        ForEach(indexed: viewModel.sections.indexed()) { sectionIndex, sectionViewModel in
            Section(
                content: {
                    ForEach(indexed: sectionViewModel.items.indexed()) { itemIndex, itemViewModel in
                        let indexPath = IndexPath(item: itemIndex, section: sectionIndex)

                        makeCell(
                            viewModel: itemViewModel,
                            indexPath: indexPath,
                            parametersProvider: parametersProvider
                        )
                        .hidden(itemViewModel.id == dragAndDropSourceViewModelIdentifier)
                        .id(itemViewModel.id)
                        .readGeometry(
                            \.frame,
                            inCoordinateSpace: .named(scrollViewContentCoordinateSpaceName)
                        ) { dragAndDropController.saveFrame($0, forItemAt: indexPath) }
                    }
                },
                header: {
                    let indexPath = IndexPath(item: viewModel.sectionHeaderItemIndex, section: sectionIndex)

                    makeSection(
                        viewModel: sectionViewModel,
                        sectionIndex: sectionIndex,
                        parametersProvider: parametersProvider
                    )
                    .hidden(sectionViewModel.id == dragAndDropSourceViewModelIdentifier)
                    .id(sectionViewModel.id)
                    .readGeometry(
                        \.frame,
                        inCoordinateSpace: .named(scrollViewContentCoordinateSpaceName)
                    ) { dragAndDropController.saveFrame($0, forItemAt: indexPath) }
                }
            )
        }
    }

    private var navigationBarBackground: some View {
        VisualEffectView(style: .systemUltraThinMaterial)
            .edgesIgnoringSafeArea(.top)
            .hidden(isNavigationBarBackgroundHidden)
            .infinityFrame(alignment: .bottom)
    }

    private var tokenListHeader: some View {
        OrganizeTokensListHeader(
            viewModel: viewModel.headerViewModel,
            scrollViewTopContentInset: $scrollViewTopContentInset,
            contentHorizontalInset: Constants.contentHorizontalInset,
            overlayViewAdditionalVerticalInset: Constants.overlayViewAdditionalVerticalInset,
            tokenListHeaderViewTopInset: Constants.tokenListHeaderViewTopInset
        )
        .background(navigationBarBackground)
        .infinityFrame(alignment: .top)
    }

    private var tokenListFooter: some View {
        OrganizeTokensListFooter(
            viewModel: viewModel,
            tokenListFooterFrameMinY: $tokenListFooterFrameMinY,
            scrollViewBottomContentInset: $scrollViewBottomContentInset,
            isTokenListFooterGradientHidden: isTokenListFooterGradientHidden,
            cornerRadius: Constants.cornerRadius,
            contentHorizontalInset: Constants.contentHorizontalInset,
            overlayViewAdditionalVerticalInset: Constants.overlayViewAdditionalVerticalInset
        )
    }

    init(
        viewModel: OrganizeTokensViewModel
    ) {
        self.viewModel = viewModel
        // Explicit @State/ @StateObject initialization is used here because we have a classic chicken-egg problem:
        // 'Cannot use instance member within property initializer; property initializers run before 'self' is available'
        let topContentInsetdentifier = UUID()
        let bottomContentInsetIdentifier = UUID()
        _scrollViewTopContentInsetSpacerIdentifier = .init(initialValue: topContentInsetdentifier)
        _scrollViewBottomContentInsetSpacerIdentifier = .init(initialValue: bottomContentInsetIdentifier)
        _dragAndDropController = .init(
            wrappedValue: OrganizeTokensDragAndDropController(
                autoScrollFrequency: Constants.autoScrollFrequency,
                destinationItemSelectionThresholdRatio: Constants.dragAndDropDestinationItemSelectionThresholdRatio,
                topEdgeAdditionalAutoScrollTargets: [topContentInsetdentifier],
                bottomEdgeAdditionalAutoScrollTargets: [bottomContentInsetIdentifier]
            )
        )
    }

    // MARK: - Gestures

    /// For more information about `Sequenced` gestures in SwiftUI see
    /// [official documentation](https://developer.apple.com/documentation/swiftui/composing-swiftui-gestures).
    private func makeDragAndDropGesture() -> some Gesture {
        LongPressGesture(minimumDuration: Constants.dragLiftLongPressGestureDuration)
            .sequenced(before: DragGesture())
            .updating($dragGestureTranslation) { value, state, _ in
                switch value {
                case .first:
                    break
                case .second(let isLongPressGestureEnded, let dragGestureValue):
                    // Long press gesture successfully ended (equivalent of `UIGestureRecognizer.State.ended`)
                    guard isLongPressGestureEnded else { return }

                    // Drag gesture changed (equivalent of `UIGestureRecognizer.State.changed`)
                    guard let dragGestureValue = dragGestureValue else { return }

                    state = dragGestureValue.translation
                }
            }
            .updating($dragAndDropSourceIndexPath) { [initialIndexPath = dragAndDropInitialIndexPath] value, state, _ in
                switch value {
                case .first(let isLongPressGestureBegins):
                    // Long press gesture began (equivalent of `UIGestureRecognizer.State.began`)
                    if isLongPressGestureBegins {
                        dragAndDropController.onDragPrepare()
                    }
                case .second(let isLongPressGestureEnded, let dragGestureValue):
                    // Long press gesture successfully ended (equivalent of `UIGestureRecognizer.State.ended`),
                    // drag gesture began, but hasn't been dragged yet (equivalent of `UIGestureRecognizer.State.began`)
                    guard
                        isLongPressGestureEnded,
                        dragGestureValue == nil,
                        let sourceIndexPath = initialIndexPath
                    else {
                        return
                    }

                    state = sourceIndexPath

                    // `DispatchQueue.main.async` used here to allow publishing changes during view update
                    DispatchQueue.main.async {
                        dragAndDropInitialIndexPath = nil // effectively consumes `self.dragAndDropInitialIndexPath`
                        dragAndDropSourceItemFrame = dragAndDropController.frame(forItemAt: sourceIndexPath)
                        dragAndDropSourceViewModelIdentifier = viewModel.viewModelIdentifier(at: sourceIndexPath)

                        dragAndDropController.onDragStart()
                        viewModel.onDragStart(at: sourceIndexPath)
                    }
                }
            }
            .updating($dragAndDropDestinationIndexPath) { value, state, _ in
                switch value {
                case .first:
                    break
                case .second(let isLongPressGestureEnded, let dragGestureValue):
                    // Long press gesture successfully ends (equivalent of `UIGestureRecognizer.State.ended`)
                    guard isLongPressGestureEnded else { return }

                    if let dragGestureValue = dragGestureValue,
                       let sourceIndexPath = dragAndDropSourceIndexPath,
                       let currentDestinationIndexPath = state {
                        if let updatedDestinationIndexPath = dragAndDropController.updatedDestinationIndexPath(
                            source: sourceIndexPath,
                            currentDestination: currentDestinationIndexPath,
                            translationValue: dragGestureValue.translation
                        ) {
                            // State after drag gesture changed its value
                            state = updatedDestinationIndexPath
                        }
                    } else {
                        // Initial state after successfully ended long press gesture
                        state = dragAndDropInitialIndexPath
                    }
                }
            }
    }

    private func onTouchesBegan(atLocation location: CGPoint) {
        if let initialIndexPath = dragAndDropController.indexPath(for: location),
           viewModel.canStartDragAndDropSession(at: initialIndexPath) {
            dragAndDropInitialIndexPath = initialIndexPath
        } else {
            dragAndDropInitialIndexPath = nil
        }
    }

    // MARK: - Auto scrolling support

    private func scrollAnchor() -> UnitPoint? {
        switch dragAndDropController.autoScrollStatus {
        case .active(.top):
            return .top
        case .active(.bottom):
            return .bottom
        case .inactive:
            return nil
        }
    }

    private func changeAutoScrollStatusIfNeeded(draggedItemFrame: CGRect) {
        guard visibleViewportFrame.canBeRendered, draggedItemFrame.canBeRendered else { return }

        let intersection = visibleViewportFrame.intersection(draggedItemFrame)
        if intersection.isNull || intersection.height < min(visibleViewportFrame.height, draggedItemFrame.height) {
            if draggedItemFrame.minY + Constants.autoScrollTriggerHeightDiff < visibleViewportFrame.minY {
                dragAndDropController.startAutoScrolling(direction: .top)
            } else if draggedItemFrame.maxY - Constants.autoScrollTriggerHeightDiff > visibleViewportFrame.maxY {
                dragAndDropController.startAutoScrolling(direction: .bottom)
            } else {
                // TODO: Andrey Fedorov - Doesn't work reliably since dragged view doesn't preserve a fixed position on the screen (IOS-3884)
                dragAndDropController.stopAutoScrolling()
            }
        }
    }

    // MARK: - View factories

    @ViewBuilder
    private func makeCell(
        viewModel: OrganizeTokensListItemViewModel,
        indexPath: IndexPath,
        parametersProvider: OrganizeTokensListCornerRadiusParametersProvider
    ) -> some View {
        OrganizeTokensListItemView(viewModel: viewModel)
            .background(Colors.Background.primary)
            .cornerRadius(
                parametersProvider.cornerRadius(forItemAt: indexPath),
                corners: parametersProvider.rectCorners(forItemAt: indexPath)
            )
    }

    @ViewBuilder
    private func makeSection(
        viewModel: OrganizeTokensListSectionViewModel,
        sectionIndex: Int,
        parametersProvider: OrganizeTokensListCornerRadiusParametersProvider
    ) -> some View {
        Group {
            switch viewModel.style {
            case .invisible:
                EmptyView()
            case .fixed(let title):
                OrganizeTokensListSectionView(title: title, isDraggable: false)
            case .draggable(let title):
                OrganizeTokensListSectionView(title: title, isDraggable: true)
            }
        }
        .background(Colors.Background.primary)
        .cornerRadius(
            parametersProvider.cornerRadius(forSectionAtIndex: sectionIndex),
            corners: parametersProvider.rectCorners(forSectionAtIndex: sectionIndex)
        )
    }

    @ViewBuilder
    private func makeDraggableComponent(width: CGFloat) -> some View {
        if let dragAndDropSourceIndexPath = dragAndDropSourceIndexPath,
           let dragAndDropSourceItemFrame = dragAndDropSourceItemFrame,
           let dragAndDropSourceViewModelIdentifier = dragAndDropSourceViewModelIdentifier,
           let dragAndDropDestinationIndexPath = dragAndDropDestinationIndexPath {
            let parametersProvider = OrganizeTokensListCornerRadiusParametersProvider(
                sections: viewModel.sections,
                cornerRadius: Constants.draggableViewCornerRadius
            )

            if let sectionViewModel = viewModel.sectionViewModel(for: dragAndDropSourceViewModelIdentifier) {
                makeDraggableView(
                    width: width,
                    indexPath: dragAndDropDestinationIndexPath,
                    itemFrame: dragAndDropSourceItemFrame
                ) {
                    makeSection(
                        viewModel: sectionViewModel,
                        sectionIndex: dragAndDropSourceIndexPath.section,
                        parametersProvider: parametersProvider
                    )
                }
            } else if let itemViewModel = viewModel.itemViewModel(for: dragAndDropSourceViewModelIdentifier) {
                makeDraggableView(
                    width: width,
                    indexPath: dragAndDropDestinationIndexPath,
                    itemFrame: dragAndDropSourceItemFrame
                ) {
                    makeCell(
                        viewModel: itemViewModel,
                        indexPath: dragAndDropSourceIndexPath,
                        parametersProvider: parametersProvider
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func makeDraggableView<Content>(
        width: CGFloat,
        indexPath: IndexPath,
        itemFrame: CGRect,
        @ViewBuilder content: () -> Content
    ) -> some View where Content: View {
        let scaleTransitionValue = width / (width * Constants.draggableViewScale)
        let offsetTransitionRatio = 1.0 - scaleTransitionValue

        let destinationFrame = dragAndDropController.frame(forItemAt: indexPath) ?? .zero
        let destinationOffset = destinationFrame.minY - (itemFrame.origin.y + dragGestureTranslation.height)

        let dummyProgressObserver = OrganizeTokensAnimationProgressObserverModifier(progress: 1.0, threshold: 1.0) {}
        let viewRemovalProgressObserver = OrganizeTokensAnimationProgressObserverModifier(
            progress: 0.0,
            threshold: Constants.dropAnimationProgressThresholdForViewRemoval
        ) {
            // `DispatchQueue.main.async` used here to allow publishing changes during view update
            DispatchQueue.main.async {
                dragAndDropSourceViewModelIdentifier = nil
            }
        }

        content()
            .frame(width: width)
            .readGeometry(\.frame, bindTo: $draggedItemFrame)
            .cornerRadiusContinuous(hasActiveDrag ? Constants.draggableViewCornerRadius : 0.0)
            .shadow(color: Color.black.opacity(0.08), radius: hasActiveDrag ? 14.0 : 0.0, y: 8.0) // TODO: Andrey Fedorov - Dark mode support (IOS-3927)
            .scaleEffect(Constants.draggableViewScale)
            .offset(y: itemFrame.origin.y)
            .offset(y: dragGestureTranslation.height)
            .transition(
                .asymmetric(
                    insertion: .scale(scale: scaleTransitionValue)
                        .combined(with: .offset(y: itemFrame.origin.y * offsetTransitionRatio))
                        .combined(with: .offset(y: dragGestureTranslation.height * offsetTransitionRatio)),
                    removal: .scale(scale: scaleTransitionValue)
                        .combined(with: .offset(y: itemFrame.origin.y * offsetTransitionRatio))
                        .combined(with: .offset(y: dragGestureTranslation.height * offsetTransitionRatio))
                        .combined(with: .offset(y: destinationOffset))
                        .combined(with: .modifier(active: viewRemovalProgressObserver, identity: dummyProgressObserver))
                )
            )
            .onDisappear { dragAndDropSourceViewModelIdentifier = nil }
    }
}

// MARK: - Constants

private extension OrganizeTokensView {
    private enum Constants {
        static let cornerRadius = 14.0
        static let overlayViewAdditionalVerticalInset = 10.0
        static let tokenListHeaderViewTopInset = 8.0
        static let contentHorizontalInset = 16.0
        static let dragLiftLongPressGestureDuration = 0.5
        static let dragLiftAnimationDuration = 0.35
        static let dropAnimationProgressThresholdForViewRemoval = 0.05
        static let dragAndDropDestinationItemSelectionThresholdRatio = 0.5
        static let draggableViewScale = 1.035
        static let draggableViewCornerRadius = 7.0
        static let autoScrollFrequency = 0.2
        static let autoScrollTriggerHeightDiff = 10.0
    }
}

// MARK: - Previews

struct OrganizeTokensView_Preview: PreviewProvider {
    private static let previewProvider = OrganizeTokensPreviewProvider()

    static var previews: some View {
        let viewModels = [
            previewProvider.multipleSections(),
            previewProvider.singleMediumSection(),
            previewProvider.singleSmallSection(),
            previewProvider.singleLargeSection(),
        ]

        Group {
            ForEach(viewModels.indexed(), id: \.0.self) { index, sections in
                OrganizeTokensView(
                    viewModel: .init(
                        coordinator: OrganizeTokensCoordinator(),
                        sections: sections
                    )
                )
            }
        }
    }
}
