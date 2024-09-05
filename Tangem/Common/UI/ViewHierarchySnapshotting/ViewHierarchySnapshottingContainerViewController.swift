//
//  ViewHierarchySnapshottingContainerViewController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class ViewHierarchySnapshottingContainerViewController: UIViewController {
    private let contentViewController: UIViewController

    init(
        contentViewController: UIViewController
    ) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "init(coder:) has not been implemented")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContent()
        ViewHierarchySnapshottingManager.shared.register(self)
    }

    // MARK: - Setup

    private func setupContent() {
        addChild(contentViewController)

        let containerView = view!
        let contentView = contentViewController.view!
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        contentViewController.didMove(toParent: self)
    }
}
