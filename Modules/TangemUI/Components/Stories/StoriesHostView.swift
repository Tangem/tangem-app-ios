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

    public init(isPresented: Binding<Bool>, storiesPagesBuilder: (StoriesHostProxy) -> [[any View]]) {
        var storyViewModels = [StoryViewModel]()
        var storyViews = [StoryView]()

        weak var futureViewModel: StoriesHostViewModel?
        let controller = StoriesHostProxy(
            pauseVisibleStoryAction: {
                futureViewModel?.pauseVisibleStory()
            },
            resumeVisibleStoryAction: {
                futureViewModel?.resumeVisibleStory()
            }
        )

        storiesPagesBuilder(controller).forEach { erasedPages in
            let viewModel = StoryViewModel(pagesCount: erasedPages.count)
            let view = StoryView(viewModel: viewModel, pageViews: erasedPages.map(StoryPageView.init))

            storyViewModels.append(viewModel)
            storyViews.append(view)
        }

        let viewModel = StoriesHostViewModel(storyViewModels: storyViewModels)
        futureViewModel = viewModel

        _isPresented = isPresented
        self.viewModel = viewModel
        self.storyViews = storyViews
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
        .animation(.default, value: viewModel.visibleStoryIndex)
        .allowsHitTesting(viewModel.allowsHitTesting)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.move(edge: .bottom))
        .onReceive(viewModel.$isPresented) { isPresented in
            self.isPresented = isPresented
        }
        .ignoresSafeArea(.all, edges: .bottom)
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
        .allowsHitTesting(false)
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
        .allowsHitTesting(false)
    }
}

struct SampleStoryPage3: View {
    let pauseStoryAction: () -> Void
    let resumeStoryAction: () -> Void

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

            HStack {
                Button("Pause story", action: pauseStoryAction)
                    .gesture(DragGesture(minimumDistance: 0))

                Spacer()

                Button("Resume story", action: resumeStoryAction)
                    .gesture(DragGesture(minimumDistance: 0))
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.gray.allowsHitTesting(false)
        }
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
        .allowsHitTesting(false)
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
                storiesPagesBuilder: { proxy in
                    [
                        [
                            SampleStoryPage1(),
                            SampleStoryPage2(),
                            SampleStoryPage3(
                                pauseStoryAction: proxy.pauseVisibleStory,
                                resumeStoryAction: proxy.resumeVisibleStory
                            ),
                            SampleStoryPage4(),
                        ],
                        [
                            SampleStoryPage2(),
                            SampleStoryPage4(),
                            SampleStoryPage2(),
                        ],
                    ]
                }
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
            .storiesHost(isPresented: $isPresented) { proxy in
                [
                    SampleStoryPage3(
                        pauseStoryAction: proxy.pauseVisibleStory,
                        resumeStoryAction: proxy.resumeVisibleStory
                    ),
                    SampleStoryPage2(),
                    SampleStoryPage1(),
                ]
            }
        }
    }

    return Preview()
}

#endif
