//
//  MutableCollection+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension MutableCollection where Self.Index == Int {
    /// `MutableCollection.move(fromOffsets:toOffset:)` with bounds checking.
    /// - Throws: `MutableCollectionTryMoveError` if there is an OOB for source/destination.
    mutating func tryMove(
        fromOffsets source: IndexSet,
        toOffset destination: Int
    ) throws {
        guard !source.isEmpty else {
            return
        }

        for offset in source {
            // “past the end” source offset (the position one greater than the last valid subscript argument) is
            // perfectly valid for the `move(fromOffsets:toOffset:)` method, therefore `<= count` comparison is used
            guard offset >= 0, offset <= count else {
                throw MutableCollectionTryMoveError.sourceOffsetOutOfBound(offset: offset, count: count)
            }
        }

        // “past the end” destination (the position one greater than the last valid subscript argument) is
        // perfectly valid for the `move(fromOffsets:toOffset:)` method, therefore `<= count` comparison is used
        guard destination >= 0, destination <= count else {
            throw MutableCollectionTryMoveError.destinationOffsetOutOfBound(offset: destination, count: count)
        }

        move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Auxiliary types

enum MutableCollectionTryMoveError: Error {
    case sourceOffsetOutOfBound(offset: Int, count: Int)
    case destinationOffsetOutOfBound(offset: Int, count: Int)
}
