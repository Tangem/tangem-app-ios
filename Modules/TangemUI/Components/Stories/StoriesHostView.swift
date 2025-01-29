//
//  StoriesHostView.swift
//  TangemModules
//
//  Created by Aleksei Lobankov on 30.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct StoriesHostView {
    @ObservedObject var viewModel: StoriesHostViewModel
    let storyViews: [StoryView]

    @Binding var isPresented: Bool

    @State private var verticalDragAmount = 0.0

    public init(isPresented: Binding<Bool>, storiesPages: [[AnyView]]) {
        self._isPresented = isPresented

        var storyViewModels = [StoryViewModel]()
        var storyViews = [StoryView]()

        storiesPages.forEach { erasedPages in
            let viewModel = StoryViewModel(pagesCount: erasedPages.count)
            let view = StoryView(viewModel: viewModel, pageViews: erasedPages.map(StoryPageView.init))

            storyViewModels.append(viewModel)
            storyViews.append(view)
        }

        self.viewModel = StoriesHostViewModel(storyViewModels: storyViewModels)
        self.storyViews = storyViews
    }

    public init(isPresented: Binding<Bool>, singleStoryPages: [AnyView]) {
        self.init(isPresented: isPresented, storiesPages: [singleStoryPages])
    }
}

// MARK: - SwiftUI.View conformance
extension StoriesHostView: View {
    public var body: some View {
        TabView(selection: $viewModel.visibleStoryIndex) {
            ForEach(Array(zip(storyViews.indices, storyViews)), id: \.0) { index, storyView in
                ZStack(alignment: .top) {
                    storyView
                        .tag(index)
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeOut(duration: 0.25), value: viewModel.visibleStoryIndex)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: verticalDragAmount)
        .gesture(dragGesture)
        .transition(.move(edge: .bottom))
        .onReceive(viewModel.$isPresented) { isPresented in
            self.isPresented = isPresented
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { drag in
                guard drag.translation.height > 0 else { return }
                viewModel.pauseVisibleStory()

                let dragGestureReactionCompensation: CGFloat = 20
                let dragAmount = max(drag.translation.height - dragGestureReactionCompensation, 0)

                withAnimation {
                    verticalDragAmount = dragAmount
                }
            }
            .onEnded { drag in
                viewModel.resumeVisibleStory()
                withAnimation {
                    if drag.translation.height > 80 {
                        isPresented = false
                    } else {
                        verticalDragAmount = 0
                    }
                }
            }
    }
}
