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

struct DefaultNavigationBarTitle: View {
    struct Settings {
        let font: Font
        let color: Color
        let lineLimit: Int?
        let minimumScaleFactor: CGFloat

        init(
            font: Font = .system(size: 17, weight: .medium),
            color: Color = Colors.Old.tangemGrayDark6,
            lineLimit: Int? = nil, // Default system value
            minimumScaleFactor: CGFloat = 1 // Default system value
        ) {
            self.font = font
            self.color = color
            self.lineLimit = lineLimit
            self.minimumScaleFactor = minimumScaleFactor
        }

        static var `default` = Settings()
    }

    let title: String
    let settings: Settings

    init(_ title: String, settings: Settings = .default) {
        self.title = title
        self.settings = settings
    }

    var body: some View {
        Text(title)
            .style(settings.font, color: settings.color)
            .lineLimit(settings.lineLimit)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(settings.minimumScaleFactor)
    }
}

struct NavigationBar<Title: View, LeftButtons: View, RightButtons: View>: View {
    struct Settings {
        let title: DefaultNavigationBarTitle.Settings
        let backgroundColor: Color
        let horizontalPadding: CGFloat
        let height: CGFloat
        let alignment: Alignment

        init(
            title: DefaultNavigationBarTitle.Settings = .default,
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

    private let settings: Settings

    private let title: () -> Title
    private let leftButtons: () -> LeftButtons
    private let rightButtons: () -> RightButtons

    @State private var titleHorizontalPadding: CGFloat = 0.0

    init(
        settings: Settings = .init(),
        @ViewBuilder titleView: @escaping () -> Title,
        @ViewBuilder leftButtons: @escaping () -> LeftButtons,
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.settings = settings
        title = titleView
        self.leftButtons = leftButtons
        self.rightButtons = rightButtons
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0.0) {
                leftButtons()
                    .readGeometry(\.size.width) { newValue in
                        if newValue > titleHorizontalPadding {
                            titleHorizontalPadding = newValue
                        }
                    }

                Spacer()

                rightButtons()
                    .readGeometry(\.size.width) { newValue in
                        if newValue > titleHorizontalPadding {
                            titleHorizontalPadding = newValue
                        }
                    }
            }

            HStack(spacing: 0.0) {
                FixedSpacer.horizontal(titleHorizontalPadding)
                    .layoutPriority(1)

                title()

                FixedSpacer.horizontal(titleHorizontalPadding)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, settings.horizontalPadding)
        .frame(height: settings.height, alignment: settings.alignment)
        .background(settings.backgroundColor.edgesIgnoringSafeArea(.all))
    }
}

extension NavigationBar where Title == DefaultNavigationBarTitle {
    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder leftButtons: @escaping () -> LeftButtons,
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.title = {
            DefaultNavigationBarTitle(
                title,
                settings: settings.title
            )
        }
        self.settings = settings
        self.rightButtons = rightButtons
        self.leftButtons = leftButtons
    }
}

extension NavigationBar where LeftButtons == EmptyView {
    init(
        settings: Settings = .init(),
        @ViewBuilder titleView: @escaping () -> Title,
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.init(
            settings: settings,
            titleView: titleView,
            leftButtons: { EmptyView() },
            rightButtons: rightButtons
        )
    }
}

extension NavigationBar where RightButtons == EmptyView {
    init(
        settings: Settings = .init(),
        @ViewBuilder titleView: @escaping () -> Title,
        @ViewBuilder leftButtons: @escaping () -> LeftButtons
    ) {
        self.init(
            settings: settings,
            titleView: titleView,
            leftButtons: leftButtons,
            rightButtons: { EmptyView() }
        )
    }
}

extension NavigationBar where Title == DefaultNavigationBarTitle, LeftButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.init(
            title: title,
            settings: settings,
            leftButtons: { EmptyView() },
            rightButtons: rightButtons
        )
    }
}

extension NavigationBar where Title == DefaultNavigationBarTitle, RightButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init(),
        @ViewBuilder leftButtons: @escaping () -> LeftButtons
    ) {
        self.init(
            title: title,
            settings: settings,
            leftButtons: leftButtons,
            rightButtons: { EmptyView() }
        )
    }
}

extension NavigationBar where Title == DefaultNavigationBarTitle, LeftButtons == EmptyView, RightButtons == EmptyView {
    init(
        title: String,
        settings: Settings = .init()
    ) {
        self.init(
            title: title,
            settings: settings,
            leftButtons: { EmptyView() },
            rightButtons: { EmptyView() }
        )
    }
}

extension NavigationBar where LeftButtons == ArrowBack, RightButtons == EmptyView, Title == DefaultNavigationBarTitle {
    init(
        title: String,
        settings: Settings = .init(),
        backAction: @escaping () -> Void
    ) {
        self.init(
            title: title,
            settings: settings,
            leftButtons: {
                ArrowBack(
                    action: {
                        backAction()
                    },
                    height: settings.height
                )
            },
            rightButtons: { EmptyView() }
        )
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
