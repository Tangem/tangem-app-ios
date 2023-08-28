//
//  DisclaimerView.swift
//  Tangem
//
//  Created by Andrew Son on 23.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct DisclaimerView: View {
    let viewModel: DisclaimerViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            WebViewContainer(viewModel: viewModel.webViewModel)

            bottomView
        }
        .modifier(if: viewModel.showNavBarTitle) {
            $0.navigationBarTitle(Localization.disclaimerTitle)
        }
        .edgesIgnoringSafeArea(.bottom)
    }

    private var bottomView: some View {
        ZStack(alignment: .center) {
            LinearGradient(
                gradient: Gradient(stops: [
                    Gradient.Stop(color: Colors.Background.primary.opacity(0.2), location: 0.0),
                    Gradient.Stop(color: Colors.Background.primary, location: 0.5),
                    Gradient.Stop(color: Colors.Background.primary, location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(
                width: UIScreen.main.bounds.width,
                height: viewModel.bottomOverlayHeight
            )
        }
    }
}

struct DisclaimerView_Previews: PreviewProvider {
    private static var url: URL = .init(string: "https://tangem.com")!

    static var previews: some View {
        DisclaimerView(viewModel: .init(url: url, style: .onboarding))
            .previewGroup(devices: [.iPhone12Pro, .iPhone8Plus], withZoomed: false)

        NavigationView(content: {
            DisclaimerView(viewModel: .init(url: url, style: .details))
        })
    }
}
