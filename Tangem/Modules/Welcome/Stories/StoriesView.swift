//
//  StoriesView.swift
//  StoriesDemo
//
//  Created by Andrey Chukavin on 26.01.2022.
//

import SwiftUI

struct StoriesView: View {
    @ObservedObject var viewModel: StoriesViewModel

    var body: some View {
        ZStack {
            if viewModel.checkingPromotionAvailability {
                Color.black
                    .ignoresSafeArea()
                    .task {
                        await viewModel.checkPromotion()
                    }
            } else {
                contentView
            }
        }
        .animation(.default, value: viewModel.checkingPromotionAvailability)
    }

    @ViewBuilder
    var contentView: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                currentStoryPage()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged {
                                viewModel.didDrag($0.location)
                            }
                            .onEnded {
                                viewModel.didEndDrag($0.location, destination: $0.predictedEndLocation, viewWidth: geo.size.width)
                            }
                    )

                StoriesProgressView(pages: viewModel.pages, currentPageIndex: viewModel.currentPageIndex, progress: $viewModel.currentProgress)
                    .padding(.horizontal)
                    .padding(.top)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    @ViewBuilder
    func currentStoryPage() -> some View {
        switch viewModel.currentPage {
        case WelcomeStoryPage.learn:
            LearnAndEarnStoryPage(
                learn: { viewModel.delegate?.openPromotion() }
            )
        case WelcomeStoryPage.meetTangem:
            MeetTangemStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                scanCard: { viewModel.delegate?.scanCard() },
                orderCard: { viewModel.delegate?.orderCard() }
            )
        case WelcomeStoryPage.awe:
            AweStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                scanCard: { viewModel.delegate?.scanCard() },
                orderCard: { viewModel.delegate?.orderCard() }
            )
        case WelcomeStoryPage.backup:
            BackupStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                scanCard: { viewModel.delegate?.scanCard() },
                orderCard: { viewModel.delegate?.orderCard() }
            )
        case WelcomeStoryPage.currencies:
            CurrenciesStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                scanCard: { viewModel.delegate?.scanCard() },
                orderCard: { viewModel.delegate?.orderCard() },
                searchTokens: { viewModel.delegate?.openTokenList() }
            )
        //        case WelcomeStoryPage.web3:
        //            Web3StoryPage(
        //                progress: viewModel.currentProgress,
        //                isScanning: viewModel.makeScanBinding(),
        //                scanCard: { viewModel.delegate?.scanCard() },
        //                orderCard: { viewModel.delegate?.orderCard() }
        //            )
        case WelcomeStoryPage.finish:
            FinishStoryPage(
                progress: viewModel.currentProgress,
                isScanning: viewModel.isScanning,
                scanCard: { viewModel.delegate?.scanCard() },
                orderCard: { viewModel.delegate?.orderCard() }
            )
        }
    }
}

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(viewModel: StoriesViewModel())
    }
}
