//
//  BottomSheetViewController.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 17.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class BottomSheetViewController<Content: View>: BottomSheetBaseController {
    @Binding private var isPresented: Bool

    private let contentView: UIHostingController<Content>
    private var keyboardSubscription: AnyCancellable?
    private var bottomConstraint: NSLayoutConstraint!

    init(
        isPresented: Binding<Bool>,
        content: Content
    ) {
        _isPresented = isPresented
        contentView = UIHostingController(rootView: content)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.masksToBounds = true

        addChild(contentView)
        view.addSubview(contentView.view)

        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.backgroundColor = contentBackgroundColor
        view.backgroundColor = contentBackgroundColor

        bottomConstraint = contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            bottomConstraint,
            contentView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
        ])

        keyboardSubscription = Publishers
            .keyboardInfo
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] info in
                guard let self = self else { return }
                bottomConstraint.constant = -info.0
                view.superview?.layoutIfNeeded()
            })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isPresented = false
    }
}
