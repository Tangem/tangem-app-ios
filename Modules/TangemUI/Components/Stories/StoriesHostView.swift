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
        _isPresented = isPresented

        var storyViewModels = [StoryViewModel]()
        var storyViews = [StoryView]()

        storiesPages.forEach { erasedPages in
            let viewModel = StoryViewModel(pagesCount: erasedPages.count)
            let view = StoryView(viewModel: viewModel, pageViews: erasedPages.map(StoryPageView.init))

            storyViewModels.append(viewModel)
            storyViews.append(view)
        }

        viewModel = StoriesHostViewModel(storyViewModels: storyViewModels)
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

// MARK: - Previews

#if DEBUG

struct SampleStoryPage1: View {
    var body: some View {
        VStack {
            Text("Story Page")
                .font(.title)
                .fontWeight(.bold)

            Text("Sample text")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray)
    }
}

struct SampleStoryPage2: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 50) {
            Text("Another page")
                .font(.title)
                .scaleEffect(isAnimating ? 0.75 : 1)
                .animation(
                    isAnimating
                        ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                        : .default,
                    value: isAnimating
                )
                .foregroundStyle(.background)

            Circle()
                .fill(.blue)
                .frame(width: 50, height: 50)
                .scaleEffect(isAnimating ? 1.5 : 1)
                .animation(
                    isAnimating
                        ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        : .default,
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct SampleStoryPage3: View {
    var body: some View {
        VStack {
            Text("Another one")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.cyan)

            Image(systemName: "swift")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.tertiary)
    }
}

struct SampleStoryPage4: View {
    var body: some View {
        (0 ..< 100).reduce(Text("stories ").italic()) { previous, _ in
            previous + Text(" stories ").italic()
        }
        .font(.largeTitle)
        .fontWeight(.black)
        .foregroundStyle(.cyan)
    }
}

#Preview("Multiple stories") {
    struct Preview: View {
        @State var isPresented = false

        var body: some View {
            VStack {
                Button("Show stories") {
                    isPresented = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .storiesHost(
                isPresented: $isPresented,
                storiesPages: [
                    [
                        AnyView(SampleStoryPage1()),
                        AnyView(SampleStoryPage2()),
                        AnyView(SampleStoryPage3()),
                        AnyView(SampleStoryPage4()),
                    ],
                    [
                        AnyView(SampleStoryPage2()),
                        AnyView(SampleStoryPage4()),
                        AnyView(SampleStoryPage2()),
                    ],
                    [
                        AnyView(Color.red),
                        AnyView(Color.orange),
                        AnyView(Color.purple),
                        AnyView(Color.yellow),
                        AnyView(Color.brown),
                    ],
                ]
            )
        }
    }

    return Preview()
}

#Preview("Single story with multiple pages") {
    struct Preview: View {
        @State var isPresented = false

        var body: some View {
            VStack {
                Button("Show stories") {
                    isPresented = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .storiesHost(isPresented: $isPresented) {
                SampleStoryPage4()
                SampleStoryPage2()
                SampleStoryPage1()
                SampleStoryPage3()
            }
        }
    }

    return Preview()
}

#endif
