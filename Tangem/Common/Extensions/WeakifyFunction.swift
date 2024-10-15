//
//  WeakifyFunction.swift
//  Tangem
//
//  Created by Andrew Son on 04/10/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// For more info read: https://klundberg.com/blog/capturing-objects-weakly-in-instance-method-references-in-swift/

func weakify<Owner: AnyObject>(_ owner: Owner, forFunction builder: @escaping (Owner) -> () -> Void) -> () -> Void {
    return { [weak owner] in
        if let owner = owner {
            builder(owner)()
        }
    }
}

func weakify<Owner: AnyObject, Param>(_ owner: Owner, forFunction builder: @escaping (Owner) -> (Param) -> Void) -> (Param) -> Void {
    return { [weak owner] param in
        if let owner = owner {
            builder(owner)(param)
        }
    }
}

func weakify<Owner: AnyObject, Param1, Param2>(_ owner: Owner, forFunction builder: @escaping (Owner) -> (Param1, Param2) -> Void) -> (Param1, Param2) -> Void {
    return { [weak owner] param1, param2 in
        if let owner = owner {
            builder(owner)(param1, param2)
        }
    }
}

func weakify<Owner: AnyObject>(_ owner: Owner, forFunction builder: @escaping (Owner) -> () async -> Void) -> () async -> Void {
    return { [weak owner] in
        if let owner = owner {
            await builder(owner)()
        }
    }
}
