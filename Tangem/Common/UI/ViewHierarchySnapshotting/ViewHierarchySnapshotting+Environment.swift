//
//  ViewHierarchySnapshotting.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Environment values

extension EnvironmentValues {
    var viewHierarchySnapshotter: ViewHierarchySnapshotting? {
        get { self[ViewHierarchySnapshotterEnvironmentKey.self] }
        set { self[ViewHierarchySnapshotterEnvironmentKey.self] = newValue }
    }
}

// MARK: - Private implementation

private enum ViewHierarchySnapshotterEnvironmentKey: EnvironmentKey {
    static var defaultValue: ViewHierarchySnapshotting? { nil }
}
