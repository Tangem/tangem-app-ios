//
//  BottomSheetContainer.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 15.0, *)
struct BottomSheetContainer<Item, ContentView: View>: View {
    @Binding private var isVisible: Bool
    private let settings: Settings
    private let content: () -> ContentView?

    // MARK: - Internal

    @State private var contentHeight: CGFloat = 400
    @State private var isDragging: Bool = false
    @State private var previousDragTranslation: CGSize = .zero
    @State private var offset: CGFloat = UIScreen.main.bounds.height

    private let indicatorSize = CGSize(width: 40, height: 4)

    private var dragPercentage: CGFloat {
        let visibleHeight = contentHeight - offset
        let percentage = visibleHeight / contentHeight
        return max(0, percentage)
    }

    private var opacity: CGFloat {
        max(0, settings.backgroundOpacity * dragPercentage)
    }

    init(
        isVisible: Binding<Bool>,
        settings: Settings,
        @ViewBuilder content: @escaping () -> ContentView?
    ) {
        _isVisible = isVisible
        self.settings = settings
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isVisible {
                Color.black.opacity(opacity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideView()
                    }

                sheetView
                    .transition(.move(edge: .bottom))
                    // Fix for black outing the sheet after dismiss externally
                    .zIndex(1)

                settings.backgroundColor
                    // For hide bottom space when sheet is up
                    .frame(height: abs(min(0, offset)))
                    // Added to hide the line between views
                    .offset(y: -1)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .animation(isDragging ? .interactiveSpring() : .easeInOut(duration: settings.animationDuration))
        .onChange(of: isVisible, perform: updateVisibility)
        .onAppear { updateVisibility(isVisible: isVisible) }
    }

    private var sheetView: some View {
        VStack(spacing: 0) {
            indicator

            if let contentView = content() {
                contentView
                    .padding(.bottom, UIApplication.safeAreaInsets.bottom)
            }
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
        .cornerRadius(settings.cornerRadius, corners: [.topLeft, .topRight])
        .readSize { contentHeight = $0.height }
        .gesture(dragGesture)
        .offset(y: offset)
    }

    private var indicator: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.secondary)
                .frame(size: indicatorSize)
                .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }

                let dragValue = value.translation.height - previousDragTranslation.height
                let locationChange = value.startLocation.y - value.location.y

                if locationChange > 0 {
                    offset += dragValue / 3
                } else {
                    offset += dragValue
                }

                previousDragTranslation = value.translation
            }
            .onEnded { value in
                previousDragTranslation = .zero
                isDragging = false

                // If swipe did be enough then hide view
                if value.translation.height > settings.distanceToHide {
                    hideView()
                    // Otherwise set the view to default state
                } else {
                    offset = 0
                }
            }
    }

    // MARK: - Methods

    private func updateVisibility(isVisible: Bool) {
        if isVisible {
            offset = 0
        } else {
            hideView()
        }
    }

    private func hideView() {
        offset = UIScreen.main.bounds.height
        guard isVisible else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + settings.animationDuration) {
            isVisible = false
        }
    }

    private func showView() {
        offset = 0
    }
}

@available(iOS 15.0, *)
extension BottomSheetContainer {
    struct Settings {
        let cornerRadius: CGFloat
        let backgroundColor: Color
        let backgroundOpacity: CGFloat
        let distanceToHide: CGFloat
        let animationDuration: Double

        init(
            cornerRadius: CGFloat = 16,
            backgroundColor: Color = Colors.Background.secondary,
            backgroundOpacity: CGFloat = 0.5,
            distanceToHide: CGFloat = UIScreen.main.bounds.height * 0.1,
            animationDuration: Double = 0.45
        ) {
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.backgroundOpacity = backgroundOpacity
            self.distanceToHide = distanceToHide
            self.animationDuration = animationDuration
        }
    }
}

@available(iOS 15.0, *)
struct BottomSheetContainer_Previews: PreviewProvider {
    struct StatableContainer: View {
        @State private var item: SwappingPermissionViewModel? = nil

        var body: some View {
            ZStack {
                Color.green
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((item != nil).description)") {
                    toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $item) {
                        SwappingPermissionView(viewModel: $0)
                    }
            }
        }

        func toggleItem() {
            let isShowing = item != nil

            if !isShowing {
                item = SwappingPermissionViewModel(
                    inputModel: SwappingPermissionInputModel(fiatFee: 1.45, transactionData: .mock),
                    transactionSender: TransactionSenderMock(),
                    coordinator: SwappingCoordinator()
                )
            } else {
                item = nil
            }
        }
    }

    static var previews: some View {
        StatableContainer()
    }
}
