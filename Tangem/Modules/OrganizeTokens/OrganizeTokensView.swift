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

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Coordinate spaces

    // Semantically, this is the same as `UIScrollView.frameLayoutGuide` from UIKit
    private let scrollViewFrameCoordinateSpaceName = UUID()

    // Semantically, this is the same as `UIScrollView.contentLayoutGuide` from UIKit
    private let scrollViewContentCoordinateSpaceName = UUID()

    // MARK: - Content insets and overlay views

    @StateObject private var scrollState = OrganizeTokensScrollState(bottomInset: Constants.headerAdditionalBottomInset)

    // TODO: Will be updated in IOS-5884
    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var scrollViewTopContentInset: CGFloat = 0.0

    // TODO: Will be updated in IOS-5884
    @available(iOS, introduced: 13.0, deprecated: 15.0, message: "Replace with native .safeAreaInset()")
    @State private var scrollViewBottomContentInset: CGFloat = 0.0

    @State private var scrollViewTopContentInsetSpacerIdentifier: UUID
    @State private var scrollViewBottomContentInsetSpacerIdentifier: UUID

    // MARK: - Drag and drop support

    @StateObject private var dragAndDropController: OrganizeTokensDragAndDropController

    @State private var dragAndDropSourceIndexPath: IndexPath?

    @State private var dragAndDropDestinationIndexPath: IndexPath?

    // In a `scrollViewContentCoordinateSpaceName` coordinate space
    @State private var dragAndDropSourceItemFrame: CGRect?

    // Stable identity, independent of changes in the underlying model (unlike index paths)
    @State private var dragAndDropSourceViewModelIdentifier: AnyHashable?

    @State private var dragGestureTranslation: CGSize?

    // Semantically, this is the same as `UITableView.hasActiveDrag` from UIKit
    private var hasActiveDrag: Bool { dragAndDropSourceIndexPath != nil }

    // MARK: - Auto scrolling support

    // Viewport insetted by `contentInset` (i.e. by `scrollViewTopContentInset` and `scrollViewBottomContentInset`)
    @State private var visibleViewportFrame: CGRect = .zero

    // In a `.global` coordinate space
    @State private var draggedItemFrame: CGRect = .zero

    // `Initial` here means 'at the beginning of the drag and drop gesture'.
    @State private var scrollViewInitialContentOffset: CGPoint = .zero

    // Adopts changes in scroll view content offset (`scrollViewContentCoordinateSpaceName` coordinate space)
    // to the drag gesture translation (`scrollViewFrameCoordinateSpaceName` coordinate space).
    // Changes can be made by drag-and-drop auto scroll, for example.
    private var dragGestureTranslationFix: CGSize {
        return CGSize(
            width: 0.0,
            height: scrollState.contentOffset.y - scrollViewInitialContentOffset.y
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            tokenList

            tokenListHeader

            tokenListFooter
        }
        .background(
            Colors.Background.secondary
                .ignoresSafeArea(edges: .vertical)
        )
        .onWillAppear {
            dragAndDropController.dataSource = viewModel
            viewModel.onViewWillAppear()
        }
        .onAppear {
            viewModel.onViewAppear()
            scrollState.onViewAppear()
        }
    }

    // MARK: - Subviews

    private var tokenList: some View {
        GeometryReader { geometryProxy in
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    // ScrollView inserts default spacing between its content views.
                    // Wrapping content into `VStack` prevents it.
                    VStack(spacing: 0.0) {
                        LazyVStack(spacing: 0.0) {
                            Spacer(minLength: scrollViewTopContentInset)
                                .fixedSize()
                                .id(scrollViewTopContentInsetSpacerIdentifier)

                            tokenListContent
                        }
                        .animation(.spring(), value: viewModel.sections)
                        .padding(.horizontal, Constants.contentHorizontalInset)
                        .coordinateSpace(name: scrollViewContentCoordinateSpaceName)
                        .readGeometry(
                            \.frame.maxY,
                            inCoordinateSpace: .global,
                            bindTo: scrollState.tokenListContentFrameMaxYSubject.asWriteOnlyBinding(.zero)
                        )
                        .readContentOffset(
                            inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName),
                            bindTo: scrollState.contentOffsetSubject.asWriteOnlyBinding(.zero)
                        )
                        .overlay(makeDragAndDropGestureOverlayView())

                        Spacer(minLength: scrollViewBottomContentInset)
                            .fixedSize()
                            .id(scrollViewBottomContentInsetSpacerIdentifier)
                    }
                }
                .readGeometry(\.frame, inCoordinateSpace: .global) { newValue in
                    dragAndDropController.viewportSizeSubject.send(newValue.size)
                    visibleViewportFrame = newValue
                        .divided(atDistance: scrollViewTopContentInset, from: .minYEdge)
                        .remainder
                        .divided(atDistance: scrollViewBottomContentInset, from: .maxYEdge)
                        .remainder
                }
                .onChange(of: draggedItemFrame) { newValue in
                    changeAutoScrollStatusIfNeeded(draggedItemFrame: newValue)
                }
                .onReceive(dragAndDropController.autoScrollTargetPublisher) { newValue in
                    withAnimation(.linear(duration: Constants.autoScrollFrequency)) {
                        scrollProxy.scrollTo(newValue, anchor: scrollAnchor())
                    }
                }
            }
            .overlay(
                makeDraggableComponent(width: geometryProxy.size.width - Constants.contentHorizontalInset * 2.0)
                    .animation(.linear(duration: Constants.dragLiftAnimationDuration), value: hasActiveDrag),
                alignment: .top
            )
        }
        .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        .onReceive(scrollState.contentOffsetSubject) { newValue in
            dragAndDropController.contentOffsetSubject.send(newValue)
            updateDragAndDropDestinationIndexPath(using: dragGestureTranslation)
        }
        .onChange(of: dragAndDropDestinationIndexPath) { [oldValue = dragAndDropDestinationIndexPath] newValue in
            guard let oldValue = oldValue, let newValue = newValue else { return }

            dragAndDropController.onItemsMove()
            viewModel.move(from: oldValue, to: newValue)
        }
        .onChange(of: hasActiveDrag) { newValue in
            if newValue {
                scrollState.onDragStart()
            } else {
                // Perform required clean-up when the user lifts the finger
                scrollState.onDragEnd()
                dragAndDropController.stopAutoScrolling()
                dragAndDropDestinationIndexPath = nil
                dragAndDropSourceItemFrame = nil
            }
        }
        .onChange(of: dragGestureTranslation) { newValue in
            updateDragAndDropDestinationIndexPath(using: newValue)
        }
    }

    @ViewBuilder private var tokenListContent: some View {
        let parametersProvider = OrganizeTokensListCornerRadiusParametersProvider(
            sections: viewModel.sections,
            cornerRadius: Constants.contentCornerRadius
        )

        ForEach(indexed: viewModel.sections.indexed()) { sectionIndex, sectionViewModel in
            Section(
                content: {
                    ForEach(indexed: sectionViewModel.items.indexed()) { itemIndex, itemViewModel in
                        let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                        let identifier = itemViewModel.id
                        let isDragged = identifier.asAnyHashable == dragAndDropSourceViewModelIdentifier

                        makeCell(
                            viewModel: itemViewModel,
                            indexPath: indexPath,
                            parametersProvider: parametersProvider
                        )
                        .hidden(isDragged)
                        .readGeometry(
                            \.frame,
                            inCoordinateSpace: .named(scrollViewContentCoordinateSpaceName)
                        ) { frame in
                            if !isDragged {
                                dragAndDropController.saveFrame(frame, forItemAt: indexPath)
                            }
                        }
                        .id(identifier)
                    }
                },
                header: {
                    let indexPath = IndexPath(item: viewModel.sectionHeaderItemIndex, section: sectionIndex)
                    let identifier = sectionViewModel.id
                    let isDragged = identifier == dragAndDropSourceViewModelIdentifier

                    makeSection(
                        from: sectionViewModel,
                        atIndex: sectionIndex,
                        parametersProvider: parametersProvider
                    )
                    .hidden(isDragged)
                    .readGeometry(
                        \.frame,
                        inCoordinateSpace: .named(scrollViewContentCoordinateSpaceName)
                    ) { frame in
                        if !isDragged {
                            dragAndDropController.saveFrame(frame, forItemAt: indexPath)
                        }
                    }
                    .id(identifier)
                    .padding(.top, sectionIndex == 0 ? 0.0 : Constants.headerBottomInset)
                }
            )
        }
    }

    private var tokenListHeader: some View {
        OrganizeTokensListHeader(
            viewModel: viewModel.headerViewModel,
            horizontalInset: Constants.contentHorizontalInset,
            bottomInset: Constants.headerBottomInset
        )
        .background(.bar.hidden(scrollState.isNavigationBarBackgroundHidden))
        .padding(.bottom, Constants.headerAdditionalBottomInset)
        .readGeometry(\.size.height, bindTo: $scrollViewTopContentInset)
        .infinityFrame(alignment: .top)
    }

    private var tokenListFooter: some View {
        OrganizeTokensListFooter(
            viewModel: viewModel,
            isTokenListFooterGradientHidden: scrollState.isTokenListFooterGradientHidden,
            cornerRadius: Constants.contentCornerRadius,
            contentInsets: EdgeInsets(
                top: Constants.contentVerticalInset,
                leading: Constants.contentHorizontalInset,
                bottom: 0.0,
                trailing: Constants.contentHorizontalInset
            )
        )
        .animation(.linear(duration: 0.1), value: scrollState.isTokenListFooterGradientHidden)
        .readGeometry(inCoordinateSpace: .global) { geometryInfo in
            scrollState.tokenListFooterFrameMinYSubject.send(geometryInfo.frame.minY + Constants.contentVerticalInset)
            $scrollViewBottomContentInset.wrappedValue = geometryInfo.size.height
        }
        .infinityFrame(alignment: .bottom)
    }

    init(
        viewModel: OrganizeTokensViewModel
    ) {
        self.viewModel = viewModel
        // Explicit @State/ @StateObject initialization is used here because we have a classic chicken-egg problem:
        // 'Cannot use instance member within property initializer; property initializers run before 'self' is available'
        let topContentInsetIdentifier = UUID()
        let bottomContentInsetIdentifier = UUID()
        _scrollViewTopContentInsetSpacerIdentifier = .init(initialValue: topContentInsetIdentifier)
        _scrollViewBottomContentInsetSpacerIdentifier = .init(initialValue: bottomContentInsetIdentifier)
        _dragAndDropController = .init(
            wrappedValue: OrganizeTokensDragAndDropController(
                autoScrollFrequency: Constants.autoScrollFrequency,
                destinationItemSelectionThresholdRatio: Constants.dragAndDropDestinationItemSelectionThresholdRatio,
                topEdgeAdditionalAutoScrollTargets: [topContentInsetIdentifier],
                bottomEdgeAdditionalAutoScrollTargets: [bottomContentInsetIdentifier]
            )
        )
    }

    // MARK: - Drag and drop support

    private func newDragAndDropSessionPrecondition() {
        // The following assertions verify that the drag-and-drop related @State variables
        // have been properly reset at the end of the previous drag-and-drop session
        assert(dragAndDropDestinationIndexPath == nil)
        assert(dragAndDropSourceItemFrame == nil)
        assert(dragAndDropSourceViewModelIdentifier == nil)
    }

    private func updateDragAndDropDestinationIndexPath(using dragGestureTranslation: CGSize?) {
        guard
            let dragGestureTranslation = dragGestureTranslation,
            let sourceIndexPath = dragAndDropSourceIndexPath,
            let currentDestinationIndexPath = dragAndDropDestinationIndexPath,
            let updatedDestinationIndexPath = dragAndDropController.updatedDestinationIndexPath(
                source: sourceIndexPath,
                currentDestination: currentDestinationIndexPath,
                translationValue: dragGestureTranslation + dragGestureTranslationFix
            )
        else {
            return
        }

        dragAndDropDestinationIndexPath = updatedDestinationIndexPath
    }

    private func resetGestureState() {
        scrollViewInitialContentOffset = .zero
        dragAndDropSourceIndexPath = nil
        dragGestureTranslation = nil
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
        guard
            hasActiveDrag,
            visibleViewportFrame.canBeRendered,
            draggedItemFrame.canBeRendered
        else {
            return
        }

        let intersection = visibleViewportFrame.intersection(draggedItemFrame)
        if intersection.height < min(visibleViewportFrame.height, draggedItemFrame.height) {
            if draggedItemFrame.minY + Constants.autoScrollTriggerHeightDiff < visibleViewportFrame.minY {
                dragAndDropController.startAutoScrolling(direction: .top)
            } else if draggedItemFrame.maxY - Constants.autoScrollTriggerHeightDiff > visibleViewportFrame.maxY {
                dragAndDropController.startAutoScrolling(direction: .bottom)
            }
        } else if !intersection.isNull {
            dragAndDropController.stopAutoScrolling()
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
        from section: OrganizeTokensListSection,
        atIndex sectionIndex: Int,
        parametersProvider: OrganizeTokensListCornerRadiusParametersProvider
    ) -> some View {
        Group {
            switch section.model.style {
            case .invisible:
                EmptyView()
            case .fixed(let title):
                OrganizeTokensListSectionView(title: title, isDraggable: false)
            case .draggable(let title):
                OrganizeTokensListSectionView(title: title, identifier: section.model.id, isDraggable: true)
            }
        }
        .background(Colors.Background.primary)
        .cornerRadius(
            parametersProvider.cornerRadius(forSectionAtIndex: sectionIndex),
            corners: parametersProvider.rectCorners(forSectionAtIndex: sectionIndex)
        )
    }

    @ViewBuilder
    private func makeDragAndDropGestureOverlayView() -> some View {
        DragAndDropGestureView(
            minimumPressDuration: Constants.dragAndDropGestureDuration,
            allowableMovement: Constants.dragAndDropGestureAllowableMovement,
            gesturePredicate: OrganizeTokensDragAndDropGesturePredicate(),
            contextProvider: OrganizeTokensDragAndDropGestureContextProvider(),
            onLongPressChanged: { isRecognized, context in
                if isRecognized {
                    guard
                        let sourceViewModelIdentifier = context,
                        let sourceIndexPath = viewModel.indexPath(for: sourceViewModelIdentifier)
                    else {
                        return
                    }

                    // One-time assignment before the value of drag gesture changes for the first time
                    scrollViewInitialContentOffset = scrollState.contentOffset

                    // Set initial state for `dragAndDropSourceIndexPath` after successfully ended long press gesture
                    dragAndDropSourceIndexPath = sourceIndexPath

                    // Set initial state for `dragAndDropDestinationIndexPath` after successfully ended long press gesture
                    dragAndDropDestinationIndexPath = sourceIndexPath
                    dragAndDropSourceItemFrame = dragAndDropController.frame(forItemAt: sourceIndexPath)
                    dragAndDropSourceViewModelIdentifier = sourceViewModelIdentifier

                    dragAndDropController.onDragStart()
                    viewModel.onDragStart(at: sourceIndexPath)
                } else {
                    newDragAndDropSessionPrecondition()
                    dragAndDropController.onDragPrepare()
                }
            },
            onDragChanged: { translation, _ in
                dragGestureTranslation = translation
            },
            onEnded: { _ in
                resetGestureState()
            },
            onCancel: { _ in
                resetGestureState()
            }
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

            makeDraggableView(
                width: width,
                indexPath: dragAndDropDestinationIndexPath,
                itemFrame: dragAndDropSourceItemFrame
            ) {
                if let section = viewModel.section(for: dragAndDropSourceViewModelIdentifier) {
                    makeSection(
                        from: section,
                        atIndex: dragAndDropSourceIndexPath.section,
                        parametersProvider: parametersProvider
                    )
                } else if let itemViewModel = viewModel.itemViewModel(for: dragAndDropSourceViewModelIdentifier) {
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

        let destinationItemFrame = dragAndDropController.frame(forItemAt: indexPath) ?? .zero
        let baseOffsetTransitionValue = itemFrame.origin.y + (dragGestureTranslation?.height ?? .zero)
        let totalOffsetTransitionValue = baseOffsetTransitionValue - scrollViewInitialContentOffset.y

        let additionalOffsetRemovalTransitionValue = destinationItemFrame.minY
            - baseOffsetTransitionValue
            - dragGestureTranslationFix.height

        content()
            .frame(width: width)
            .readGeometry(\.frame, inCoordinateSpace: .global, bindTo: $draggedItemFrame)
            .scaleEffect(Constants.draggableViewScale)
            .offset(y: totalOffsetTransitionValue)
            .transition(
                .scale(scale: scaleTransitionValue)
                    .combined(with: .offset(y: totalOffsetTransitionValue * offsetTransitionRatio))
                    .combined(
                        with: .asymmetric(
                            insertion: .identity,
                            removal: .offset(y: additionalOffsetRemovalTransitionValue)
                        )
                    )
                    .combined(
                        with: .cornerRadius(
                            insertionOffset: totalOffsetTransitionValue,
                            removalOffset: totalOffsetTransitionValue + additionalOffsetRemovalTransitionValue
                        )
                    )
                    .combined(with: .shadow(colorScheme: colorScheme))
                    .combined(with: .onViewRemoval { dragAndDropSourceViewModelIdentifier = nil })
            )
            .onDisappear {
                // Perform required clean-up when the view removal animation finishes
                //
                // `dragAndDropSourceViewModelIdentifier` nullified here one more time,
                // in case if `AnyTransition.onViewRemoval` is unexpectedly cancelled
                dragAndDropSourceViewModelIdentifier = nil
                viewModel.onDragAnimationCompletion()
            }
    }
}

// MARK: - Convenience extensions

private extension AnyTransition {
    static func shadow(colorScheme: ColorScheme) -> AnyTransition {
        let color: Color
        let radius: CGFloat
        let offset: CGPoint

        switch colorScheme {
        case .dark:
            color = Color.black.opacity(0.26)
            radius = 20.0
            offset = CGPoint(x: 0.0, y: 2.0)
        case .light:
            fallthrough
        @unknown default:
            color = Color.black.opacity(0.08)
            radius = 14.0
            offset = CGPoint(x: 0.0, y: 8.0)
        }

        return .modifier(
            active: ShadowAnimatableModifier(progress: 0.0, color: color, radius: radius, offset: offset),
            identity: ShadowAnimatableModifier(progress: 1.0, color: color, radius: radius, offset: offset)
        )
    }

    static func cornerRadius(insertionOffset: CGFloat, removalOffset: CGFloat) -> AnyTransition {
        return .modifier(
            active: CornerRadiusAnimatableModifier(
                progress: 0.0,
                cornerRadius: 0.0,
                cornerRadiusStyle: .continuous
            ) { clipShape in
                clipShape
                    .scale(1.0)
                    .offset(y: removalOffset)
            },
            identity: CornerRadiusAnimatableModifier(
                progress: 1.0,
                cornerRadius: OrganizeTokensView.Constants.draggableViewCornerRadius,
                cornerRadiusStyle: .continuous
            ) { clipShape in
                clipShape
                    .scale(OrganizeTokensView.Constants.draggableViewScale)
                    .offset(y: insertionOffset)
            }
        )
    }

    static func onViewRemoval(perform action: @escaping () -> Void) -> AnyTransition {
        let dummyViewInsertionProgressObserver = AnimationProgressObserverModifier(observedValue: 1.0) {}
        let viewRemovalProgressObserver = AnimationProgressObserverModifier(
            observedValue: 0.0,
            targetValue: OrganizeTokensView.Constants.dropAnimationProgressThresholdForViewRemoval,
            valueComparator: <=,
            action: action
        )

        return .modifier(
            active: viewRemovalProgressObserver,
            identity: dummyViewInsertionProgressObserver
        )
    }
}

// MARK: - Constants

private extension OrganizeTokensView {
    enum Constants {
        static let contentCornerRadius = 14.0
        static let headerBottomInset = 10.0
        static var headerAdditionalBottomInset: CGFloat { contentVerticalInset - headerBottomInset }
        static let contentVerticalInset = 14.0
        static let contentHorizontalInset = 16.0
        static let dragAndDropGestureDuration = 0.15
        static let dragAndDropGestureAllowableMovement = 5.0
        static let dragLiftAnimationDuration = 0.2
        static let dropAnimationProgressThresholdForViewRemoval = 0.1
        static let dragAndDropDestinationItemSelectionThresholdRatio = 0.5
        static let draggableViewScale = 1.035
        static let draggableViewCornerRadius = 7.0
        static let autoScrollFrequency = 0.2
        static let autoScrollTriggerHeightDiff = 10.0
    }
}

// MARK: - Previews

struct OrganizeTokensView_Preview: PreviewProvider {
    static var previews: some View {
        let viewModelFactory = OrganizeTokensPreviewViewModelFactory()

        ForEach(OrganizeTokensPreviewConfiguration.allCases, id: \.name) { previewConfiguration in
            let viewModel = viewModelFactory.makeViewModel(for: previewConfiguration)
            OrganizeTokensView(viewModel: viewModel)
                .previewLayout(.sizeThatFits)
                .previewDisplayName(previewConfiguration.name)
        }
    }
}
