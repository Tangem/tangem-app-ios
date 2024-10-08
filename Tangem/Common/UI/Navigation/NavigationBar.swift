//
//  NavigationBar.swift
//  Tangem
//
//  Created by Andrew Son on 21/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct ArrowBack: View {
    let action: () -> Void
    let height: CGFloat
    var color: Color = Colors.Old.tangemGrayDark6

    var body: some View {
        Button(action: action, label: {
            Image(systemName: "chevron.left")
                .frame(width: height, height: height)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
        })
        .frame(width: height, height: height)
    }
}

private enum DefaultNavigationBarSettings {
    static let color = Colors.Old.tangemGrayDark6
    static let padding = 16.0
}

struct BackButton: View {
    let height: CGFloat
    let isVisible: Bool
    let isEnabled: Bool
    var color: Color = DefaultNavigationBarSettings.color
    var hPadding: CGFloat = DefaultNavigationBarSettings.padding
    let action: () -> Void

    var body: some View {
        Button(action: action, label: {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .padding(-1) // remove default? extra padding
                Text(Localization.commonBack)
                    .font(.system(size: 17, weight: .regular))
            }
        })
        .allowsHitTesting(isEnabled)
        .hidden(!isVisible)
        .frame(height: height)
        .foregroundColor(isEnabled ? color : color.opacity(0.5))
        .padding(.horizontal, hPadding)
    }
}

struct SupportButton: View {
    let height: CGFloat
    let isVisible: Bool
    let isEnabled: Bool
    var color: Color = Colors.Old.tangemGrayDark6
    var hPadding: CGFloat = 16
    let action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Text(Localization.commonSupport)
                .font(.system(size: 17, weight: .regular))
        })
        .allowsHitTesting(isEnabled)
        .opacity(isVisible ? 1.0 : 0.0)
        .frame(height: height)
        .foregroundColor(isEnabled ? color : color.opacity(0.5))
        .padding(.horizontal, hPadding)
    }
}

struct NavigationBar<LeftButtons: View, RightButtons: View>: View {
    struct Settings {
        struct Title {
            var font: Font = .system(size: 17, weight: .medium)
            var color: Color = Colors.Old.tangemGrayDark6
            var lineLimit: Int? = nil // Default system value
            var minimumScaleFactor: CGFloat = 1 // Default system value
        }

        let title: Title
        let backgroundColor: Color
        let horizontalPadding: CGFloat
        let height: CGFloat
        let alignment: Alignment

        init(
            title: Title = .init(),
            backgroundColor: Color = Colors.Old.tangemBgGray,
            horizontalPadding: CGFloat = 0,
            height: CGFloat = 44,
            alignment: Alignment = .center
        ) {
            self.title = title
            self.backgroundColor = backgroundColor
            self.horizontalPadding = horizontalPadding
            self.height = height
            self.alignment = alignment
        }
    }

    private let title: String
    private let settings: Settings
    private let leftButtons: LeftButtons
    private let rightButtons: RightButtons

    @State private var titleHorizontalPadding: CGFloat = 0.0

    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder leftItems: () -> LeftButtons,
        @ViewBuilder rightItems: () -> RightButtons
    ) {
        self.title = title
        self.settings = settings
        leftButtons = leftItems()
        rightButtons = rightItems()
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0.0) {
                leftButtons
                    .readGeometry(\.size.width) { newValue in
                        if newValue > titleHorizontalPadding {
                            titleHorizontalPadding = newValue
                        }
                    }

                Spacer()

                rightButtons
                    .readGeometry(\.size.width) { newValue in
                        if newValue > titleHorizontalPadding {
                            titleHorizontalPadding = newValue
                        }
                    }
            }

            HStack(spacing: 0.0) {
                FixedSpacer.horizontal(titleHorizontalPadding)
                    .layoutPriority(1)

                Text(title)
                    .style(settings.title.font, color: settings.title.color)
                    .lineLimit(settings.title.lineLimit)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(settings.title.minimumScaleFactor)

                FixedSpacer.horizontal(titleHorizontalPadding)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, settings.horizontalPadding)
        .frame(height: settings.height, alignment: settings.alignment)
        .background(settings.backgroundColor.edgesIgnoringSafeArea(.all))
    }
}

extension NavigationBar where LeftButtons == EmptyView, RightButtons == EmptyView {
    init(title: String, settings: Settings = .init()) {
        self.title = title
        self.settings = settings
        leftButtons = EmptyView()
        rightButtons = EmptyView()
    }
}

extension NavigationBar where LeftButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder rightButtons: () -> RightButtons
    ) {
        leftButtons = EmptyView()
        self.rightButtons = rightButtons()
        self.title = title
        self.settings = settings
    }
}

extension NavigationBar where RightButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder leftButtons: () -> LeftButtons
    ) {
        rightButtons = EmptyView()
        self.leftButtons = leftButtons()
        self.title = title
        self.settings = settings
    }
}

extension NavigationBar where LeftButtons == ArrowBack, RightButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init(),
        backAction: @escaping () -> Void
    ) {
        leftButtons = ArrowBack(action: {
            backAction()
        }, height: settings.height)
        rightButtons = EmptyView()
        self.title = title
        self.settings = settings
    }
}

extension NavigationBar where LeftButtons == ArrowBack, RightButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init(),
        presentationMode: Binding<PresentationMode>
    ) {
        leftButtons = ArrowBack(action: {
            presentationMode.wrappedValue.dismiss()
        }, height: settings.height)
        rightButtons = EmptyView()
        self.title = title
        self.settings = settings
    }
}

struct NavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                NavigationBar(title: "Hello, World!", backAction: {})
                Spacer()
            }.deviceForPreview(.iPhone11Pro)

            VStack {
                NavigationBar(title: "Hello, World!")
                Spacer()
            }.deviceForPreview(.iPhone11ProMax)

            HStack {
                BackButton(height: 44, isVisible: true, isEnabled: true) {}
                Spacer()
            }.deviceForPreview(.iPhone11ProMax)
        }
    }
}
